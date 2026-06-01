# BASwiftKit 代码评审摘要

> 评审范围：`HEAD~1..HEAD`（最近一次提交）  
> 评审时间：2026/05/27  
> 评审文件：22 个（重点关注 18 个）

## 问题统计

| 严重级别 | 数量 |
|---------|------|
| 🔴 Critical | 1 |
| 🟠 High | 2 |
| 🟡 Medium | 4 |
| 🟢 Low | 4 |

---

## 🔴 Critical

### 1. `start()` 被重复调用（`BAScannerViewController`）

- **文件**：`Package/Sources/BASwiftKit/Scanner/BAScannerViewController.swift:88`
- **问题**：`prepareScanner()` 成功回调里调了 `scannerSession.start()`，`viewWillAppear` 又无条件调了一次。`AVCaptureSession.startRunning()` 连续调用可能抛 `NSGenericException`。
- **修复方案**：去掉 `prepareScanner()` 里的直接 `start()`，改为记录准备状态；仅在页面可见（`view.window != nil`）时才启动相机。

---

## 🟠 High

### 2. `isConfigured` 标志位永不重置（`BAScannerSession`）

- **文件**：`Package/Sources/BASwiftKit/Scanner/BAScannerSession.swift:33`
- **问题**：`isConfigured` 第一次配置成功后永远为 `true`，实例复用或恢复时直接返回，可能导致 `previewLayer` 为空或异常。
- **修复方案**：用 `captureSession.inputs.isEmpty` 替代 `isConfigured` 布尔标志，反映真实的会话配置状态。

### 3. 生命周期竞态条件（`BAScannerViewController`）

- **文件**：`Package/Sources/BASwiftKit/Scanner/BAScannerViewController.swift:35-56`
- **问题**：如果在 `viewWillDisappear` 之后 `prepare` 的 completion 才执行，会再次 `start()` 把相机在后台重新打开。
- **修复方案**：在 `prepare` completion 中判断 `view.window != nil`，仅当页面确实可见时才启动相机。

---

## 🟡 Medium

### 4. `UIScreen.main` 已废弃（iOS 16+）

- **文件**：`Package/Sources/BASwiftKit/Utilities/BAAppEnvironment.swift:20`
- **建议**：iOS 16+ 应改用 `windowScene?.screen` 获取屏幕信息。

### 5. `ba_isPortrait` / `ba_isLandscape` 名不副实

- **文件**：`Package/Sources/BASwiftKit/Utilities/BAAppEnvironment.swift:34-36`
- **建议**：比较的是屏幕物理尺寸而非界面方向。在 iPad 分屏或外接显示器时会产生误判。建议改名为 `ba_isScreenPortrait` / `ba_isScreenLandscape`，或改用 `interfaceOrientation` 判断。

### 6. 分页瀑布流布局不支持 Supplementary Views

- **文件**：`Package/Sources/BASwiftKit/Layout/BAPagedWaterfallFlowLayout.swift:78-83`
- **建议**：未覆盖 `layoutAttributesForSupplementaryView(ofKind:at:)` 等方法。如果使用者注册了 header/footer 会 crash。建议补全方法或在文档中明确声明不支持。

### 7. 安全区边距重复计算

- **文件**：`Package/Sources/BASwiftKit/Layout/BAWaterfallFlowLayout.swift:88`
- **建议**：`adjustedContentInset` 已包含安全区，`sectionInset` 再叠加可能导致双重 padding。建议明确 `sectionInset` 是否与安全区互斥。

---

## 🟢 Low

### 8. `setTorch` 错误类型不精确

- **文件**：`Package/Sources/BASwiftKit/Scanner/BAScannerSession.swift:100-104`
- **建议**：`lockForConfiguration()` 失败时（设备被其他 session 锁定）也报 `.torchUnavailable`，建议区分 `.torchLocked`。

### 9. Demo 中无条件 `invalidateLayout()`

- **文件**：`Demo/BASwiftKitDemo/Modules/WaterfallDemo/BAPagedWaterfallDemoViewController.swift:39-42`
- **建议**：`viewDidLayoutSubviews` 每次都会触发全量 `prepare()` 重算。应仅在 bounds 真正变化时才调用。

### 10. `metadataObjectType` 为 internal

- **文件**：`Package/Sources/BASwiftKit/Scanner/BAScannerTypes.swift:33`
- **建议**：消费者无法扩展扫码类型。建议改为 `public`，或让配置接口直接接受 `[AVMetadataObject.ObjectType]`。

### 11. `ba_keyWindow` 后台可能返回 nil

- **文件**：`Package/Sources/BASwiftKit/Utilities/BAAppEnvironment.swift:41`
- **建议**：app 进入后台时 `.foregroundActive` 会漏掉窗口。建议文档说明，或提供 `.foregroundInactive` fallback。

---

## 正面观察

- Scanner 模块职责分离清晰（`BAScannerSession` 管 AVFoundation、`BAScannerViewController` 管 UI）。
- 多线程处理规范（`sessionQueue` / `metadataQueue` + 主线程回调）。
- 闭包中 `[weak self]` 使用一致，无循环引用风险。
- 新增公共 API 有详细文档注释（参数、用法、注意事项）。
- Demo 中多处修复了 safe area 约束，提升全面屏兼容性。
- `BAScannerError` 枚举覆盖全面，错误语义清晰。

---

## 修复状态

| 问题 | 状态 |
|-----|------|
| Critical - 重复 `start()` | 已修复 |
| High - `isConfigured` 标志 | 已修复 |
| High - 生命周期竞态 | 已修复（与 Critical 一并处理）|
| Medium / Low | 建议后续迭代 |
