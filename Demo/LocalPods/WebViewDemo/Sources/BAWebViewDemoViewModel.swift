//
//  BAWebViewDemoViewModel.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/26.
//

import UIKit
import BASwiftKit
import WebKit
import DemoCommon

final class BAWebViewDemoViewModel {

    struct Row {
        let title: String
        let subtitle: String
        let action: () -> UIViewController
    }

    let rows: [Row] = [
        Row(title: "🌐 加载网页",
            subtitle: "加载 https://www.apple.com",
            action: {
                let config = BAWebViewConfiguration()
                let vc = BAWebViewController(configuration: config)
                vc.ba_load(urlString: "https://www.apple.com")
                return vc
            }),
        Row(title: "🎨 自定义进度条",
            subtitle: "橙色进度条 + 高度 3pt",
            action: {
                let progressConfig = BAWebViewProgressConfiguration(
                    progressTintColor: .systemOrange,
                    height: 3,
                    fadeOutDuration: 0.3
                )
                let config = BAWebViewConfiguration(progressConfiguration: progressConfig)
                let vc = BAWebViewController(configuration: config)
                vc.ba_load(urlString: "https://www.apple.com")
                return vc
            }),
        Row(title: "🚫 URL 拦截",
            subtitle: "拦截特定域名并 Toast 提示",
            action: {
                struct DemoInterceptor: BAWebViewInterceptor {
                    func canHandle(url: URL) -> Bool {
                        url.host?.contains("example.com") == true
                    }
                    func handle(url: URL, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
                        DispatchQueue.main.async {
                            BAToast.ba_show("已拦截: \(url.host ?? "")", style: .warning)
                        }
                        decisionHandler(.cancel)
                    }
                }
                let config = BAWebViewConfiguration(
                    interceptors: [DemoInterceptor()]
                )
                let vc = BAWebViewController(configuration: config)
                vc.ba_load(urlString: "https://www.apple.com")
                return vc
            }),
        Row(title: "💻 HTML 内容",
            subtitle: "直接加载 HTML 字符串",
            action: {
                let vc = BAWebViewController()
                let html = """
                <html>
                <head><meta name="viewport" content="width=device-width, initial-scale=1.0"></head>
                <body style="font-family: -apple-system; padding: 20px;">
                    <h1>Hello BASwiftKit</h1>
                    <p>这是直接加载的 HTML 字符串内容。</p>
                    <button onclick="alert('JS 交互成功')" style="padding: 10px 20px; font-size: 16px;">
                        点击测试 JS
                    </button>
                </body>
                </html>
                """
                vc.ba_load(html: html)
                return vc
            }),
        Row(title: "🛠 JS 交互",
            subtitle: "注入 JS 并获取返回值",
            action: {
                let vc = BAWebViewDemoJSViewController()
                return vc
            })
    ]
}

// MARK: - JS Demo VC

final class BAWebViewDemoJSViewController: BABaseViewController {

    private let webView: BAWebView = {
        let wv = BAWebView()
        wv.didFinishLoading = { _ in
            BAProgressHUD.dismiss()
        }
        return wv
    }()

    private let resultLabel = UILabel.ba_make(font: .ba_medium(14), color: BAAppTheme.textPrimary, numberOfLines: 0)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "JS 交互演示"
        setupLayout()

        let html = """
        <html>
        <head><meta name="viewport" content="width=device-width, initial-scale=1.0"></head>
        <body style="font-family: -apple-system; padding: 20px;">
            <h2>JS Bridge 测试</h2>
            <p>点击下方按钮调用原生方法，或点击原生按钮调用 JS。</p>
            <button onclick="getDeviceInfo()" style="padding: 12px 24px; font-size: 16px; margin: 8px 0;">
                获取设备信息
            </button>
            <div id="result" style="margin-top: 16px; color: #333;"></div>
        </body>
        <script>
            function getDeviceInfo() {
                document.getElementById('result').innerText = 'UserAgent: ' + navigator.userAgent;
            }
            function sayHello(name) {
                return 'Hello, ' + name + '! 来自 JS 的问候。';
            }
        </script>
        </html>
        """
        BAProgressHUD.show("加载中…")
        webView.ba_load(html: html)
    }

    private func setupLayout() {
        let nativeButton = UIButton.ba_make(title: "调用 JS sayHello()",
                                            titleColor: .white,
                                            backgroundColor: BAAppTheme.accent,
                                            font: .ba_semibold(15),
                                            cornerRadius: BAAppTheme.smallCornerRadius)
        nativeButton.snp.makeConstraints { make in make.height.equalTo(BAAppTheme.controlHeight) }
        nativeButton.ba_onTap { [weak self] _ in
            self?.callJS()
        }

        resultLabel.backgroundColor = BAAppTheme.backgroundElevated
        resultLabel.layer.cornerRadius = BAAppTheme.smallCornerRadius
        resultLabel.clipsToBounds = true
        resultLabel.text = "  点击上方按钮测试 JS 交互"

        let stack = UIStackView.ba_make(axis: .vertical, spacing: 12)
        stack.ba_addArrangedSubviews(webView, nativeButton, resultLabel)
        webView.snp.makeConstraints { make in make.height.equalTo(300) }
        resultLabel.snp.makeConstraints { make in make.height.greaterThanOrEqualTo(60) }

        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(12)
            make.left.right.equalToSuperview().inset(16)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide.snp.bottom).offset(-12)
        }
    }

    private func callJS() {
        webView.ba_evaluateJavaScript("sayHello('BASwiftKit')") { [weak self] result in
            switch result {
            case .success(let value):
                self?.resultLabel.text = "  JS 返回值: \(value ?? "nil")"
                BAToast.ba_show("JS 调用成功", style: .success)
            case .failure(let error):
                self?.resultLabel.text = "  错误: \(error.localizedDescription)"
                BAToast.ba_show("JS 调用失败", style: .error)
            }
        }
    }
}
