//
//  BAPermissionManager.swift
//  BASwiftKit
//
//  Created by boai on 2026/07/01.
//

import Foundation
import CommonCrypto
import AppKit

// MARK: - BASecurityBookmark

/// 安全范围书签持久化条目。
public struct BASecurityBookmark: Sendable {
    /// 书签标识符（通常为目录路径的 SHA-256）。
    public let identifier: String
    /// 序列化的书签数据。
    public let bookmarkData: Data
    /// 书签创建时间。
    public let createdAt: Date
    /// 对应的目录 URL（通过 `URL.resolveBookmarkData` 解出，不持久化到磁盘）。
    public let resolvedURL: URL?

    public init(identifier: String, bookmarkData: Data, createdAt: Date, resolvedURL: URL? = nil) {
        self.identifier = identifier
        self.bookmarkData = bookmarkData
        self.createdAt = createdAt
        self.resolvedURL = resolvedURL
    }
}

// MARK: - BAPermissionManager

/// 权限管理器：安全范围书签存储与沙盒目录访问。
///
/// 在沙盒化应用中，每次重新启动后需要恢复对用户选择的目录的访问权限。
/// 本管理器通过持久化安全范围书签（Security-Scoped Bookmark）实现此功能。
///
/// 示例：
/// ```swift
/// // 请求用户选择目录
/// BAPermissionManager.shared.requestDirectoryAccess { result in
///     switch result {
///     case .success(let url):
///         print("获得访问权限: \(url.path)")
///     case .failure(let error):
///         print("权限请求失败: \(error)")
///     }
/// }
///
/// // 查询已有权限
/// let urls = BAPermissionManager.shared.authorizedDirectories
/// ```
public final class BAPermissionManager: @unchecked Sendable {

    // MARK: - Singleton

    /// 共享实例。
    public static let shared = BAPermissionManager()

    // MARK: - Storage Keys

    private static let bookmarksKey = "com.baswiftkit.permission.bookmarks"
    private let lock = NSLock()

    // MARK: - Published State

    /// 已授权的目录 URL 列表（只读快照，线程安全）。
    public var authorizedDirectories: [URL] {
        lock.lock()
        defer { lock.unlock() }
        return _bookmarks.values.compactMap { $0.resolvedURL }
    }

    /// 已存储的书签列表。
    public var storedBookmarks: [BASecurityBookmark] {
        lock.lock()
        defer { lock.unlock() }
        return Array(_bookmarks.values)
    }

    // MARK: - Private Storage

    /// 内存中书签缓存：identifier → BASecurityBookmark。
    private var _bookmarks: [String: BASecurityBookmark] = [:]

    // MARK: - Init

    private init() {
        loadBookmarksFromStorage()
    }

    // MARK: - Public API

    /// 使用 NSOpenPanel 请求用户选择目录并持久化书签。
    ///
    /// - Parameters:
    ///   - message: 面板提示文字。
    ///   - canChooseFiles: 是否允许选择文件，默认 `false`（仅目录）。
    ///   - completion: 完成回调（主线程），返回选中的 URL 或错误。
    public func requestDirectoryAccess(
        message: String = "选择需要授权的目录",
        canChooseFiles: Bool = false,
        completion: @escaping @Sendable (Result<URL, BAPermissionError>) -> Void
    ) {
        DispatchQueue.main.async {
            let panel = NSOpenPanel()
            panel.message = message
            panel.canChooseFiles = canChooseFiles
            panel.canChooseDirectories = true
            panel.allowsMultipleSelection = false
            panel.canCreateDirectories = false
            panel.prompt = "授权"

            panel.begin { [weak self] response in
                guard let self = self else { return }

                guard response == .OK, let url = panel.url else {
                    completion(.failure(.userCancelled))
                    return
                }

                do {
                    // 创建安全范围书签
                    let bookmarkData = try url.bookmarkData(
                        options: [.withSecurityScope],
                        includingResourceValuesForKeys: nil,
                        relativeTo: nil
                    )

                    // 立即开始访问
                    guard url.startAccessingSecurityScopedResource() else {
                        completion(.failure(.accessDenied(url)))
                        return
                    }
                    defer { url.stopAccessingSecurityScopedResource() }

                    let identifier = self.identifierForURL(url)
                    let bookmark = BASecurityBookmark(
                        identifier: identifier,
                        bookmarkData: bookmarkData,
                        createdAt: Date(),
                        resolvedURL: url
                    )

                    self.lock.lock()
                    self._bookmarks[identifier] = bookmark
                    self.lock.unlock()

                    self.persistBookmarksToStorage()

                    completion(.success(url))
                } catch {
                    completion(.failure(.bookmarkCreationFailed(url)))
                }
            }
        }
    }

