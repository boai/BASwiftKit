//
//  BALogSQLiteStore.swift
//  BASwiftKit
//
//  Created by boai on 2026/06/02.
//

import Foundation
import SQLite3

/// SQLite 文本绑定析构常量。
///
/// `SQLITE_STATIC`(nil) 表示 SQLite 不复制字符串、由调用方保证其生命周期；
/// 而我们绑定的多为 `(str as NSString).utf8String` 等临时缓冲区，bind 后即可能被释放，
/// 故必须用 `SQLITE_TRANSIENT`，令 SQLite 在绑定时立即复制一份，避免读到悬垂内存。
/// SQLite3 头文件中该宏定义为 `((sqlite3_destructor_type)-1)`，Swift 需手动 bit-cast 还原。
private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/// SQLite 日志数据库。
///
/// 封装日志的写入、查询、清理操作。所有操作线程安全（串行队列 + SQLite 串行模式）。
public final class BALogSQLiteStore {

    /// 单例，默认数据库路径为 `<Documents>/com.baswiftkit.logger/logs.db`。
    public static let shared: BALogSQLiteStore = {
        let docs = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? ""
        let dir = (docs as NSString).appendingPathComponent("com.baswiftkit.logger")
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        let path = (dir as NSString).appendingPathComponent("logs.db")
        return BALogSQLiteStore(path: path)
    }()

    private var db: OpaquePointer?
    private let queue = DispatchQueue(label: "com.baswiftkit.logger.db", qos: .utility)
    private let dbPath: String

    // MARK: - Init

