//
//  BADeviceInfo.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

#if canImport(UIKit)
import UIKit
import Foundation

/// 设备 / App 信息工具
public enum BADeviceInfo {

    // MARK: - App

    /// App 名称
    public static var ba_appName: String {
        (Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String)
            ?? (Bundle.main.infoDictionary?["CFBundleName"] as? String)
            ?? ""
    }

    /// 版本号（CFBundleShortVersionString）
    public static var ba_appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    /// 构建号
    public static var ba_buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    }

    /// Bundle Identifier
    public static var ba_bundleId: String {
        Bundle.main.bundleIdentifier ?? ""
    }

    // MARK: - 系统

    public static var ba_systemName: String { UIDevice.current.systemName }
    public static var ba_systemVersion: String { UIDevice.current.systemVersion }
    public static var ba_deviceName: String { UIDevice.current.name }

    /// 机型标识符（如 iPhone14,5）
    public static var ba_machineModel: String {
        var sysInfo = utsname()
        uname(&sysInfo)
        let mirror = Mirror(reflecting: sysInfo.machine)
        let id = mirror.children.compactMap { ($0.value as? Int8).flatMap { $0 != 0 ? Character(UnicodeScalar(UInt8($0))) : nil } }
        return String(id)
    }

    // MARK: - 屏幕

    public static var ba_screenSize: CGSize { UIScreen.main.bounds.size }
    public static var ba_screenScale: CGFloat { UIScreen.main.scale }

    /// 是否为刘海屏（safeArea.top > 24）
    public static var ba_isNotched: Bool {
        if #available(iOS 13.0, *) {
            let window = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first(where: { $0.isKeyWindow })
            return (window?.safeAreaInsets.top ?? 0) > 24
        }
        return false
    }
}
#endif
