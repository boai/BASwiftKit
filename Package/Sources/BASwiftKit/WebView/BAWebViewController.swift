//
//  BAWebViewController.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/26.
//

#if canImport(UIKit)
import UIKit
import WebKit
import SnapKit

/// 完整的 WebView 视图控制器封装，带进度条、下拉刷新、错误页面和工具栏。
///
/// `BAWebViewController` 封装了 `BAWebView`，提供即开即用的网页浏览体验：
/// - 顶部进度条（自动跟随加载进度，可自定义颜色/高度）
/// - 下拉刷新（`UIRefreshControl`）
/// - 错误页面（使用 `BAEmptyView`，支持重试）
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
        return wv
    }()

    private let progressView = UIProgressView(progressViewStyle: .default)
    private var refreshControl: UIRefreshControl?
    private var isErrorState = false
    private var toolbarTimer: Timer?

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
        toolbarTimer?.invalidate()
        toolbarTimer = nil
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

        view.addSubview(webView)
        view.addSubview(progressView)

        webView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        progressView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(progressConfig.height)
        }

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

        toolbarItems = [back, space, forward, space, refresh]

        toolbarTimer?.invalidate()
        toolbarTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            back.isEnabled = self.webView.ba_canGoBack
            forward.isEnabled = self.webView.ba_canGoForward
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
        let config = BAEmptyViewConfiguration(
            image: UIImage(systemName: "wifi.exclamationmark"),
            title: "加载失败",
            message: "网络连接异常或页面无法访问，请检查后重试。",
            buttonTitle: "重新加载",
            imageSize: CGSize(width: 64, height: 64),
            verticalSpacing: 14,
            titleFont: .systemFont(ofSize: 18, weight: .semibold),
            messageFont: .systemFont(ofSize: 14, weight: .regular),
            buttonFont: .systemFont(ofSize: 15, weight: .semibold)
        )
        webView.ba_showEmptyView(config) { [weak self] in
            self?.webView.ba_reload()
        }
    }

    private func hideEmptyView() {
        webView.ba_hideEmptyView()
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
