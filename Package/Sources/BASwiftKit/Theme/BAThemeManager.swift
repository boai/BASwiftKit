//
//  BAThemeManager.swift
//  BASwiftKit
//
//  Created by boai on 2026/06/30.
//

#if canImport(UIKit)
import UIKit

// MARK: - Theme Mode

/// 主题模式。
public enum BAThemeMode {
    /// 跟随系统（深浅由系统设置决定）。
    case system
    /// 强制浅色。
    case light
    /// 强制深色。
    case dark
    /// 自定义品牌主题（任意 ``BAThemePalette``）。
    case custom(BAThemePalette)
}

// MARK: - Theme Manager

/// 主题管理器 —— 主题系统的统一入口。
///
/// 一行切换深浅色 / 自定义主题，自动完成：持久化、驱动窗口外观、广播变更、平滑过渡动画。
///
/// ## 两种零负担的接入路径
///
/// 1. **暗黑 / 白天（开箱即用，零 per-view 代码）**
///    业务用色直接用系统语义色（`.label`、`.systemBackground`）或
///    `UIColor.ba_dynamic(light:dark:)`。切换时本管理器设置所有窗口的
///    `overrideUserInterfaceStyle`，系统动态色自动重解析，全屏即时生效：
///    ```swift
///    BAThemeManager.shared.apply(.dark)      // 强制深色
///    BAThemeManager.shared.toggleLightDark() // 一键切换
///    ```
///
/// 2. **自定义品牌主题（多套换肤）**
///    业务用 ``UIView/ba_applyTheme(_:)`` / ``UIView/ba_themeBackground(_:)`` 等绑定语义色槽，
///    切换 `.custom(palette)` 时框架广播变更、绑定自动重渲染：
///    ```swift
///    BAThemeManager.shared.register(OceanTheme())          // 注册以便按 id 恢复
///    BAThemeManager.shared.apply(.custom(OceanTheme()))
///    ```
///
/// ## 启动恢复
///
/// 在窗口就绪后（`didFinishLaunching` 或 `SceneDelegate`）调用一次 ``restore()`` 即可
/// 恢复用户上次选择的主题。自定义主题需先 ``register(_:)`` 才能按 id 恢复。
///
/// - Important: 所有切换操作均在主线程执行（内部自动调度）。
public final class BAThemeManager {

    // MARK: - Singleton

    /// 全局共享实例。
    public static let shared = BAThemeManager()

    // MARK: - Notification

    /// 主题变更通知。`object` 为变更后的 ``palette``。
    ///
    /// 绑定层（``BAThemeBinder``）与自定义观察者据此重渲染。一般业务无需直接监听，
    /// 使用 ``UIView/ba_applyTheme(_:)`` 系列绑定即可。
    public static let didChangeNotification = Notification.Name("com.baswiftkit.theme.didChange")

    // MARK: - State

    /// 当前主题模式。
    public private(set) var mode: BAThemeMode

    /// 当前生效的色板。
    public private(set) var palette: BAThemePalette

    /// 已注册的自定义主题（按 id 索引），用于启动按 id 恢复。
    private var registeredThemes: [String: BAThemePalette] = [:]
    /// 保护 `registeredThemes` 的并发访问（register 可能在非主线程调用，restore 在主线程读）。
    private let themeLock = NSLock()

    private let defaults = UserDefaults.standard
    private static let persistenceKey = "com.baswiftkit.theme.mode"

    // MARK: - Init

    private init() {
        // 读取持久化的模式（仅恢复状态，不触碰窗口；窗口外观由 restore() 应用）。
        let restored = Self.readPersistedMode(from: defaults, registered: [:])
        self.mode = restored
        self.palette = Self.palette(for: restored)
    }

    // MARK: - Public API

    /// 切换主题。
    ///
    /// - Parameters:
    ///   - mode: 目标模式。
    ///   - animated: 是否以淡入淡出过渡，默认 `true`。
    ///   - persist: 是否持久化本次选择以便下次启动恢复，默认 `true`。
    public func apply(_ mode: BAThemeMode, animated: Bool = true, persist: Bool = true) {
        // 统一在主线程执行（涉及窗口与 UI）。
        guard Thread.isMainThread else {
            DispatchQueue.main.async { self.apply(mode, animated: animated, persist: persist) }
            return
        }

        self.mode = mode
        self.palette = Self.palette(for: mode)

        if persist {
            defaults.set(Self.persistedString(for: mode), forKey: Self.persistenceKey)
        }

        let overrideStyle = Self.overrideStyle(for: mode)
        let windows = Self.allWindows()

        let commit = {
            windows.forEach { $0.overrideUserInterfaceStyle = overrideStyle }
            // 广播变更：自定义主题的绑定据此重渲染；系统色由 override 自动重解析。
            NotificationCenter.default.post(name: Self.didChangeNotification, object: self.palette)
        }

        if animated, !windows.isEmpty {
            Self.crossfade(windows: windows, commit: commit)
        } else {
            commit()
        }
    }

