//
//  BADemoRouteConstants.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/06/03.
//

/// Demo 路由路径常量。
///
/// 集中管理所有 Demo 页面的路由路径，避免散落字符串带来的复制粘贴错误。
/// 使用 URL Scheme 规范：`ba://<module>/<action>`。
///
/// ## 命名规范
///
/// - 采用 `/module/action` 层级结构
/// - 全小写，单词间用 `-` 分隔
/// - 每个路径对应一个有业务含义的名称
///
/// ## 使用方式
///
/// ```swift
/// // 注册路由
/// BARouter.shared.register(demoRoute(pattern: BADemoRoutes.UI.animation) { ... })
///
/// // 跳转
/// BARouter.shared.open(BADemoRoutes.UI.animation)
///
/// // 带参数跳转（通过 BAURLParser 构建 request）
/// let req = BARouteRequest(
///     urlString: BADemoRoutes.Foundation.paramPassing,
///     path: BADemoRoutes.Foundation.paramPassing,
///     params: ["name": "张三", "age": 28]
/// )
/// BARouter.shared.open(req) { result in print("回调: \(result ?? "")") }
/// ```
public enum BADemoRoutes {

    /// App 的 URL Scheme。
    public static let scheme = "baswiftkit"

    // MARK: - UI 类 Demo（Category: ui）

    public enum UI {
        public static let color          = "/demo/ui/color"
        public static let components     = "/demo/ui/components"
        public static let animation      = "/demo/ui/animation"
        public static let font           = "/demo/ui/font"
        public static let waterfall      = "/demo/ui/waterfall"
        public static let pagedWaterfall = "/demo/ui/paged-waterfall"
        public static let navbar         = "/demo/ui/navbar"
        public static let tabbar         = "/demo/ui/tabbar"
        public static let banner         = "/demo/ui/banner"
    }

    // MARK: - Feedback 类 Demo（Category: feedback）

    public enum Feedback {
        public static let toast    = "/demo/feedback/toast"
        public static let loading  = "/demo/feedback/loading"
        public static let emptyView = "/demo/feedback/emptyview"
        public static let alert    = "/demo/feedback/alert"
    }

    // MARK: - Foundation 类 Demo（Category: foundation）

    public enum Foundation {
        public static let string        = "/demo/foundation/string"
        public static let l10n          = "/demo/foundation/l10n"
        public static let socket        = "/demo/foundation/socket"
        public static let countdown     = "/demo/foundation/countdown"
        public static let logger        = "/demo/foundation/logger"
        public static let routerDemo    = "/demo/foundation/router"
        public static let networkCrypto = "/demo/foundation/network-crypto"
        public static let scanner       = "/demo/foundation/scanner"
        public static let infra         = "/demo/foundation/infra"
        public static let storage       = "/demo/foundation/storage"
        public static let utilities     = "/demo/foundation/utilities"
        public static let mediaData     = "/demo/foundation/media-data"
        public static let deviceInfo    = "/demo/foundation/device-info"
        public static let cache         = "/demo/foundation/cache"
        public static let webView       = "/demo/foundation/webview"
        /// 参数传递 + 回调 Demo（Target 页，在 ParamPassingDemo pod）
        public static let paramPassing  = "/demo/foundation/param-passing"
        /// 路由 Caller 页面（发起方，在主 App 中）
        public static let routerCaller  = "/demo/foundation/router-caller"
    }

    /// 所有已注册路由的路径列表（供调试使用）。
    public static var allPaths: [String] {
        [
            UI.color, UI.components, UI.animation, UI.font, UI.waterfall,
            UI.pagedWaterfall, UI.navbar, UI.tabbar, UI.banner,
            Feedback.toast, Feedback.loading, Feedback.emptyView, Feedback.alert,
            Foundation.string, Foundation.l10n, Foundation.socket, Foundation.countdown,
            Foundation.logger, Foundation.routerDemo, Foundation.routerCaller, Foundation.networkCrypto,
            Foundation.scanner, Foundation.infra, Foundation.storage,
            Foundation.utilities, Foundation.mediaData, Foundation.deviceInfo,
            Foundation.cache, Foundation.webView, Foundation.paramPassing
        ]
    }

    // MARK: - Helper

    /// 为指定路由路径构建带 scheme 的完整 URL 字符串。
    ///
    /// ```swift
    /// BADemoRoutes.fullURL(BADemoRoutes.UI.animation)
    /// // → "baswiftkit://demo/ui/animation"
    /// ```
    public static func fullURL(_ path: String) -> String {
        "\(scheme)://\(path.dropFirst())"
    }
}
