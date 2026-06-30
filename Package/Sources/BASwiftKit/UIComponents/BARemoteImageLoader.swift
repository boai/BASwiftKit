//
//  BARemoteImageLoader.swift
//  BASwiftKit
//
//  Created by boai on 2026/06/30.
//

#if canImport(UIKit)
import UIKit
import ObjectiveC.runtime

// MARK: - Image Loading Protocol

/// 远程图片加载协议（**低耦合解耦点**）。
///
/// 轮播等组件不直接绑定任何具体图片库，而是依赖本协议。业务可：
/// - 使用框架内置的 ``BADefaultImageLoader``（URLSession + 内存缓存，开箱即用、零三方依赖）；
/// - 或自行实现本协议接入 Kingfisher / SDWebImage 等（一两行转发即可）。
///
/// ```swift
/// // 接入 Kingfisher 示例：
/// final class KFImageLoader: BARemoteImageLoading {
///     func ba_loadImage(from url: URL, into imageView: UIImageView, placeholder: UIImage?) {
///         imageView.kf.setImage(with: url, placeholder: placeholder)
///     }
///     func ba_cancelLoad(for imageView: UIImageView) { imageView.kf.cancelDownloadTask() }
/// }
/// ```
public protocol BARemoteImageLoading: AnyObject {
    /// 异步加载网络图片到 `imageView`，加载完成前先展示 `placeholder`。
    ///
    /// - Important: 需自行处理 cell 复用（同一 `imageView` 再次请求时取消上一次、避免错图）。
    func ba_loadImage(from url: URL, into imageView: UIImageView, placeholder: UIImage?)

    /// 取消某个 `imageView` 正在进行的加载（用于 cell 复用 / 视图回收）。
    func ba_cancelLoad(for imageView: UIImageView)
}

// MARK: - Default Loader

/// 框架内置默认图片加载器。
///
/// 自包含实现：`URLSession` 下载 + `NSCache` 内存缓存 + 后台解码 + 主线程回填，
/// 并通过「请求代次」正确处理 cell 复用（异步回来时若该 `imageView` 已被复用加载别的图，则丢弃旧结果），
/// 避免错图与无谓主线程开销。**不依赖任何三方库**。
public final class BADefaultImageLoader: BARemoteImageLoading {

    /// 全局共享实例（内存缓存随之共享，命中率更高）。
    public static let shared = BADefaultImageLoader()

    private let cache = NSCache<NSURL, UIImage>()
    private let session: URLSession

    /// 按 URL 维度登记的在途请求等待者，避免同一 URL 并发重复下载/解码（列表/轮播快速滑动场景）。
    private var pending: [URL: [Waiter]] = [:]
    private let lock = NSLock()

    /// 一个等待回填的目标：弱引用 imageView + 发起时的请求代次。
    private struct Waiter {
        weak var imageView: UIImageView?
        let token: Int
    }

    /// 创建图片加载器。
    /// - Parameters:
    ///   - memoryCountLimit: 内存缓存最多保留的图片数量，默认 100。
    ///   - session: 下载用的 URLSession，默认带磁盘/内存 URLCache 的共享配置。
    public init(memoryCountLimit: Int = 100, session: URLSession? = nil) {
        cache.countLimit = memoryCountLimit
        if let session = session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.requestCachePolicy = .returnCacheDataElseLoad
            config.urlCache = URLCache(memoryCapacity: 8 * 1024 * 1024,
                                       diskCapacity: 64 * 1024 * 1024,
                                       diskPath: "BAImageLoaderCache")
            self.session = URLSession(configuration: config)
        }
    }

    public func ba_loadImage(from url: URL, into imageView: UIImageView, placeholder: UIImage?) {
        // 递增该 imageView 的请求代次，使此前在途的请求回来后被丢弃（防 cell 复用错图）。
        let token = imageView.ba_imageLoadToken &+ 1
        imageView.ba_imageLoadToken = token

        // 内存缓存命中：直接回填，零网络、零解码。
        if let cached = cache.object(forKey: url as NSURL) {
            imageView.image = cached
            return
        }

        imageView.image = placeholder

        // 在途去重：同一 URL 已有请求时只登记等待者，不重复发起下载。
        let waiter = Waiter(imageView: imageView, token: token)
        lock.lock()
        if pending[url] != nil {
            pending[url]?.append(waiter)
            lock.unlock()
            return
        }
        pending[url] = [waiter]
        lock.unlock()

        let task = session.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self else { return }
            // 在后台线程强制解码，避免首次显示时在主线程同步解码造成卡顿。
            let image = data.flatMap { UIImage(data: $0) }.map { Self.decodedImage($0) }
            if let image = image {
                self.cache.setObject(image, forKey: url as NSURL)
            }
            // 取出并清空该 URL 的全部等待者（成功或失败都清，失败后允许重试）。
            self.lock.lock()
            let waiters = self.pending.removeValue(forKey: url) ?? []
            self.lock.unlock()

            guard let image = image else { return }
            DispatchQueue.main.async {
                // 仅回填仍在等待「这一次」请求的 imageView（代次一致），其余已复用，丢弃。
                for waiter in waiters {
                    if let imageView = waiter.imageView, imageView.ba_imageLoadToken == waiter.token {
                        imageView.image = image
                    }
                }
            }
        }
        task.resume()
    }

    public func ba_cancelLoad(for imageView: UIImageView) {
        // 仅作废该 imageView 的回填（代次自增使其等待者失效）；共享下载任务继续，结果入缓存供复用。
        imageView.ba_imageLoadToken &+= 1
    }

    /// 后台强制解码，预渲染位图，消除滚动时的首帧解码卡顿。
    private static func decodedImage(_ image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        let size = CGSize(width: cgImage.width, height: cgImage.height)
        guard size.width > 0, size.height > 0 else { return image }
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = image.scale
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - UIImageView Associated Storage

private enum BAImageLoaderKeys {
    static var token: UInt8 = 0
}

extension UIImageView {
    /// 请求代次：每次发起新请求自增，异步回填时据此判断是否已被复用覆盖。
    fileprivate var ba_imageLoadToken: Int {
        get { (objc_getAssociatedObject(self, &BAImageLoaderKeys.token) as? Int) ?? 0 }
        set { objc_setAssociatedObject(self, &BAImageLoaderKeys.token, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}
#endif