    /// 请求多个目录的访问权限。
    ///
    /// - Parameters:
    ///   - message: 面板提示文字。
    ///   - completion: 完成回调（主线程），返回所有选中的 URL 或错误。
    public func requestMultipleDirectoriesAccess(
        message: String = "选择一个或多个需要授权的目录",
        completion: @escaping @Sendable (Result<[URL], BAPermissionError>) -> Void
    ) {
        DispatchQueue.main.async {
            let panel = NSOpenPanel()
            panel.message = message
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.allowsMultipleSelection = true
            panel.canCreateDirectories = false
            panel.prompt = "授权"

            panel.begin { [weak self] response in
                guard let self = self else { return }

                guard response == .OK, !panel.urls.isEmpty else {
                    completion(.failure(.userCancelled))
                    return
                }

                var authorizedURLs: [URL] = []
                var failedURLs: [URL] = []

                for url in panel.urls {
                    do {
                        let bookmarkData = try url.bookmarkData(
                            options: [.withSecurityScope],
                            includingResourceValuesForKeys: nil,
                            relativeTo: nil
                        )

                        guard url.startAccessingSecurityScopedResource() else {
                            failedURLs.append(url)
                            continue
                        }
                        defer { url.stopAccessingSecurityScopedResource() }

                        let identifier = self.identifierForURL(url)
                        let bookmark = BASecurityBookmark(
                            identifier: identifier,
                            bookmarkData: bookmarkData,
                            createdAt: Date(),
                            resolvedURL: url
                        )

                        self.lock.lock()
                        self._bookmarks[identifier] = bookmark
                        self.lock.unlock()

                        authorizedURLs.append(url)
                    } catch {
                        failedURLs.append(url)
                    }
                }

                self.persistBookmarksToStorage()

                if authorizedURLs.isEmpty {
                    completion(.failure(.bookmarkCreationFailed(failedURLs.first!)))
                } else {
                    completion(.success(authorizedURLs))
                }
            }
        }
    }

    /// 恢复对所有已授权目录的安全范围访问。
    ///
    /// 在应用启动时调用，恢复上一次持久化的书签。
    /// - Returns: 成功恢复访问的 URL 列表。
    @discardableResult
    public func restoreAllAccess() -> [URL] {
        lock.lock()
        let bookmarks = Array(_bookmarks.values)
        lock.unlock()

        var restored: [URL] = []

        for bookmark in bookmarks {
            do {
                var isStale = false
                let url = try URL(
                    resolvingBookmarkData: bookmark.bookmarkData,
                    options: .withSecurityScope,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )

                guard url.startAccessingSecurityScopedResource() else {
                    continue
                }

                let updatedBookmark: BASecurityBookmark
                if isStale {
                    // 书签过期，重新创建
                    let newData = try url.bookmarkData(
                        options: [.withSecurityScope],
                        includingResourceValuesForKeys: nil,
                        relativeTo: nil
                    )
                    updatedBookmark = BASecurityBookmark(
                        identifier: bookmark.identifier,
                        bookmarkData: newData,
                        createdAt: Date(),
                        resolvedURL: url
                    )
                    persistBookmarksToStorage()
                } else {
                    updatedBookmark = BASecurityBookmark(
                        identifier: bookmark.identifier,
                        bookmarkData: bookmark.bookmarkData,
                        createdAt: bookmark.createdAt,
                        resolvedURL: url
                    )
                }

                lock.lock()
                _bookmarks[bookmark.identifier] = updatedBookmark
                lock.unlock()

                restored.append(url)
            } catch {
                // 书签损坏，移除
                lock.lock()
                _bookmarks.removeValue(forKey: bookmark.identifier)
                lock.unlock()
            }
        }

        persistBookmarksToStorage()
        return restored
    }

