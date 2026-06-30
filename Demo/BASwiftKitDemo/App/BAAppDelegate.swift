//
//  BAAppDelegate.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit

@main
class BAAppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // 1. 启动日志管理器（捕获 print/NSLog + 写入 SQLite）
        BALogManager.shared.start()
        // 2. 启动自动埋点（页面浏览 + 按钮点击 Swizzling）
        BAAutoTracker.start()
        // 3. 注册 App URL Scheme
        BAURLParser.registeredSchemes.insert(BADemoRoutes.scheme)
        // 4. 初始化路由系统并一键自动发现注册所有组件路由（各 Pod 实现 BARouteModule，主工程永不改动）
        BARouter.shared.setup(autoRegister: true)
        let routeCount = BARouter.shared.debugAllRoutes().count
        print("[BAAppDelegate] 路由注册完成（已注册路由: \(routeCount) 条）")
        // 自检：确保 Runtime 自动发现正常工作（若失败通常是因为缺少 -ObjC linker flag）
        if routeCount == 0 {
            print("[BAAppDelegate] ⚠️ 警告：未发现任何已注册路由！请检查 Podfile 是否包含 use_frameworks! 或 linker flag -ObjC")
        }
        return true
    }

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
