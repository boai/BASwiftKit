//
//  BAScannerSession.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

#if canImport(UIKit)
import AVFoundation
import UIKit

/// 扫码会话封装。
///
/// `BAScannerSession` 只负责相机采集、扫码识别、预览层和手电筒控制，不依赖导航、权限工具或业务 UI。
/// 使用前请在宿主 App 的 `Info.plist` 配置 `NSCameraUsageDescription`，否则系统会终止 App。
public final class BAScannerSession: NSObject {
    /// 扫码成功回调。默认在主线程触发。
    public var onResult: ((BAScannerResult) -> Void)?
    /// 扫码失败回调。默认在主线程触发。
    public var onError: ((BAScannerError) -> Void)?

    /// 当前扫码配置。
    public let configuration: BAScannerConfiguration
    /// 摄像头预览层。调用 `prepare(in:completion:)` 成功后可用于自定义布局。
    public private(set) var previewLayer: AVCaptureVideoPreviewLayer?
    /// 当前是否正在运行采集会话。
    public var isRunning: Bool { captureSession.isRunning }

    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "com.baswiftkit.scanner.session")
    private let metadataQueue = DispatchQueue(label: "com.baswiftkit.scanner.metadata")
    private var videoDevice: AVCaptureDevice?

    /// 非连续模式下是否已投递过结果。
    ///
    /// 非连续模式识别到首个结果后只能异步 stop()，会话真正停下前 metadataQueue 仍会连续回调，
    /// 用该标志短路后续回调，确保 onResult 只触发一次。受 `deliveryLock` 保护。
    private var hasDelivered = false
    private let deliveryLock = NSLock()

    /// 创建扫码会话。
    ///
    /// - Parameter configuration: 扫码配置。
    public init(configuration: BAScannerConfiguration = BAScannerConfiguration()) {
        self.configuration = configuration
        super.init()
    }

    /// 准备扫码会话并把相机预览层添加到指定视图。
    ///
    /// - Parameters:
    ///   - previewView: 用于承载相机画面的视图。
    ///   - completion: 主线程回调准备结果。
    public func prepare(in previewView: UIView, completion: @escaping (Result<Void, BAScannerError>) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configure(in: previewView, completion: completion)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self, weak previewView] granted in
                DispatchQueue.main.async {
                    guard granted, let previewView else {
                        completion(.failure(.cameraUnauthorized))
                        return
                    }
                    self?.configure(in: previewView, completion: completion)
                }
            }
        case .denied, .restricted:
            completion(.failure(.cameraUnauthorized))
        @unknown default:
            completion(.failure(.cameraUnauthorized))
        }
    }

    /// 开始扫码。
    ///
    /// 可在 `prepare(in:completion:)` 成功后调用。方法内部会切到后台队列启动采集，避免阻塞主线程。
    public func start() {
        // 每次启动重置投递标志，使非连续模式在重新 start 后可以再次投递结果。
        deliveryLock.lock()
        hasDelivered = false
        deliveryLock.unlock()

        sessionQueue.async { [captureSession] in
            guard !captureSession.isRunning else { return }
            captureSession.startRunning()
        }
    }

    /// 停止扫码。
    public func stop() {
        sessionQueue.async { [captureSession] in
            guard captureSession.isRunning else { return }
            captureSession.stopRunning()
        }
    }

    /// 更新预览层尺寸。
    ///
    /// 通常在页面 `viewDidLayoutSubviews` 中调用，保证横竖屏或布局变化后预览画面铺满容器。
    ///
    /// - Parameter frame: 预览层的新 frame。
    public func updatePreviewFrame(_ frame: CGRect) {
        previewLayer?.frame = frame
    }

    /// 设置手电筒开关。
    ///
    /// - Parameter isOn: `true` 打开手电筒，`false` 关闭。
    /// - Throws: 当前设备无手电筒或锁定设备失败时抛出错误。
    public func setTorch(_ isOn: Bool) throws {
        guard let device = videoDevice, device.hasTorch else { throw BAScannerError.torchUnavailable }
        do {
            try device.lockForConfiguration()
            device.torchMode = isOn ? .on : .off
            device.unlockForConfiguration()
        } catch {
            throw BAScannerError.torchLocked
        }
    }

    private func configure(in previewView: UIView, completion: @escaping (Result<Void, BAScannerError>) -> Void) {
        sessionQueue.async { [weak self, weak previewView] in
            guard let self, let previewView else {
                DispatchQueue.main.async { completion(.failure(.cameraUnavailable)) }
                return
            }
            if !self.captureSession.inputs.isEmpty {
                DispatchQueue.main.async { completion(.success(())) }
                return
            }

            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                DispatchQueue.main.async { completion(.failure(.cameraUnavailable)) }
                return
            }
            self.videoDevice = device

            do {
                let input = try AVCaptureDeviceInput(device: device)
                guard self.captureSession.canAddInput(input) else {
                    DispatchQueue.main.async { completion(.failure(.cannotAddInput)) }
                    return
                }
                self.captureSession.addInput(input)
            } catch {
                DispatchQueue.main.async { completion(.failure(.cannotAddInput)) }
                return
            }

            let output = AVCaptureMetadataOutput()
            guard self.captureSession.canAddOutput(output) else {
                DispatchQueue.main.async { completion(.failure(.cannotAddOutput)) }
                return
            }
            self.captureSession.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: self.metadataQueue)

            let requestedTypes = BAScanCodeType.makeMetadataObjectTypes(self.configuration.codeTypes)
            let supportedTypes = requestedTypes.filter { output.availableMetadataObjectTypes.contains($0) }
            guard !supportedTypes.isEmpty else {
                DispatchQueue.main.async { completion(.failure(.unsupportedCodeTypes)) }
                return
            }
            output.metadataObjectTypes = supportedTypes

            let layer = AVCaptureVideoPreviewLayer(session: self.captureSession)
            layer.videoGravity = self.configuration.videoGravity
            self.previewLayer = layer

            DispatchQueue.main.async {
                layer.frame = previewView.bounds
                previewView.layer.insertSublayer(layer, at: 0)
                completion(.success(()))
            }
        }
    }
}

extension BAScannerSession: AVCaptureMetadataOutputObjectsDelegate {
    public func metadataOutput(_ output: AVCaptureMetadataOutput,
                               didOutput metadataObjects: [AVMetadataObject],
                               from connection: AVCaptureConnection) {
        guard let readableObject = metadataObjects.compactMap({ $0 as? AVMetadataMachineReadableCodeObject }).first,
              let value = readableObject.stringValue else { return }

        let result = BAScannerResult(value: value, metadataObjectType: readableObject.type)

        if !configuration.isContinuous {
            // 非连续模式：首个结果投递后置位 hasDelivered，后续回调（会话停下前 metadataQueue
            // 仍会连续触发）在此短路，确保 onResult 只触发一次。
            deliveryLock.lock()
            if hasDelivered {
                deliveryLock.unlock()
                return
            }
            hasDelivered = true
            deliveryLock.unlock()
            stop()
        }

        DispatchQueue.main.async { [onResult] in
            onResult?(result)
        }
    }
}
#endif
