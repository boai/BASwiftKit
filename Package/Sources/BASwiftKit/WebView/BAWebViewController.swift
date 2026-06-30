//
//  BAWebViewController.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/26.
//

#if canImport(UIKit)
import UIKit
import WebKit

/// 完整的 WebView 视图控制器封装，带进度条、下拉刷新、错误页面和工具栏。
///
/// `BAWebViewController` 封装了 `BAWebView`，提供即开即用的网页浏览体验：
/// - 顶部进度条（自动跟随加载进度，可自定义颜色/高度）
/// - 下拉刷新（`UIRefreshControl`）
/// - 错误页面（内置自包含 `BAWebErrorView`，支持重试）
/// - 离线加载（网络不可用时回放缓存页面，需在配置中开启 `offlineEnabled`）
/// - 底部工具栏（前进/后退/刷新，可隐藏）
/// - 导航栏标题自动同步网页 title
///
/// ```swift
/// let config = BAWebViewConfiguration(
///     progressConfiguration: BAWebViewProgressConfiguration(
///         progressTintColor: .systemOrange,
///         height: 3
///     )
/// )
/// let vc = BAWebViewController(configuration: config)
/// vc.ba_load(url: URL(string: "https://example.com")!)
/// navigationController?.pushViewController(vc, animated: true)
/// ```
public final class BAWebViewController: UIViewController {

    /// 当前 WebView 配置。
    public let configuration: BAWebViewConfiguration

    /// 内部封装的 `BAWebView` 实例。
    public private(set) lazy var webView: BAWebView = {
        let wv = BAWebView(configuration: configuration)
        wv.progressHandler = { [weak self] progress in
            self?.updateProgress(progress)
        }
        wv.didFinishLoading = { [weak self] _ in
            self?.handleFinish()
        }
        wv.didFailLoading = { [weak self] error in
            self?.handleError(error)
        }
        wv.didLoadFromCache = { [weak self] _ in
            // 已用离线缓存成功展示，隐藏可能存在的错误页。
            self?.hideEmptyView()
        }
        return wv
    }()

    private let progressView = UIProgressView(progressViewStyle: .default)
    private var refreshControl: UIRefreshControl?
    private var isErrorState = false

    /// 工具栏前进/后退按钮（由 KVO 事件驱动更新可用态，替代 0.3s 定时器轮询）。
    private var backItem: UIBarButtonItem?
    private var forwardItem: UIBarButtonItem?
    private var canGoBackObservation: NSKeyValueObservation?
    private var canGoForwardObservation: NSKeyValueObservation?

    /// 自包含错误页（替代对 UIComponents 的 BAEmptyView 依赖，便于 WebView 独立成 Pod）。
    private lazy var errorView: BAWebErrorView = {
        let view = BAWebErrorView()
        view.isHidden = true
        view.onRetry = { [weak self] in self?.webView.ba_reload() }
        return view
    }()

    deinit {
        canGoBackObservation?.invalidate()
        canGoForwardObservation?.invalidate()
    }

    /// 创建 WebView 控制器。
    ///
    /// - Parameter configuration: WebView 配置。默认使用 `.default`。
    public init(configuration: BAWebViewConfiguration = .default) {
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.configuration = .default
        super.init(coder: coder)
    }

