//
//  BAWebViewOfflineCache.swift
//  BASwiftKit
//
//  Created by boai on 2026/06/30.
//

#if canImport(WebKit)
import Foundation

/// WebView 离线快照磁盘缓存。
///
/// 自包含实现：**仅依赖 Foundation**，不引用 BASwiftKit 其它模块或任何三方库，
/// 以便 WebView 组件后续可整体拆分为独立 Pod。
///
/// 缓存内容是页面加载完成后抓取的渲染态 HTML（`document.documentElement.outerHTML`），
/// 按目标 URL 存盘；当后续同一 URL 因网络不可用加载失败时，回放该 HTML 实现离线展示。
///
/// - Note: 仅缓存 HTML 文档本身。页面子资源（图片/CSS/JS）是否离线可用，取决于
///   `WKWebView` 自身的资源缓存；本缓存不额外抓取子资源。文件名采用 URL 的稳定哈希，
///   避免非法字符与路径穿越。
final class BAWebViewOfflineCache {

    /// 缓存目录。
    private let directory: URL
    /// 快照最长有效期（秒）；`<= 0` 表示永不过期。
    private let maxAge: TimeInterval
    /// 串行 I/O 队列，避免磁盘读写阻塞主线程或互相竞争。
    private let ioQueue = DispatchQueue(label: "com.baswiftkit.webview.offlineCache")

    /// 创建离线缓存。
    ///
    /// - Parameters:
    ///   - directory: 缓存目录；传 `nil` 使用 `Caches/BAWebViewOffline`。
    ///   - maxAge: 快照最长有效期（秒），默认 7 天；`<= 0` 表示永不过期。
    init(directory: URL? = nil, maxAge: TimeInterval = 7 * 24 * 3600) {
        if let directory = directory {
            self.directory = directory
        } else {
            let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSTemporaryDirectory())
            self.directory = caches.appendingPathComponent("BAWebViewOffline", isDirectory: true)
        }
        self.maxAge = maxAge
        try? FileManager.default.createDirectory(at: self.directory, withIntermediateDirectories: true)
    }

    /// 异步保存某 URL 的页面 HTML 快照（在 I/O 队列写盘，不阻塞调用线程）。
    func save(html: String, for url: URL) {
        let fileURL = directory.appendingPathComponent(Self.fileName(for: url))
        let data = Data(html.utf8)
        ioQueue.async {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    /// 异步读取某 URL 的有效快照。读盘在 I/O 队列进行，`completion` 回到主线程。
    ///
    /// 过期快照会被自动删除并返回 `nil`。
    func loadSnapshot(for url: URL, completion: @escaping (String?) -> Void) {
        let fileURL = directory.appendingPathComponent(Self.fileName(for: url))
        let maxAge = self.maxAge
        ioQueue.async {
            let html = Self.readValidHTML(at: fileURL, maxAge: maxAge)
            DispatchQueue.main.async { completion(html) }
        }
    }

    /// 清空全部离线缓存。
    func clear() {
        let directory = self.directory
        ioQueue.async {
            try? FileManager.default.removeItem(at: directory)
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }

    // MARK: - Private

    /// 读取并校验快照（存在性 + 有效期）；过期则删除并返回 nil。
    private static func readValidHTML(at fileURL: URL, maxAge: TimeInterval) -> String? {
        let fm = FileManager.default
        guard fm.fileExists(atPath: fileURL.path) else { return nil }

        if maxAge > 0,
           let attrs = try? fm.attributesOfItem(atPath: fileURL.path),
           let modified = attrs[.modificationDate] as? Date,
           Date().timeIntervalSince(modified) > maxAge {
            try? fm.removeItem(at: fileURL)
            return nil
        }

        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// 由 URL 生成稳定、合法的缓存文件名。
    ///
    /// 采用自包含的 djb2 哈希（不依赖 Crypto 模块），避免 URL 中的非法字符与路径穿越；
    /// 缓存场景下极低的碰撞概率可接受（碰撞仅表现为一次缓存覆盖/未命中）。
    private static func fileName(for url: URL) -> String {
        var hash: UInt64 = 5381
        for byte in url.absoluteString.utf8 {
            hash = (hash &* 33) &+ UInt64(byte)
        }
        return String(format: "%016llx.html", hash)
    }
}
#endif
