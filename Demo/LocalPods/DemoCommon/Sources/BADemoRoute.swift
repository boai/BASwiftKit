//
//  BADemoRoute.swift
//  DemoCommon
//
//  Created by boai on 2026/06/30.
//

import BASwiftKit

// MARK: - Demo 路由枚举（类型安全）

/// Demo 全量路由的统一声明，类型安全版。
///
/// **为什么放在 DemoCommon**：Demo 的路由注册分散在 24 个独立 Pod 的 `*Router.swift`，
/// 跳转入口则集中在主 App。本枚举下沉到共享 Pod `DemoCommon` 后，两端共用同一份定义，
/// 彻底消除「注册端 / 跳转端各写一份字符串、写错一字即静默 404」的复制粘贴隐患。
///
/// ## 设计
///
/// 采用嵌套 case 枚举：外层按功能域分组（`UI` / `Feedback` / `Foundation`），
/// 每个分组是一个 String-backed enum，rawValue 即为路由 pattern，零运行时开销。
/// 所有分组都遵循 ``BARoutePath``，可直接传给 `BARouter` 的注册 / 跳转重载。
///
/// ## 用法
///
/// ```swift
/// // 注册（在各 Demo Pod 的 Router 内）
/// BARouter.shared.register(BADemoRoute.UI.animation, title: "动画") { _ in
///     BAAnimationDemoViewController(viewModel: BAAnimationDemoViewModel())
/// }
///
/// // 跳转（主 App 卡片点击）
/// BARouter.shared.open(BADemoRoute.UI.animation)
///
/// // 需要 String 形式时（如构造 BARouteRequest.path）
/// let path = BADemoRoute.Foundation.paramPassing
/// let request = BARouteRequest(urlString: BADemoRoute.fullURL(path),
///                              path: path.pattern, params: [:], source: .internal)
/// ```
public enum BADemoRoute {

    /// App 的 URL Scheme。
    public static let scheme = "baswiftkit"

    // MARK: - UI 类 Demo（Category: ui）

    /// UI 相关 Demo 路由。
    public enum UI: String, BARoutePath {
        /// 颜色 / UIColor
        case color          = "/demo/ui/color"
        /// UI 组件
        case components     = "/demo/ui/components"
        /// 动画 / Animation
        case animation      = "/demo/ui/animation"
        /// 字体 / UIFont
        case font           = "/demo/ui/font"
        /// 瀑布流 FlowLayout
        case waterfall      = "/demo/ui/waterfall"
        /// 横向分页瀑布流
        case pagedWaterfall = "/demo/ui/paged-waterfall"
        /// 自定义 NavigationBar
        case navbar         = "/demo/ui/navbar"
        /// 自定义 TabBar
        case tabbar         = "/demo/ui/tabbar"
        /// 广告组件（跑马灯 · 轮播）
        case banner         = "/demo/ui/banner"

        public var pattern: String { rawValue }
    }

    // MARK: - Feedback 类 Demo（Category: feedback）

    /// Feedback 相关 Demo 路由。
    public enum Feedback: String, BARoutePath {
        /// 全局 Toast
        case toast     = "/demo/feedback/toast"
        /// 加载 HUD / Progress
        case loading   = "/demo/feedback/loading"
        /// EmptyView / 空状态
        case emptyView = "/demo/feedback/emptyview"
        /// 自定义 Alert / 表单
        case alert     = "/demo/feedback/alert"

        public var pattern: String { rawValue }
    }

    // MARK: - Foundation 类 Demo（Category: foundation）

    /// Foundation 相关 Demo 路由。
    public enum Foundation: String, BARoutePath {
        /// 字符串 / String
        case string        = "/demo/foundation/string"
        /// 多语言 / BALocalization
        case l10n          = "/demo/foundation/l10n"
        /// Socket / WebSocket
        case socket        = "/demo/foundation/socket"
        /// 倒计时 / Countdown
        case countdown     = "/demo/foundation/countdown"
        /// 日志埋点 / Logger
        case logger        = "/demo/foundation/logger"
        /// 路由 / Router
        case routerDemo    = "/demo/foundation/router"
        /// Network & Crypto
        case networkCrypto = "/demo/foundation/network-crypto"
        /// 扫一扫 / Scanner
        case scanner       = "/demo/foundation/scanner"
        /// 基础设施 / Codable · Network
        case infra         = "/demo/foundation/infra"
        /// Storage 存储工具
        case storage       = "/demo/foundation/storage"
        /// 工具封装
        case utilities     = "/demo/foundation/utilities"
        /// Data & Image
        case mediaData     = "/demo/foundation/media-data"
        /// 设备信息 + 清缓存
        case deviceInfo    = "/demo/foundation/device-info"
        /// Cache 缓存框架
        case cache         = "/demo/foundation/cache"
        /// WebView 封装
        case webView       = "/demo/foundation/webview"
        /// 参数传递 & 回调（Target 页，在 ParamPassingDemo pod）
        case paramPassing  = "/demo/foundation/param-passing"
        /// 跨模块传参 & 回调（Caller 页，在主 App 中）
        case routerCaller  = "/demo/foundation/router-caller"

        public var pattern: String { rawValue }
    }

    // MARK: - Helper

    /// 为指定路由构建带 scheme 的完整 URL 字符串。
    ///
    /// ```swift
    /// BADemoRoute.fullURL(BADemoRoute.UI.animation)
    /// // → "baswiftkit://demo/ui/animation"
    /// ```
    public static func fullURL(_ path: BARoutePath) -> String {
        let p = path.pattern
        // pattern 以 "/" 开头（如 "/demo/ui/animation"），拼接 scheme 时去掉前导斜杠。
        let dropped = p.hasPrefix("/") ? String(p.dropFirst()) : p
        return "\(scheme)://\(dropped)"
    }
}
