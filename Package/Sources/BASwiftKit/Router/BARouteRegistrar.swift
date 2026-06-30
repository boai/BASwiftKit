//
//  BARouteRegistrar.swift
//  BASwiftKit
//
//  Created by boai on 2026/06/03.
//

import Foundation
import ObjectiveC.runtime

// MARK: - Legacy Route Registrar Protocol (Deprecated)

/// 路由注册器协议（**已废弃**，请改用 ``BARouteModule``）。
///
/// 旧版实例式注册器需要框架实例化候选类来判断协议遵循，存在性能与安全隐患。
/// 自动发现现仅支持 `@objc` 的 ``BARouteModule``；本协议保留是为了向后兼容，
/// 但**不再参与自动发现**，只能通过 ``BARouteRegistrarRegistry/add(_:)`` 手动注册。
///
/// 迁移示例：
/// ```swift
/// // 旧（实例方法 + moduleName）
/// final class BAUserRouter: NSObject, BARouteRegistrar {
///     let moduleName = "User"
///     func registerRoutes() { ... }
/// }
///
/// // 新（@objc + 静态方法，自动发现，零实例化）
/// @objc(BAUserRouter)
/// final class BAUserRouter: NSObject, BARouteModule {
///     static func registerRoutes() { ... }
/// }
/// ```
@available(*, deprecated, message: "请改用 BARouteModule（@objc + static registerRoutes），可被安全自动发现。本协议仅支持手动 add(_:)。")
public protocol BARouteRegistrar: AnyObject {

    /// 组件名称，用于日志和排序。
    var moduleName: String { get }

    /// 注册该组件的全部路由。
    func registerRoutes()
}

// MARK: - Registrar Registry

/// 路由注册表 —— 自动发现并执行所有组件（``BARouteModule``）的路由注册。
///
/// ## 工作原理（安全自动发现）
///
/// 1. 通过 `objc_getClassList` 获取进程内全部类，并用 `class_getImageName`
///    过滤出**仅位于 App Bundle 内**（主程序 + 内嵌 Framework）的类，跳过系统库 / 三方库。
/// 2. 对每个候选类执行 `cls as? BARouteModule.Type` —— 这是一次**纯类型检查，不创建任何实例**，
///    既判断了协议遵循，又拿到了可直接调用的类型。
/// 3. 按类名排序后依次调用其 `registerRoutes()`，保证注册顺序确定性。
///
/// 这样无论组件增长到多少个，启动开销都与「App 自身类数量」线性相关，且无实例化副作用。
///
/// **线程安全**：`registerAll()` 内部加锁，多次调用仅首次生效（后续调用直接返回）。
///
/// ```swift
/// // AppDelegate 中调用（或 BARouter.shared.setup(autoRegister: true)）
/// BARouteRegistrarRegistry.shared.registerAll()
/// ```
public final class BARouteRegistrarRegistry {

    // MARK: - Singleton

    /// 全局共享实例。
    public static let shared = BARouteRegistrarRegistry()

    // MARK: - State

    /// 是否已完成全部注册。
    public private(set) var isRegistered: Bool = false

    /// 手动添加的旧版注册器（``BARouteRegistrar``，不走自动发现）。
    /// 以 `AnyObject` 存储，避免在属性声明处引用已废弃类型而产生框架自身的弃用告警。
    private var manualRegistrars: [AnyObject] = []

    private let lock = NSLock()

    // MARK: - Init

    private init() {}

    // MARK: - Manual Registration (备用)

    /// 手动添加一个旧版注册器（不走自动发现）。
    ///
    /// 适用于需要精确控制注册顺序，或仍在使用已废弃的 ``BARouteRegistrar`` 的场景。
    /// 新代码请优先实现 ``BARouteModule`` 以获得自动发现能力。
    ///
    /// - Parameter registrar: 注册器实例。
    @available(*, deprecated, message: "请改用 BARouteModule 以获得安全自动发现；本手动通道仅为兼容旧代码保留。")
    public func add(_ registrar: BARouteRegistrar) {
        lock.lock()
        defer { lock.unlock() }
        manualRegistrars.append(registrar)
    }

    // MARK: - Auto-Discovery Registration