    /// 在「浅色」与「深色」之间一键切换（当前为深色则切浅色，否则切深色）。
    /// - Parameter animated: 是否带过渡动画，默认 `true`。
    public func toggleLightDark(animated: Bool = true) {
        apply(isDark ? .light : .dark, animated: animated)
    }

    /// 当前是否处于深色外观。
    ///
    /// `.dark` / `.light` 直接判定；`.system` 依据当前窗口实际 trait；
    /// `.custom` 依据色板的 `userInterfaceStyle`。
    public var isDark: Bool {
        switch mode {
        case .dark:
            return true
        case .light:
            return false
        case .system:
            return Self.allWindows().first?.traitCollection.userInterfaceStyle == .dark
        case .custom(let palette):
            return palette.userInterfaceStyle == .dark
        }
    }

    /// 注册一套自定义主题，使其可在启动时按 id 被 ``restore()`` 恢复。
    /// - Parameter palette: 自定义色板。
    public func register(_ palette: BAThemePalette) {
        themeLock.lock()
        registeredThemes[palette.identifier] = palette
        themeLock.unlock()
    }

    /// 恢复用户上次选择的主题并应用到窗口。
    ///
    /// 在窗口就绪后调用一次（`didFinishLaunching` 或 `SceneDelegate.scene(_:willConnectTo:)`）。
    /// 自定义主题需先 ``register(_:)`` 才能按 id 恢复，否则回落到 `.system`。
    /// - Parameter animated: 是否带过渡动画，默认 `false`（启动恢复通常不需要动画）。
    public func restore(animated: Bool = false) {
        themeLock.lock()
        let registered = registeredThemes
        themeLock.unlock()
        let restored = Self.readPersistedMode(from: defaults, registered: registered)
        apply(restored, animated: animated, persist: false)
    }

    // MARK: - Private: Mode Mapping

    /// 模式 → 生效色板。
    private static func palette(for mode: BAThemeMode) -> BAThemePalette {
        switch mode {
        case .system: return BASystemPalette(identifier: "system", userInterfaceStyle: .unspecified)
        case .light:  return BASystemPalette(identifier: "light", userInterfaceStyle: .light)
        case .dark:   return BASystemPalette(identifier: "dark", userInterfaceStyle: .dark)
        case .custom(let palette): return palette
        }
    }

    /// 模式 → 窗口 `overrideUserInterfaceStyle`。
    private static func overrideStyle(for mode: BAThemeMode) -> UIUserInterfaceStyle {
        switch mode {
        case .system: return .unspecified
        case .light:  return .light
        case .dark:   return .dark
        case .custom(let palette): return palette.userInterfaceStyle
        }
    }

    // MARK: - Private: Persistence

    private static func persistedString(for mode: BAThemeMode) -> String {
        switch mode {
        case .system: return "system"
        case .light:  return "light"
        case .dark:   return "dark"
        case .custom(let palette): return "custom:\(palette.identifier)"
        }
    }

    private static func readPersistedMode(from defaults: UserDefaults,
                                          registered: [String: BAThemePalette]) -> BAThemeMode {
        guard let raw = defaults.string(forKey: persistenceKey) else { return .system }
        switch raw {
        case "system": return .system
        case "light":  return .light
        case "dark":   return .dark
        default:
            // "custom:<id>"：需已注册对应主题方可恢复，否则回落系统。
            if raw.hasPrefix("custom:") {
                let id = String(raw.dropFirst("custom:".count))
                if let palette = registered[id] { return .custom(palette) }
            }
            return .system
        }
    }

    // MARK: - Private: Windows & Animation

    /// 收集当前所有前台窗口。
    private static func allWindows() -> [UIWindow] {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
    }

    /// 以快照淡出实现主题切换的平滑过渡。
    private static func crossfade(windows: [UIWindow], commit: () -> Void) {
        // 仅对「常规层级、可见、有尺寸」的应用窗口做快照过渡；
        // 排除键盘窗口、外接屏（AirPlay/CarPlay）、系统弹窗等，避免闪烁或截取到异常内容。
        let targets = windows.filter {
            $0.windowLevel == .normal && !$0.isHidden && $0.bounds.width > 0
        }
        let snapshots: [(UIWindow, UIView)] = targets.compactMap { window in
            guard let snapshot = window.snapshotView(afterScreenUpdates: false) else { return nil }
            window.addSubview(snapshot)
            return (window, snapshot)
        }

        // 立即提交主题变更（此时旧界面被快照覆盖，用户看不到突变）。
        commit()

        // 快照淡出，露出已应用新主题的真实界面。
        UIView.animate(withDuration: 0.3, animations: {
            snapshots.forEach { $0.1.alpha = 0 }
        }, completion: { _ in
            snapshots.forEach { $0.1.removeFromSuperview() }
        })
    }
}
#endif
