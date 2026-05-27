//
//  BAWebView.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/26.
//

#if canImport(UIKit)
import UIKit
import WebKit

/// `WKWebView` 封装，支持加载、拦截、缓存、进度监听和 JS 交互。
///
/// `BAWebView` 内置了 `WKNavigationDelegate` 处理拦截器和缓存逻辑，
/// 并通过 KVO 监听 `estimatedProgress` 向外界报告加载进度。
/// 可直接嵌入自定义界面，或通过 `BAWebViewController` 获得完整的导航控制体验。
///
/// ```swift
/// let config = BAWebViewConfiguration()
/// let webView = BAWebView(configuration: config)
/// webView.progressHandler = { progress in
///     print("加载进度: \(progress)")
/// }
/// webView.ba_load(url: URL(string: "https://example.com")!)
/// ```
public final class BAWebView: UIView {

    /// 加载进度回调，值域 `[0.0, 1.0]`。
    public var progressHandler: ((Double) -> Void)?

    /// 加载完成回调。
    public var didFinishLoading: ((URL?) -> Void)?

    /// 加载失败回调。
    public var didFailLoading: ((Error) -> Void)?

    /// 拦截器处理后的导航决策回调。
    public var navigationDecisionHandler: ((URL, WKNavigationActionPolicy) -> Void)?

    /// 当前 WebView 配置。
    public let configuration: BAWebViewConfiguration

    /// 底层 `WKWebView` 实例。需要直接访问 WKWebView API 时可通过此属性。
    public private(set) lazy var webView: WKWebView = {
        let prefs = WKPreferences()
        prefs.javaScriptEnabled = configuration.allowsJavaScript

        let webConfig = WKWebViewConfiguration()
        webConfig.preferences = prefs
        webConfig.allowsInlineMediaPlayback = configuration.allowsInlineMediaPlayback

        let wv = WKWebView(frame: CGRect(x: 0, y: 0, width: 1, height: 1), configuration: webConfig)
        wv.navigationDelegate = self
        wv.allowsBackForwardNavigationGestures = true
        wv.translatesAutoresizingMaskIntoConstraints = false
        if let ua = configuration.userAgent {
            wv.customUserAgent = ua
        }
        return wv
    }()

    private var progressObservation: NSKeyValueObservation?

    /// 创建 WebView。
    ///
    /// - Parameter configuration: WebView 配置。默认使用 `.default`。
    public init(configuration: BAWebViewConfiguration = .default) {
        self.configuration = configuration
        super.init(frame: .zero)
        setupWebView()
    }

    required init?(coder: NSCoder) {
        self.configuration = .default
        super.init(coder: coder)
        setupWebView()
    }

    deinit {
        progressObservation?.invalidate()
    }

    // MARK: - Setup

    private func setupWebView() {
        addSubview(webView)
        webView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] _, change in
            guard let progress = change.newValue else { return }
            DispatchQueue.main.async {
                self?.progressHandler?(progress)
            }
        }
    }

    // MARK: - Loading

    /// 加载指定 URL。
    ///
    /// - Parameter url: 要加载的 URL。
    public func ba_load(url: URL) {
        var request = URLRequest(url: url, timeoutInterval: configuration.timeoutInterval)
        configuration.headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        webView.load(request)
    }

    /// 加载 URL 字符串。
    ///
    /// - Parameter urlString: 要加载的 URL 字符串。若解析失败则无操作。
    public func ba_load(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        ba_load(url: url)
    }

    /// 加载 HTML 字符串。
    ///
    /// - Parameters:
    ///   - html: HTML 内容字符串。
    ///   - baseURL: 用于解析相对路径的基准 URL。默认 `nil`。
    public func ba_load(html: String, baseURL: URL? = nil) {
        webView.loadHTMLString(html, baseURL: baseURL)
    }

    /// 加载本地文件。
    ///
    /// - Parameter fileURL: 本地文件 URL。
    public func ba_load(fileURL: URL) {
        webView.loadFileURL(fileURL, allowingReadAccessTo: fileURL)
    }

    // MARK: - Navigation

    /// 是否可以后退。
    public var ba_canGoBack: Bool {
        webView.canGoBack
    }

    /// 是否可以前进。
    public var ba_canGoForward: Bool {
        webView.canGoForward
    }

    /// 后退一页。
    public func ba_goBack() {
        webView.goBack()
    }

    /// 前进一页。
    public func ba_goForward() {
        webView.goForward()
    }

    /// 重新加载当前页面。
    public func ba_reload() {
        webView.reload()
    }

    /// 停止加载。
    public func ba_stopLoading() {
        webView.stopLoading()
    }

    // MARK: - JavaScript

    /// 执行 JavaScript 代码。
    ///
    /// - Parameters:
    ///   - script: 要执行的 JS 代码字符串。
    ///   - completion: 执行结果回调。`Result` 的 `success` 为返回值（可能为 `nil`）。
    public func ba_evaluateJavaScript(_ script: String, completion: ((Result<Any?, Error>) -> Void)? = nil) {
        webView.evaluateJavaScript(script) { result, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion?(.failure(error))
                } else {
                    completion?(.success(result))
                }
            }
        }
    }

    /// 获取当前页面 URL。
    public var ba_url: URL? {
        webView.url
    }

    /// 获取当前页面标题。
    public var ba_title: String? {
        webView.title
    }
}

// MARK: - WKNavigationDelegate

extension BAWebView: WKNavigationDelegate {

    /// 根据配置中的拦截器决定本次导航是否允许继续。
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        for interceptor in configuration.interceptors where interceptor.canHandle(url: url) {
            interceptor.handle(url: url) { [weak self] policy in
                self?.navigationDecisionHandler?(url, policy)
                decisionHandler(policy)
            }
            return
        }

        decisionHandler(.allow)
    }

    /// 页面加载完成回调，转发给 `didFinishLoading`。
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        didFinishLoading?(webView.url)
    }

    /// 页面主导航加载失败回调，转发给 `didFailLoading`。
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        didFailLoading?(error)
    }

    /// 页面 provisional navigation 加载失败回调，转发给 `didFailLoading`。
    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        didFailLoading?(error)
    }
}
#endif