    /// 创建日志数据库。
    ///
    /// - Parameter path: 数据库文件完整路径。父目录不存在时会自动创建。
    public init(path: String) {
        self.dbPath = path
        let dir = (path as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        queue.sync { [weak self] in
            self?.open()
        }
    }

    deinit {
        if let db = db {
            // 使用 close_v2：WAL 模式下若仍有未 finalize 的语句或未完成事务，
            // sqlite3_close 会返回 SQLITE_BUSY 而拒绝关闭、泄漏句柄；
            // close_v2 会标记句柄为僵尸并在最后一个资源释放后自动关闭，确保连接最终被回收。
            sqlite3_close_v2(db)
        }
    }

    // MARK: - Write

    /// 写入一条日志。
    ///
    /// - Parameters:
    ///   - timestamp: Unix 时间戳。
    ///   - level: 日志级别。
    ///   - message: 日志正文。
    ///   - context: 可选上下文 JSON。
    public func insert(timestamp: TimeInterval, level: BALogLevel, message: String, context: String?) {
        queue.async { [weak self] in
            guard let self, let db = self.db else { return }
            let dateString = Self.dateFormatter.string(from: Date(timeIntervalSince1970: timestamp))
            let sql = """
                INSERT INTO logs (timestamp, date_string, level, type, message, context)
                VALUES (?, ?, ?, ?, ?, ?);
                """
            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let s = stmt else { return }
            sqlite3_bind_double(s, 1, timestamp)
            // 文本绑定一律用 SQLITE_TRANSIENT，令 SQLite 立即复制，避免临时 NSString 缓冲区悬垂。
            sqlite3_bind_text(s, 2, (dateString as NSString).utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(s, 3, (level.rawValue as NSString).utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_int(s, 4, Int32(level.levelValue))
            sqlite3_bind_text(s, 5, (message as NSString).utf8String, -1, SQLITE_TRANSIENT)
            if let ctx = context {
                sqlite3_bind_text(s, 6, (ctx as NSString).utf8String, -1, SQLITE_TRANSIENT)
            } else {
                sqlite3_bind_null(s, 6)
            }
            sqlite3_step(s)
            sqlite3_finalize(s)
        }
    }

    // MARK: - Query

    /// 查询指定日期的所有日志。
    ///
    /// - Parameter dateString: 日期字符串，"yyyy-MM-dd" 格式。
    /// - Returns: 按时间升序排列的日志数组。
    public func fetch(dateString: String) -> [BALogEntry] {
        var results: [BALogEntry] = []
        queue.sync { [weak self] in
            guard let self, let db = self.db else { return }
            let sql = "SELECT id, timestamp, date_string, level, type, message, context FROM logs WHERE date_string = ? ORDER BY timestamp ASC;"
            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let s = stmt else { return }
            sqlite3_bind_text(s, 1, (dateString as NSString).utf8String, -1, SQLITE_TRANSIENT)
            while sqlite3_step(s) == SQLITE_ROW {
                let entry = BALogEntry(
                    id: sqlite3_column_int64(s, 0),
                    timestamp: sqlite3_column_double(s, 1),
                    // 列可能为 NULL，sqlite3_column_text 会返回空指针，直接强解包会崩溃，统一用 .map 兜底为 ""。
                    dateString: sqlite3_column_text(s, 2).map { String(cString: $0) } ?? "",
                    level: sqlite3_column_text(s, 3).map { String(cString: $0) } ?? "",
                    typeValue: Int(sqlite3_column_int(s, 4)),
                    message: sqlite3_column_text(s, 5).map { String(cString: $0) } ?? "",
                    context: sqlite3_column_text(s, 6).map { String(cString: $0) }
                )
                results.append(entry)
            }
            sqlite3_finalize(s)
        }
        return results
    }

    /// 查询指定日期范围内的日志。
    public func fetch(from startDate: String, to endDate: String) -> [BALogEntry] {
        var results: [BALogEntry] = []
        queue.sync { [weak self] in
            guard let self, let db = self.db else { return }
            let sql = "SELECT id, timestamp, date_string, level, type, message, context FROM logs WHERE date_string >= ? AND date_string <= ? ORDER BY timestamp ASC;"
            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let s = stmt else { return }
            sqlite3_bind_text(s, 1, (startDate as NSString).utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_bind_text(s, 2, (endDate as NSString).utf8String, -1, SQLITE_TRANSIENT)
            while sqlite3_step(s) == SQLITE_ROW {
                let entry = BALogEntry(
                    id: sqlite3_column_int64(s, 0),
                    timestamp: sqlite3_column_double(s, 1),
                    // 同 fetch(dateString:)：NULL 列用 .map 兜底为 ""，避免强解包崩溃。
                    dateString: sqlite3_column_text(s, 2).map { String(cString: $0) } ?? "",
                    level: sqlite3_column_text(s, 3).map { String(cString: $0) } ?? "",
                    typeValue: Int(sqlite3_column_int(s, 4)),
                    message: sqlite3_column_text(s, 5).map { String(cString: $0) } ?? "",
                    context: sqlite3_column_text(s, 6).map { String(cString: $0) }
                )
                results.append(entry)
            }
            sqlite3_finalize(s)
        }
        return results
    }

    /// 获取所有有日志的日期列表。
    public func allDates() -> [String] {
        var results: [String] = []
        queue.sync { [weak self] in
            guard let self, let db = self.db else { return }
            let sql = "SELECT DISTINCT date_string FROM logs ORDER BY date_string DESC;"
            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let s = stmt else { return }
            while sqlite3_step(s) == SQLITE_ROW {
                // NULL 列用 .map 兜底为 ""，避免强解包崩溃。
                if let date = sqlite3_column_text(s, 0).map({ String(cString: $0) }) {
                    results.append(date)
                }
            }
            sqlite3_finalize(s)
        }
        return results
    }

    /// 获取日志总数。
    public func totalCount() -> Int {
        var count: Int = 0
        queue.sync { [weak self] in
            guard let self, let db = self.db else { return }
            let sql = "SELECT COUNT(*) FROM logs;"
            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let s = stmt else { return }
            if sqlite3_step(s) == SQLITE_ROW {
                count = Int(sqlite3_column_int(s, 0))
            }
            sqlite3_finalize(s)
        }
        return count
    }

    // MARK: - Clean

    /// 删除指定天数之前的日志。
    ///
    /// - Parameter days: 保留最近 N 天的日志，删除更早的。
    public func clean(olderThanDays days: Int) {
        queue.async { [weak self] in
            guard let self, let db = self.db else { return }
            let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
            let cutoff = BALogSQLiteStore.dateFormatter.string(from: cutoffDate)
            let sql = "DELETE FROM logs WHERE date_string < ?;"
            var stmt: OpaquePointer?
            guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let s = stmt else { return }
            sqlite3_bind_text(s, 1, (cutoff as NSString).utf8String, -1, SQLITE_TRANSIENT)
            sqlite3_step(s)
            sqlite3_finalize(s)
        }
    }

    /// 清空所有日志。
    public func clearAll() {
        queue.async { [weak self] in
            guard let self, let db = self.db else { return }
            let sql = "DELETE FROM logs;"
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let s = stmt {
                sqlite3_step(s)
                sqlite3_finalize(s)
            }
        }
    }

    // MARK: - Private

    private func open() {
        if sqlite3_open(dbPath, &db) != SQLITE_OK { return }
        sqlite3_exec(db, "PRAGMA journal_mode=WAL;", nil, nil, nil)
        let createSQL = """
            CREATE TABLE IF NOT EXISTS logs (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp REAL NOT NULL,
                date_string TEXT NOT NULL,
                level TEXT NOT NULL,
                type INTEGER NOT NULL DEFAULT 0,
                message TEXT NOT NULL,
                context TEXT
            );
            CREATE INDEX IF NOT EXISTS idx_date ON logs(date_string);
            """
        sqlite3_exec(db, createSQL, nil, nil, nil)

        // 兼容旧版本数据库：若 logs 表此前没有 type 列则追加。
        migrateAddTypeColumnIfNeeded()

        // 确保 type 列存在后再创建索引，避免旧表启动时崩溃。
        sqlite3_exec(db, "CREATE INDEX IF NOT EXISTS idx_type ON logs(type);", nil, nil, nil)
    }

    private func migrateAddTypeColumnIfNeeded() {
        guard let db = db else { return }
        let sql = "ALTER TABLE logs ADD COLUMN type INTEGER NOT NULL DEFAULT 0;"
        sqlite3_exec(db, sql, nil, nil, nil)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()
}
