//
//  BAScannerViewController.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

#if canImport(UIKit)
import UIKit

/// 通用扫码页面。
///
/// 该页面只提供扫码页面的基础能力：相机预览、开始/停止扫码、结果回调和错误回调。业务层可继承或组合使用，
/// 也可以直接使用 `BAScannerSession` 自定义完整 UI。
open class BAScannerViewController: UIViewController {
    /// 扫码会话对象。
    public let scannerSession: BAScannerSession
    /// 相机预览容器。
    public let previewView = UIView()
    /// 扫码成功回调。
    public var onResult: ((BAScannerResult) -> Void)?
    /// 扫码失败回调。
    public var onError: ((BAScannerError) -> Void)?

    private var isPrepared = false

    /// 创建扫码页面。
    ///
    /// - Parameter configuration: 扫码配置。
    public init(configuration: BAScannerConfiguration = BAScannerConfiguration()) {
        scannerSession = BAScannerSession(configuration: configuration)
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    open override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupPreviewView()
        bindScannerSession()
        prepareScanner()
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewView.frame = view.bounds
        scannerSession.updatePreviewFrame(previewView.bounds)
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if isPrepared {
            scannerSession.start()
        }
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        scannerSession.stop()
    }

    /// 重新开始扫码。
    public func restartScanning() {
        scannerSession.start()
    }

    /// 停止扫码。
    public func stopScanning() {
        scannerSession.stop()
    }

    private func setupPreviewView() {
        previewView.backgroundColor = .black
        previewView.frame = view.bounds
        view.addSubview(previewView)
    }

    private func bindScannerSession() {
        scannerSession.onResult = { [weak self] result in
            self?.onResult?(result)
        }
        scannerSession.onError = { [weak self] error in
            self?.onError?(error)
        }
    }

    private func prepareScanner() {
        scannerSession.prepare(in: previewView) { [weak self] result in
            switch result {
            case .success:
                self?.isPrepared = true
                if self?.view.window != nil {
                    self?.scannerSession.start()
                }
            case let .failure(error):
                self?.onError?(error)
            }
        }
    }
}
#endif
