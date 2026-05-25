//
//  BADeviceInfo.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

#if canImport(UIKit)
import UIKit
import Foundation

/// 设备 / App / 系统 / 磁盘 / 电池 等运行时信息
public enum BADeviceInfo {

    // MARK: - App

    public static var ba_appName: String {
        (Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String)
            ?? (Bundle.main.infoDictionary?["CFBundleName"] as? String)
            ?? ""
    }
    public static var ba_appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
    public static var ba_buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    }
    public static var ba_bundleId: String { Bundle.main.bundleIdentifier ?? "" }

    // MARK: - 系统

    public static var ba_systemName: String { UIDevice.current.systemName }
    public static var ba_systemVersion: String { UIDevice.current.systemVersion }

    /// 用户自定义的设备名（如 "Alice 的 iPhone"）
    public static var ba_userDeviceName: String { UIDevice.current.name }

    /// 机型标识符（如 `iPhone17,1`）
    public static var ba_machineModel: String {
        var sysInfo = utsname()
        uname(&sysInfo)
        let mirror = Mirror(reflecting: sysInfo.machine)
        let id = mirror.children.compactMap {
            ($0.value as? Int8).flatMap { $0 != 0 ? Character(UnicodeScalar(UInt8($0))) : nil }
        }
        return String(id)
    }

    /// 友好型号名（如 "iPhone 17 Pro"）。未知机型直接返回原始 identifier。
    public static var ba_modelName: String {
        let id = ba_machineModel
        return Self.machineMap[id] ?? id
    }

    /// 根据机型标识符查询友好名称（如 "iPhone17,1" → "iPhone 16 Pro"）
    public static func ba_modelName(for identifier: String) -> String {
        Self.machineMap[identifier] ?? identifier
    }

    /// 是否运行在 Simulator
    public static var ba_isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    /// CPU 核心数
    public static var ba_processorCount: Int { ProcessInfo.processInfo.processorCount }

    /// 物理内存（字节）
    public static var ba_physicalMemoryBytes: UInt64 { ProcessInfo.processInfo.physicalMemory }

    // MARK: - 屏幕

    public static var ba_screenSize: CGSize { UIScreen.main.bounds.size }
    public static var ba_screenScale: CGFloat { UIScreen.main.scale }

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

    // MARK: - 电池

    /// 调用前请先 `ba_enableBatteryMonitoring()`，否则读到的可能是 -1
    @discardableResult
    public static func ba_enableBatteryMonitoring() -> Bool {
        if !UIDevice.current.isBatteryMonitoringEnabled {
            UIDevice.current.isBatteryMonitoringEnabled = true
        }
        return UIDevice.current.isBatteryMonitoringEnabled
    }

    /// 电池电量 0~1，未开启监测时为 -1
    public static var ba_batteryLevel: Float { UIDevice.current.batteryLevel }

    /// 电池状态：unknown / unplugged / charging / full
    public static var ba_batteryState: UIDevice.BatteryState { UIDevice.current.batteryState }

    /// 中文电池状态串
    public static var ba_batteryStateDescription: String {
        switch ba_batteryState {
        case .unknown:    return "未知"
        case .unplugged:  return "未充电"
        case .charging:   return "充电中"
        case .full:       return "已充满"
        @unknown default: return "未知"
        }
    }

    // MARK: - 磁盘

    /// 设备总磁盘空间（字节）。失败返回 0
    public static var ba_totalDiskBytes: Int64 {
        let url = URL(fileURLWithPath: NSHomeDirectory())
        return (try? url.resourceValues(forKeys: [.volumeTotalCapacityKey]).volumeTotalCapacity)
            .flatMap { Int64($0) } ?? 0
    }

    /// 可用磁盘空间（字节，系统认为"重要用途"可用容量）
    public static var ba_freeDiskBytes: Int64 {
        let url = URL(fileURLWithPath: NSHomeDirectory())
        if let val = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]).volumeAvailableCapacityForImportantUsage {
            return val
        }
        return 0
    }

    /// 已使用磁盘空间（字节）
    public static var ba_usedDiskBytes: Int64 {
        max(0, ba_totalDiskBytes - ba_freeDiskBytes)
    }

    // MARK: - 地域 / 时区

    public static var ba_localeIdentifier: String { Locale.current.identifier }
    public static var ba_timeZoneIdentifier: String { TimeZone.current.identifier }
    public static var ba_languageCode: String { Locale.preferredLanguages.first ?? "" }

    // MARK: - 字节格式化

    /// 把字节数格式化成 1.23 GB / 456 MB 等
    public static func ba_formatBytes(_ bytes: Int64,
                                      style: ByteCountFormatter.CountStyle = .file) -> String {
        let f = ByteCountFormatter()
        f.allowedUnits = [.useGB, .useMB, .useKB, .useBytes]
        f.countStyle = style
        return f.string(fromByteCount: bytes)
    }

    public static func ba_formatBytes(_ bytes: UInt64,
                                      style: ByteCountFormatter.CountStyle = .file) -> String {
        ba_formatBytes(Int64(clamping: bytes), style: style)
    }

    // MARK: - 机型映射表（覆盖 iPhone 6s ~ iPhone 17 / iPad / Apple Watch 主流型号）

    private static let machineMap: [String: String] = [
        // iPhone
        "iPhone8,1": "iPhone 6s",
        "iPhone8,2": "iPhone 6s Plus",
        "iPhone8,4": "iPhone SE (1st gen)",
        "iPhone9,1": "iPhone 7",   "iPhone9,3": "iPhone 7",
        "iPhone9,2": "iPhone 7 Plus", "iPhone9,4": "iPhone 7 Plus",
        "iPhone10,1": "iPhone 8",  "iPhone10,4": "iPhone 8",
        "iPhone10,2": "iPhone 8 Plus", "iPhone10,5": "iPhone 8 Plus",
        "iPhone10,3": "iPhone X",  "iPhone10,6": "iPhone X",
        "iPhone11,2": "iPhone XS",
        "iPhone11,4": "iPhone XS Max", "iPhone11,6": "iPhone XS Max",
        "iPhone11,8": "iPhone XR",
        "iPhone12,1": "iPhone 11",
        "iPhone12,3": "iPhone 11 Pro",
        "iPhone12,5": "iPhone 11 Pro Max",
        "iPhone12,8": "iPhone SE (2nd gen)",
        "iPhone13,1": "iPhone 12 mini",
        "iPhone13,2": "iPhone 12",
        "iPhone13,3": "iPhone 12 Pro",
        "iPhone13,4": "iPhone 12 Pro Max",
        "iPhone14,4": "iPhone 13 mini",
        "iPhone14,5": "iPhone 13",
        "iPhone14,2": "iPhone 13 Pro",
        "iPhone14,3": "iPhone 13 Pro Max",
        "iPhone14,6": "iPhone SE (3rd gen)",
        "iPhone14,7": "iPhone 14",
        "iPhone14,8": "iPhone 14 Plus",
        "iPhone15,2": "iPhone 14 Pro",
        "iPhone15,3": "iPhone 14 Pro Max",
        "iPhone15,4": "iPhone 15",
        "iPhone15,5": "iPhone 15 Plus",
        "iPhone16,1": "iPhone 15 Pro",
        "iPhone16,2": "iPhone 15 Pro Max",
        "iPhone17,3": "iPhone 16",
        "iPhone17,4": "iPhone 16 Plus",
        "iPhone17,1": "iPhone 16 Pro",
        "iPhone17,2": "iPhone 16 Pro Max",
        "iPhone17,5": "iPhone 16e",
        "iPhone18,1": "iPhone 17 Pro",
        "iPhone18,2": "iPhone 17 Pro Max",
        "iPhone18,3": "iPhone 17",
        "iPhone18,4": "iPhone Air",
        "iPhone18,5": "iPhone 17e",

        // iPad
        "iPad7,11": "iPad (7th gen)",  "iPad7,12": "iPad (7th gen)",
        "iPad11,6": "iPad (8th gen)",  "iPad11,7": "iPad (8th gen)",
        "iPad12,1": "iPad (9th gen)",  "iPad12,2": "iPad (9th gen)",
        "iPad13,18": "iPad (10th gen)", "iPad13,19": "iPad (10th gen)",
        "iPad15,7": "iPad (11th gen)",  "iPad15,8": "iPad (11th gen)",
        "iPad11,1": "iPad mini (5th gen)", "iPad11,2": "iPad mini (5th gen)",
        "iPad14,1": "iPad mini (6th gen)", "iPad14,2": "iPad mini (6th gen)",
        "iPad16,1": "iPad mini (7th gen)", "iPad16,2": "iPad mini (7th gen)",
        "iPad11,3": "iPad Air (3rd gen)", "iPad11,4": "iPad Air (3rd gen)",
        "iPad13,1": "iPad Air (4th gen)", "iPad13,2": "iPad Air (4th gen)",
        "iPad13,16": "iPad Air (5th gen)", "iPad13,17": "iPad Air (5th gen)",
        "iPad14,8": "iPad Air 11-inch (M2)", "iPad14,9": "iPad Air 11-inch (M2)",
        "iPad14,10": "iPad Air 13-inch (M2)", "iPad14,11": "iPad Air 13-inch (M2)",
        "iPad15,3": "iPad Air 11-inch (M3)", "iPad15,4": "iPad Air 11-inch (M3)",
        "iPad15,5": "iPad Air 13-inch (M3)", "iPad15,6": "iPad Air 13-inch (M3)",
        "iPad13,4": "iPad Pro 11-inch (M1)", "iPad13,5": "iPad Pro 11-inch (M1)",
        "iPad13,6": "iPad Pro 11-inch (M1)", "iPad13,7": "iPad Pro 11-inch (M1)",
        "iPad13,8": "iPad Pro 12.9-inch (M1)", "iPad13,9": "iPad Pro 12.9-inch (M1)",
        "iPad13,10": "iPad Pro 12.9-inch (M1)", "iPad13,11": "iPad Pro 12.9-inch (M1)",
        "iPad14,3": "iPad Pro 11-inch (M2)", "iPad14,4": "iPad Pro 11-inch (M2)",
        "iPad14,5": "iPad Pro 12.9-inch (M2)", "iPad14,6": "iPad Pro 12.9-inch (M2)",
        "iPad16,3": "iPad Pro 11-inch (M4)", "iPad16,4": "iPad Pro 11-inch (M4)",
        "iPad16,5": "iPad Pro 13-inch (M4)", "iPad16,6": "iPad Pro 13-inch (M4)",
        "iPad17,1": "iPad Pro 11-inch (M5)", "iPad17,2": "iPad Pro 11-inch (M5)",
        "iPad17,3": "iPad Pro 13-inch (M5)", "iPad17,4": "iPad Pro 13-inch (M5)",

        // Apple Watch
        "Watch3,1": "Apple Watch Series 3 38mm (GPS+蜂窝)",
        "Watch3,2": "Apple Watch Series 3 42mm (GPS+蜂窝)",
        "Watch3,3": "Apple Watch Series 3 38mm (GPS)",
        "Watch3,4": "Apple Watch Series 3 42mm (GPS)",
        "Watch4,1": "Apple Watch Series 4 40mm (GPS)",
        "Watch4,2": "Apple Watch Series 4 44mm (GPS)",
        "Watch4,3": "Apple Watch Series 4 40mm (GPS+蜂窝)",
        "Watch4,4": "Apple Watch Series 4 44mm (GPS+蜂窝)",
        "Watch5,1": "Apple Watch Series 5 40mm (GPS)",
        "Watch5,2": "Apple Watch Series 5 44mm (GPS)",
        "Watch5,3": "Apple Watch Series 5 40mm (GPS+蜂窝)",
        "Watch5,4": "Apple Watch Series 5 44mm (GPS+蜂窝)",
        "Watch5,9": "Apple Watch SE (1st gen) 40mm (GPS)",
        "Watch5,10": "Apple Watch SE (1st gen) 44mm (GPS)",
        "Watch5,11": "Apple Watch SE (1st gen) 40mm (GPS+蜂窝)",
        "Watch5,12": "Apple Watch SE (1st gen) 44mm (GPS+蜂窝)",
        "Watch6,1": "Apple Watch Series 6 40mm (GPS)",
        "Watch6,2": "Apple Watch Series 6 44mm (GPS)",
        "Watch6,3": "Apple Watch Series 6 40mm (GPS+蜂窝)",
        "Watch6,4": "Apple Watch Series 6 44mm (GPS+蜂窝)",
        "Watch6,6": "Apple Watch Series 7 41mm (GPS)",
        "Watch6,7": "Apple Watch Series 7 45mm (GPS)",
        "Watch6,8": "Apple Watch Series 7 41mm (GPS+蜂窝)",
        "Watch6,9": "Apple Watch Series 7 45mm (GPS+蜂窝)",
        "Watch6,10": "Apple Watch SE (2nd gen) 40mm (GPS)",
        "Watch6,11": "Apple Watch SE (2nd gen) 44mm (GPS)",
        "Watch6,12": "Apple Watch SE (2nd gen) 40mm (GPS+蜂窝)",
        "Watch6,13": "Apple Watch SE (2nd gen) 44mm (GPS+蜂窝)",
        "Watch6,14": "Apple Watch Series 8 41mm (GPS)",
        "Watch6,15": "Apple Watch Series 8 45mm (GPS)",
        "Watch6,16": "Apple Watch Series 8 41mm (GPS+蜂窝)",
        "Watch6,17": "Apple Watch Series 8 45mm (GPS+蜂窝)",
        "Watch6,18": "Apple Watch Ultra",
        "Watch7,1": "Apple Watch Series 9 41mm (GPS)",
        "Watch7,2": "Apple Watch Series 9 45mm (GPS)",
        "Watch7,3": "Apple Watch Series 9 41mm (GPS+蜂窝)",
        "Watch7,4": "Apple Watch Series 9 45mm (GPS+蜂窝)",
        "Watch7,5": "Apple Watch Ultra 2",
        "Watch7,8": "Apple Watch Series 10 42mm (GPS)",
        "Watch7,9": "Apple Watch Series 10 46mm (GPS)",
        "Watch7,10": "Apple Watch Series 10 42mm (GPS+蜂窝)",
        "Watch7,11": "Apple Watch Series 10 46mm (GPS+蜂窝)",
        "Watch7,12": "Apple Watch Ultra 3",
        "Watch7,13": "Apple Watch SE (3rd gen) 40mm (GPS)",
        "Watch7,14": "Apple Watch SE (3rd gen) 44mm (GPS)",
        "Watch7,15": "Apple Watch SE (3rd gen) 40mm (GPS+蜂窝)",
        "Watch7,16": "Apple Watch SE (3rd gen) 44mm (GPS+蜂窝)",
        "Watch7,17": "Apple Watch Series 11 42mm",
        "Watch7,18": "Apple Watch Series 11 46mm",
        "Watch7,19": "Apple Watch Series 11 42mm (GPS+蜂窝)",
        "Watch7,20": "Apple Watch Series 11 46mm (GPS+蜂窝)",

        // Simulator
        "i386":      "Simulator (i386)",
        "x86_64":    "Simulator (x86_64)",
        "arm64":     "Simulator (arm64)"
    ]
}
#endif