    /// 一键注册所有组件的路由。
    ///
    /// 执行流程：
    /// 1. 安全自动发现所有 ``BARouteModule`` 实现类（仅 App 自身镜像、零实例化）
    /// 2. 按类名排序后依次调用其 `registerRoutes()` 类方法
    /// 3. 追加执行手动添加的旧版 ``BARouteRegistrar``
    ///
    /// 多次调用仅首次生效，后续调用直接返回。
    public func registerAll() {
        lock.lock()
        guard !isRegistered else {
            lock.unlock()
            return
        }
        isRegistered = true
        let manual = manualRegistrars
        lock.unlock()

        // 1. 安全自动发现（仅 App 镜像 + 零实例化）
        let moduleClasses = Self.discoverModuleClasses()
            .sorted { NSStringFromClass($0) < NSStringFromClass($1) }

        var count = 0
        for cls in moduleClasses {
            (cls as? BARouteModule.Type)?.registerRoutes()
            BARouterLogger.info("已注册模块路由: \(NSStringFromClass(cls))")
            count += 1
        }

        // 2. 追加旧版手动注册器（隔离在弃用方法内执行，避免污染框架构建告警）
        count += Self.runLegacyRegistrars(manual)

        BARouterLogger.info("路由注册完成，共 \(count) 个模块")
    }

    /// 执行旧版 ``BARouteRegistrar`` 手动注册器（按 `moduleName` 排序）。
    ///
    /// 单独抽出并标记弃用，使内部对已废弃类型的引用不产生框架自身的弃用告警。
    /// - Returns: 实际执行的注册器数量。
    @available(*, deprecated, message: "兼容旧版 BARouteRegistrar 的内部执行入口。")
    private static func runLegacyRegistrars(_ registrars: [AnyObject]) -> Int {
        let legacy = registrars.compactMap { $0 as? BARouteRegistrar }
        for registrar in legacy.sorted(by: { $0.moduleName < $1.moduleName }) {
            registrar.registerRoutes()
            BARouterLogger.info("已注册模块路由(legacy): \(registrar.moduleName)")
        }
        return legacy.count
    }

    // MARK: - Private: Safe Auto-Discovery

    /// 安全发现所有遵循 ``BARouteModule`` 的类。
    ///
    /// - 仅遍历位于 App Bundle 内（主程序 + 内嵌 Framework）的类；
    /// - 仅做 `as?` 类型检查，**不实例化**任何类。
    ///
    /// - Returns: 遵循 `BARouteModule` 的类列表。
    private static func discoverModuleClasses() -> [AnyClass] {
        // App Bundle 根路径（解析软链）。同时预备一个 /private 前缀变体，
        // 以零文件 I/O 的方式兼容「模拟器 / 沙盒」中 class_getImageName 可能带或不带
        // /private 前缀的差异，避免对每个类做 resolvingSymlinksInPath 的逐类 stat 开销。
        let bundlePath = Bundle.main.bundleURL.resolvingSymlinksInPath().path
        let altBundlePath = bundlePath.hasPrefix("/private")
            ? String(bundlePath.dropFirst("/private".count))
            : "/private" + bundlePath

        let expectedCount = objc_getClassList(nil, 0)
        guard expectedCount > 0 else { return [] }

        let buffer = UnsafeMutablePointer<AnyClass>.allocate(capacity: Int(expectedCount))
        defer { buffer.deallocate() }

        let actualCount = objc_getClassList(
            AutoreleasingUnsafeMutablePointer<AnyClass>(buffer),
            expectedCount
        )

        var result: [AnyClass] = []
        for i in 0..<Int(actualCount) {
            let cls: AnyClass = buffer[i]

            // 先用镜像路径过滤：只保留 App 自身的类，避免对系统/三方类做无谓的类型检查。
            guard let imageNamePtr = class_getImageName(cls) else { continue }
            let imagePath = String(cString: imageNamePtr)
            guard imagePath.hasPrefix(bundlePath) || imagePath.hasPrefix(altBundlePath) else { continue }

            // 零实例化的协议遵循检查 —— 通过即说明是路由模块。
            if cls is BARouteModule.Type {
                result.append(cls)
            }
        }
        return result
    }
}
