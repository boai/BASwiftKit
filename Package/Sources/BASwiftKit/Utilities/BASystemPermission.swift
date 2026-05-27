//
//  BASystemPermission.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

#if canImport(UIKit)
import UIKit
import AVFoundation
import CoreLocation
import Photos
import UserNotifications

/// 系统权限状态。
public enum BAPermissionStatus: Equatable {
    /// 用户尚未做出选择。
    case notDetermined
    /// 权限已授权。
    case authorized
    /// 权限被拒绝。
    case denied
    /// 权限受系统限制，例如家长控制或企业策略。
    case restricted
    /// iOS 14+ 相册受限访问，仅允许访问用户选择的部分资源。
    case limited
    /// 当前设备或系统不支持该权限。
    case unsupported
}

/// 定位权限请求类型。
public enum BALocationPermissionType {
    /// App 使用期间定位。
    case whenInUse
    /// 始终允许定位。
    case always
}

/// 常用系统权限封装。
///
/// 提供权限状态查询、权限请求和跳转系统设置页能力。调用请求方法前，请确保宿主 App 的
/// `Info.plist` 已配置对应的隐私说明字段，例如 `NSCameraUsageDescription`、
/// `NSLocationWhenInUseUsageDescription` 等，否则系统会终止 App。
public enum BASystemPermission {

    /// 当前相机权限状态。
    public static var ba_cameraStatus: BAPermissionStatus {
        ba_status(for: AVCaptureDevice.authorizationStatus(for: .video))
    }

    /// 当前麦克风权限状态。
    public static var ba_microphoneStatus: BAPermissionStatus {
        ba_status(for: AVCaptureDevice.authorizationStatus(for: .audio))
    }

    /// 当前相册读取权限状态。
    public static var ba_photoLibraryStatus: BAPermissionStatus {
        if #available(iOS 14.0, *) {
            return ba_status(for: PHPhotoLibrary.authorizationStatus(for: .readWrite))
        }
        return ba_status(for: PHPhotoLibrary.authorizationStatus())
    }

    /// 当前定位权限状态。
    public static var ba_locationStatus: BAPermissionStatus {
        if #available(iOS 14.0, *) {
            return ba_status(for: CLLocationManager().authorizationStatus)
        }
        return ba_status(for: CLLocationManager.authorizationStatus())
    }

    /// 请求相机权限。
    ///
    /// - Parameter completion: 主线程回调授权状态。
    public static func ba_requestCamera(completion: @escaping (BAPermissionStatus) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { _ in
            DispatchQueue.main.async { completion(ba_cameraStatus) }
        }
    }

    /// 请求麦克风权限。
    ///
    /// - Parameter completion: 主线程回调授权状态。
    public static func ba_requestMicrophone(completion: @escaping (BAPermissionStatus) -> Void) {
        AVCaptureDevice.requestAccess(for: .audio) { _ in
            DispatchQueue.main.async { completion(ba_microphoneStatus) }
        }
    }

    /// 请求相册读取权限。
    ///
    /// - Parameter completion: 主线程回调授权状态，iOS 14+ 可能返回 `.limited`。
    public static func ba_requestPhotoLibrary(completion: @escaping (BAPermissionStatus) -> Void) {
        if #available(iOS 14.0, *) {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                DispatchQueue.main.async { completion(ba_status(for: status)) }
            }
        } else {
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async { completion(ba_status(for: status)) }
            }
        }
    }

    /// 查询通知权限状态。
    ///
    /// - Parameter completion: 主线程回调授权状态。
    public static func ba_notificationStatus(completion: @escaping (BAPermissionStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async { completion(ba_status(for: settings.authorizationStatus)) }
        }
    }

    /// 请求通知权限。
    ///
    /// - Parameters:
    ///   - options: 通知能力选项，默认请求 alert、badge、sound。
    ///   - completion: 主线程回调授权状态。
    public static func ba_requestNotification(options: UNAuthorizationOptions = [.alert, .badge, .sound],
                                              completion: @escaping (BAPermissionStatus) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: options) { _, _ in
            ba_notificationStatus(completion: completion)
        }
    }

    /// 请求定位权限。
    ///
    /// - Parameters:
    ///   - type: 请求类型，`.whenInUse` 或 `.always`。
    ///   - completion: 主线程回调授权状态。该回调会在系统状态变化时触发一次。
    /// - Returns: 持有定位代理的请求对象；调用方需要在请求完成前保留它。
    @discardableResult
    public static func ba_requestLocation(_ type: BALocationPermissionType = .whenInUse,
                                          completion: @escaping (BAPermissionStatus) -> Void) -> BALocationPermissionRequest {
        let request = BALocationPermissionRequest(type: type, completion: completion)
        request.ba_start()
        return request
    }

    /// 打开当前 App 的系统设置页。
    ///
    /// - Parameter completion: 打开完成回调。
    public static func ba_openSettings(completion: BAAppNavigator.Completion? = nil) {
        BAAppNavigator.ba_openAppSettings(completion: completion)
    }

    private static func ba_status(for status: AVAuthorizationStatus) -> BAPermissionStatus {
        switch status {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        case .authorized: return .authorized
        @unknown default: return .unsupported
        }
    }

    private static func ba_status(for status: PHAuthorizationStatus) -> BAPermissionStatus {
        switch status {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        case .authorized: return .authorized
        case .limited: return .limited
        @unknown default: return .unsupported
        }
    }

    private static func ba_status(for status: CLAuthorizationStatus) -> BAPermissionStatus {
        switch status {
        case .notDetermined: return .notDetermined
        case .restricted: return .restricted
        case .denied: return .denied
        case .authorizedAlways, .authorizedWhenInUse: return .authorized
        @unknown default: return .unsupported
        }
    }

    private static func ba_status(for status: UNAuthorizationStatus) -> BAPermissionStatus {
        switch status {
        case .notDetermined: return .notDetermined
        case .denied: return .denied
        case .authorized, .provisional, .ephemeral: return .authorized
        @unknown default: return .unsupported
        }
    }
}

/// 定位权限请求对象。
///
/// `CLLocationManager` 的授权回调依赖 delegate 生命周期，调用 `ba_requestLocation` 时需要持有返回对象，
/// 否则对象提前释放会导致无法收到系统回调。
public final class BALocationPermissionRequest: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private let type: BALocationPermissionType
    private let completion: (BAPermissionStatus) -> Void

    /// 创建定位权限请求对象。
    ///
    /// - Parameters:
    ///   - type: 定位权限请求类型。
    ///   - completion: 授权状态变化后的主线程回调。
    public init(type: BALocationPermissionType = .whenInUse,
                completion: @escaping (BAPermissionStatus) -> Void) {
        self.type = type
        self.completion = completion
        super.init()
        manager.delegate = self
    }

    /// 开始请求定位权限。
    public func ba_start() {
        switch type {
        case .whenInUse:
            manager.requestWhenInUseAuthorization()
        case .always:
            manager.requestAlwaysAuthorization()
        }
    }

    /// iOS 14+ 定位授权状态变化回调。
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        ba_complete()
    }

    /// iOS 13 及以下定位授权状态变化回调。
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        ba_complete()
    }

    private func ba_complete() {
        DispatchQueue.main.async {
            self.completion(BASystemPermission.ba_locationStatus)
        }
    }
}
#endif