    /// 加载视图并初始化 WebView、进度条和工具栏。
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupToolbar()
    }

    /// 页面即将消失时隐藏工具栏并清理工具栏刷新定时器。
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if configuration.toolbarEnabled {
            navigationController?.setToolbarHidden(true, animated: animated)
        }
    }

    /// 页面即将显示时按配置展示底部工具栏。
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if configuration.toolbarEnabled {
            navigationController?.setToolbarHidden(false, animated: animated)
        }
    }

    // MARK: - Setup

    private func setupViews() {
        view.backgroundColor = .systemBackground

        let progressConfig = configuration.progressConfiguration
        progressView.trackTintColor = progressConfig.trackTintColor
        progressView.progressTintColor = progressConfig.progressTintColor
        progressView.progress = 0
        progressView.isHidden = true

        webView.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false
        errorView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(webView)
        view.addSubview(errorView)
        view.addSubview(progressView)

        // 纯原生约束（不依赖 SnapKit），便于 WebView 组件独立成 Pod。
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            errorView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            errorView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            progressView.topAnchor.constraint(equalTo: view.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: progressConfig.height)
        ])

        if configuration.pullToRefreshEnabled {
            let rc = UIRefreshControl()
            rc.addTarget(self, action: #selector(refreshPulled), for: .valueChanged)
            webView.webView.scrollView.refreshControl = rc
            self.refreshControl = rc
        }
    }

    private func setupToolbar() {
        guard configuration.toolbarEnabled else { return }

        let back = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), style: .plain, target: self, action: #selector(toolbarBack))
        let forward = UIBarButtonItem(image: UIImage(systemName: "chevron.forward"), style: .plain, target: self, action: #selector(toolbarForward))
        let refresh = UIBarButtonItem(image: UIImage(systemName: "arrow.clockwise"), style: .plain, target: self, action: #selector(toolbarRefresh))
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        back.isEnabled = false
        forward.isEnabled = false
        backItem = back
        forwardItem = forward
        toolbarItems = [back, space, forward, space, refresh]

        // 事件驱动更新前进/后退可用态（KVO 替代 0.3s 定时器轮询：省电、即时、无定时器生命周期问题）。
        // WKWebView 在主线程更新这两个属性，故回调内可直接刷新 UI。
        let underlyingWebView = webView.webView
        canGoBackObservation = underlyingWebView.observe(\.canGoBack, options: [.initial, .new]) { [weak self] webView, _ in
            self?.backItem?.isEnabled = webView.canGoBack
        }
        canGoForwardObservation = underlyingWebView.observe(\.canGoForward, options: [.initial, .new]) { [weak self] webView, _ in
            self?.forwardItem?.isEnabled = webView.canGoForward
        }
    }

    // MARK: - Loading

    /// 加载指定 URL。
    ///
    /// - Parameter url: 要加载的 URL。
    public func ba_load(url: URL) {
        isErrorState = false
        hideEmptyView()
        webView.ba_load(url: url)
    }

    /// 加载 URL 字符串。
    ///
    /// - Parameter urlString: 要加载的 URL 字符串。
    public func ba_load(urlString: String) {
        guard let url = URL(string: urlString) else { return }
        ba_load(url: url)
    }

    /// 加载 HTML 字符串。
    ///
    /// - Parameters:
    ///   - html: HTML 内容。
    ///   - baseURL: 基准 URL。
    public func ba_load(html: String, baseURL: URL? = nil) {
        isErrorState = false
        hideEmptyView()
        webView.ba_load(html: html, baseURL: baseURL)
    }

    // MARK: - Progress

    private func updateProgress(_ progress: Double) {
        let config = configuration.progressConfiguration
        progressView.isHidden = false
        progressView.setProgress(Float(progress), animated: config.animationDuration > 0)

        if progress >= 1.0 {
            if config.fadeOutDuration > 0 {
                UIView.animate(withDuration: config.fadeOutDuration, delay: 0.15, options: .curveEaseInOut) {
                    self.progressView.alpha = 0
                } completion: { _ in
                    self.progressView.isHidden = true
                    self.progressView.alpha = 1
                    self.progressView.setProgress(0, animated: false)
                }
            } else {
                progressView.isHidden = true
                progressView.setProgress(0, animated: false)
            }
        }
    }

    private func handleFinish() {
        refreshControl?.endRefreshing()
        if configuration.titleSyncEnabled {
            title = webView.ba_title
        }
        isErrorState = false
        hideEmptyView()
    }

    private func handleError(_ error: Error) {
        refreshControl?.endRefreshing()
        let nsError = error as NSError
        if nsError.code == NSURLErrorCancelled { return }

        isErrorState = true
        showErrorView()
    }

    // MARK: - Error View

    private func showErrorView() {
        errorView.configure(
            image: UIImage(systemName: "wifi.exclamationmark"),
            title: "加载失败",
            message: "网络连接异常或页面无法访问，请检查后重试。",
            retryTitle: "重新加载"
        )
        view.bringSubviewToFront(errorView)
        errorView.isHidden = false
    }

    private func hideEmptyView() {
        errorView.isHidden = true
    }

    // MARK: - Actions

    @objc private func refreshPulled() {
        webView.ba_reload()
    }

    @objc private func toolbarBack() {
        webView.ba_goBack()
    }

    @objc private func toolbarForward() {
        webView.ba_goForward()
    }

    @objc private func toolbarRefresh() {
        webView.ba_reload()
    }
}
#endif