    /// 撤销指定目录的访问权限并移除书签。
    ///
    /// - Parameter url: 要撤销的目录 URL。
    public func revokeAccess(for url: URL) {
        let identifier = identifierForURL(url)

        lock.lock()
        if let bookmark = _bookmarks[identifier],
           let resolvedURL = bookmark.resolvedURL {
            resolvedURL.stopAccessingSecurityScopedResource()
        }
        _bookmarks.removeValue(forKey: identifier)
        lock.unlock()

        persistBookmarksToStorage()
    }

    /// 撤销所有已授权目录的访问权限。
    public func revokeAllAccess() {
        lock.lock()
        for bookmark in _bookmarks.values {
            if let url = bookmark.resolvedURL {
                url.stopAccessingSecurityScopedResource()
            }
        }
        _bookmarks.removeAll()
        lock.unlock()

        persistBookmarksToStorage()
    }

    /// 检查是否已有指定目录的授权。
    ///
    /// - Parameter url: 要检查的目录 URL。
    /// - Returns: 是否已授权。
    public func hasAccess(to url: URL) -> Bool {
        let identifier = identifierForURL(url)
        lock.lock()
        defer { lock.unlock() }
        return _bookmarks[identifier] != nil
    }

    // MARK: - Error

    public enum BAPermissionError: Error, Sendable {
        /// 用户取消了选择。
        case userCancelled
        /// 访问被拒绝。
        case accessDenied(URL)
        /// 书签创建失败。
        case bookmarkCreationFailed(URL)
        /// 书签无效或已损坏。
        case invalidBookmark(URL)
    }

    // MARK: - Private Helpers

    /// 为 URL 生成唯一标识符（使用路径的 SHA-256）。
    private func identifierForURL(_ url: URL) -> String {
        let pathData = url.standardizedFileURL.path.data(using: .utf8) ?? Data()
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        pathData.withUnsafeBytes { _ = CC_SHA256($0.baseAddress, CC_LONG(pathData.count), &hash) }
        return hash.map { String(format: "%02x", $0) }.joined()
    }

    /// 持久化书签到 UserDefaults。
    private func persistBookmarksToStorage() {
        lock.lock()
        let bookmarks = Array(_bookmarks.values)
        lock.unlock()

        let storageData: [[String: Any]] = bookmarks.compactMap { bookmark in
            return [
                "identifier": bookmark.identifier,
                "bookmarkData": bookmark.bookmarkData,
                "createdAt": bookmark.createdAt.timeIntervalSince1970,
            ]
        }

        UserDefaults.standard.set(storageData, forKey: Self.bookmarksKey)
        UserDefaults.standard.synchronize()
    }

    /// 从 UserDefaults 加载书签到内存。
    private func loadBookmarksFromStorage() {
        guard let storageData = UserDefaults.standard.array(forKey: Self.bookmarksKey) as? [[String: Any]] else {
            return
        }

        var loaded: [String: BASecurityBookmark] = [:]

        for dict in storageData {
            guard let identifier = dict["identifier"] as? String,
                  let bookmarkData = dict["bookmarkData"] as? Data,
                  let createdAtInterval = dict["createdAt"] as? TimeInterval else {
                continue
            }

            let createdAt = Date(timeIntervalSince1970: createdAtInterval)
            let bookmark = BASecurityBookmark(
                identifier: identifier,
                bookmarkData: bookmarkData,
                createdAt: createdAt
            )
            loaded[identifier] = bookmark
        }

        lock.lock()
        _bookmarks = loaded
        lock.unlock()
    }
}
