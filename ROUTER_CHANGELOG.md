# BARouter Changelog — macOS / SwiftUI Cross-Platform Optimizations

> 本文档记录 BARouter 为支持 macOS SwiftUI 跨平台所做的所有变更。
> 每次变更包含：日期、变更原因、变更内容、影响范围。

---

## 2026-07-01 — macOS SwiftUI 跨平台适配

### 变更背景
BACleanMyMac（macOS 15+ SwiftUI App）使用 BARouter 进行模块解耦。BARouter 原有设计面向 iOS UIKit，需要进行跨平台适配。

### 变更清单

#### 1. BARoutable 协议文档更新
- **文件**: `Router/BARoutable.swift`
- **变更**: 协议文档从 "UIViewController 专用" 改为 "跨平台通用"
- **影响**: 无 API 变更，纯文档更新。向后兼容。

#### 2. BARouteSourceType 文档更新
- **文件**: `Router/BARouteConfig.swift`
- **变更**: 明确标注 `.push`/`.present`/`.root` 为 UIKit 专用，`.auto` 为跨平台推荐
- **影响**: 无 API 变更。引导非 UIKit 平台使用 `.auto`。

#### 3. 新增跨平台便捷注册 API
- **文件**: `Router/BARouter.swift`
- **变更**: 新增 `BARouter.register(_:sourceType:animated:interceptors:handler:)` 方法
- **签名**: `func register(_ pattern: String, sourceType: BARouteSourceType = .auto, animated: Bool = true, interceptors: [BARouteInterceptor] = [], handler: @escaping ([String: Any], @escaping (BARouteError?) -> Void) -> Void)`
- **影响**: 新增 API，不破坏现有接口。UIKit 便捷方法（`BARouter+Convenience.swift`）保持不变。
- **用途**: SwiftUI / AppKit / CLI 等非 UIKit 平台可使用此方法注册路由，无需依赖 UIViewController。

#### 4. BACrossPlatformRouteHandler
- **文件**: `Router/BARouter.swift`（内部类）
- **变更**: 新增 `private final class BACrossPlatformRouteHandler: BARouteHandler`
- **影响**: 内部实现，不暴露。将闭包适配为 BARouteHandler 协议。

### 跨平台架构说明

```
BARouter (Foundation, 跨平台)
├── URL 匹配 (BARouteTrie)          ✅ 跨平台
├── 服务容器 (BAServiceable)        ✅ 跨平台
├── 模块发现 (BARouteModule)        ✅ 跨平台
├── 拦截器链 (BARouteInterceptor)   ✅ 跨平台
├── 便捷注册 (新增)                  ✅ 跨平台
├── UIKit 便捷注册 (已有)            ⚠️ #if canImport(UIKit)
├── UIKit 导航器 (BARouteNavigator)  ⚠️ #if canImport(UIKit)
└── BARoutable 协议                  ✅ 跨平台（文档已更新）
```

### 后续优化建议
- [ ] 考虑将 `BARouteNavigator` 的模式抽象为平台无关协议，允许各平台提供自己的 Navigator 实现
- [ ] 考虑为 SwiftUI 提供 `NavigationLink` / `.sheet()` 原生的路由集成
- [ ] 考虑为 macOS AppKit 提供 NSWindow / NSViewController 导航支持
