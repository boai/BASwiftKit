//
//  BADeviceInfoDemoViewModel.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit

public struct BADeviceInfoSection {

    let title: String
    let rows: [(String, String)]
}

public final class BADeviceInfoDemoViewModel {

    public init() {}

    let sections: BAObservable<[BADeviceInfoSection]> = BAObservable([])
    let cacheSizeText: BAObservable<String> = BAObservable("计算中…")

    func refresh() {
        BADeviceInfo.ba_enableBatteryMonitoring()

        let battery: String = {
            let lvl = BADeviceInfo.ba_batteryLevel
            let pct = lvl < 0 ? "未知" : "\(Int(lvl * 100))%"
            return "\(pct) · \(BADeviceInfo.ba_batteryStateDescription)"
        }()

        sections.update([
            BADeviceInfoSection(title: "设备", rows: [
                ("用户设备名",   BADeviceInfo.ba_userDeviceName),
                ("设备型号",    BADeviceInfo.ba_modelName),
                ("机型标识",    BADeviceInfo.ba_machineModel),
                ("Simulator",  BADeviceInfo.ba_isSimulator ? "是" : "否"),
                ("CPU 核心",    "\(BADeviceInfo.ba_processorCount)"),
                ("物理内存",    BADeviceInfo.ba_formatBytes(BADeviceInfo.ba_physicalMemoryBytes))
            ]),
            BADeviceInfoSection(title: "系统", rows: [
                ("系统",       "\(BADeviceInfo.ba_systemName) \(BADeviceInfo.ba_systemVersion)"),
                ("语言",       BADeviceInfo.ba_languageCode),
                ("地域",       BADeviceInfo.ba_localeIdentifier),
                ("时区",       BADeviceInfo.ba_timeZoneIdentifier)
            ]),
            BADeviceInfoSection(title: "电池", rows: [
                ("电量 / 状态", battery)
            ]),
            BADeviceInfoSection(title: "屏幕", rows: [
                ("分辨率",      "\(Int(BADeviceInfo.ba_screenSize.width))×\(Int(BADeviceInfo.ba_screenSize.height)) @\(Int(BADeviceInfo.ba_screenScale))x"),
                ("屏幕宽高",    "\(Int(BAAppEnvironment.ba_screenWidth))×\(Int(BAAppEnvironment.ba_screenHeight)) pt"),
                ("窗口宽高",    "\(Int(BAAppEnvironment.ba_windowWidth))×\(Int(BAAppEnvironment.ba_windowHeight)) pt"),
                ("安全区",      "top=\(Int(BAAppEnvironment.ba_safeAreaTop)), bottom=\(Int(BAAppEnvironment.ba_safeAreaBottom))"),
                ("状态栏",      "\(Int(BAAppEnvironment.ba_statusBarHeight)) pt"),
                ("导航栏区域",   "\(Int(BAAppEnvironment.ba_navigationFullHeight)) pt"),
                ("TabBar 区域", "\(Int(BAAppEnvironment.ba_tabBarFullHeight)) pt"),
                ("刘海屏",      BAAppEnvironment.ba_hasTopSafeArea ? "是" : "否")
            ]),
            BADeviceInfoSection(title: "当前界面", rows: [
                ("KeyWindow",   BAAppEnvironment.ba_keyWindow == nil ? "nil" : "存在"),
                ("CurrentVC",   String(describing: type(of: BAAppEnvironment.ba_currentViewController ?? UIViewController()))),
                ("RootVC",      String(describing: type(of: BAAppEnvironment.ba_rootViewController ?? UIViewController()))),
                ("横竖屏",      BAAppEnvironment.ba_isPortrait ? "竖屏" : "横屏"),
                ("等比宽度",    "16pt@375 → \(String(format: "%.1f", BAAppEnvironment.ba_scaleWidth(16)))pt")
            ]),
            BADeviceInfoSection(title: "存储", rows: [
                ("总空间",      BADeviceInfo.ba_formatBytes(BADeviceInfo.ba_totalDiskBytes)),
                ("可用空间",    BADeviceInfo.ba_formatBytes(BADeviceInfo.ba_freeDiskBytes)),
                ("已使用",      BADeviceInfo.ba_formatBytes(BADeviceInfo.ba_usedDiskBytes))
            ]),
            BADeviceInfoSection(title: "App", rows: [
                ("名称",       BADeviceInfo.ba_appName),
                ("版本",       "\(BADeviceInfo.ba_appVersion) (\(BADeviceInfo.ba_buildNumber))"),
                ("Bundle ID",  BADeviceInfo.ba_bundleId)
            ])
        ])

        recomputeCacheSize()
    }

    func recomputeCacheSize() {
        cacheSizeText.update("计算中…")
        BACache.ba_sizeAsync { [weak self] bytes in
            self?.cacheSizeText.update(BADeviceInfo.ba_formatBytes(bytes))
        }
    }

    func clearCache(_ completion: @escaping (Bool) -> Void) {
        BACache.ba_clearAsync { [weak self] ok in
            self?.recomputeCacheSize()
            completion(ok)
        }
    }
}
