# 对话与完成项日志

> 按时间倒序记录每一轮用户对话的要点 + 本轮实际完成 / 修复的内容。
> 每次新对话请追加一个新的 `## YYYY-MM-DD` 区块到顶部。

---

## 2026-05-21 (第 4 轮)

### 用户输入概要

> 我说的是封装的代码里方法开头用 `ba_`，没说 Demo 里的方法也用这个，改一下。

### 本轮完成

把 Demo 里业务方法上误加的 `ba_` 前缀全部去掉。只保留对库 API 的 `ba_` 调用（`BAToast.ba_show`、`btn.ba_onTap`、`UILabel.ba_make` 等都是库的方法，保留）。

| 方法 | 文件 | 变化 |
| --- | --- | --- |
| `loadData()` | `BAHomeViewModel` / `BAColorDemoViewModel` / `BAStringDemoViewModel`（无此方法）/ `BAToastDemoViewModel` / `BAComponentsDemoViewModel` | `ba_loadData` → `loadData` |
| `roll()` | `BAColorDemoViewModel` | `ba_roll` → `roll` |
| `update(_:)` | `BAStringDemoViewModel` | `ba_update` → `update` |
| `recompute()` | `BAStringDemoViewModel` | `ba_recompute` 壳子方法删掉，原来的 `private func recompute()` 直接公开 |
| `show(_:)` | `BAToastDemoViewModel` | `ba_show` → `show`（内部对 `BAToast.ba_show` 的调用保留） |
| `configure(with:)` | `BAHomeItemCell` | `ba_configure` → `configure` |

对应 ViewController 里的所有调用点（`viewModel.ba_loadData()` / `viewModel.ba_roll()` / `cell.ba_configure(...)` 等）也一起改了。

### 实现手法

用精确 perl 模式做替换，避免误伤库 API：

```perl
s/\bfunc ba_(loadData|roll|update|recompute|show|configure)\b/func $1/g;
s/\bviewModel\.ba_(loadData|roll|update|recompute|show)\b/viewModel.$1/g;
s/\bcell\.ba_configure\b/cell.configure/g;
```

`BAToast.ba_show` 这种「类名.ba_方法」形态的库调用不会被匹配。

### 本轮修复

- `BAStringDemoViewModel`：原先 `ba_recompute()` 是壳子，只调用 `private func recompute()`。批量改名后两者重名变成死递归。修法是删掉壳子，把 `private` 去掉直接对外暴露 `recompute()`。

### 验证

- `xcodebuild -sdk iphonesimulator … build` ✅ **BUILD SUCCEEDED**

---

## 2026-05-21 (第 3 轮)

### 用户输入概要

> 所有新建的文件顶部的文件说明呢，类似 Xcode 标头（`//  XX.swift / 工程名 / Created by …`）这种全部加上。
> 另外文件前缀 BA 也没有（指 Demo 里 AppDelegate / HomeViewController 等还没 BA 前缀）。

### 本轮完成

**Demo 文件 + 类名加 BA 前缀**（库文件本就有前缀，无需动）：

| 旧 | 新 |
| --- | --- |
| `App/AppDelegate.swift` · `class AppDelegate` | `App/BAAppDelegate.swift` · `class BAAppDelegate` |
| `App/SceneDelegate.swift` · `class SceneDelegate` | `App/BASceneDelegate.swift` · `class BASceneDelegate` |
| `Common/Observable.swift` · `class Observable<Value>` | `Common/BAObservable.swift` · `class BAObservable<Value>` |
| `Common/BaseViewController.swift` · `class BaseViewController` | `Common/BABaseViewController.swift` · `class BABaseViewController` |
| `Theme/AppTheme.swift` · `enum AppTheme` | `Theme/BAAppTheme.swift` · `enum BAAppTheme` |
| `Modules/Home/DemoItem.swift` · `struct DemoItem` | `Modules/Home/BADemoItem.swift` · `struct BADemoItem` |
| `Modules/Home/HomeViewModel.swift` | `Modules/Home/BAHomeViewModel.swift` |
| `Modules/Home/HomeItemCell.swift` | `Modules/Home/BAHomeItemCell.swift` |
| `Modules/Home/HomeViewController.swift` | `Modules/Home/BAHomeViewController.swift` |
| `Modules/ColorDemo/ColorDemoViewModel.swift` · `struct ColorSwatch` | `Modules/ColorDemo/BAColorDemoViewModel.swift` · `struct BAColorSwatch` |
| `Modules/ColorDemo/ColorDemoViewController.swift` | `Modules/ColorDemo/BAColorDemoViewController.swift` |
| `Modules/StringDemo/StringDemoViewModel.swift` · `struct StringDemoResult` | `Modules/StringDemo/BAStringDemoViewModel.swift` · `struct BAStringDemoResult` |
| `Modules/StringDemo/StringDemoViewController.swift` | `Modules/StringDemo/BAStringDemoViewController.swift` |
| `Modules/ToastDemo/ToastDemoViewModel.swift` · `struct ToastDemoOption` | `Modules/ToastDemo/BAToastDemoViewModel.swift` · `struct BAToastDemoOption` |
| `Modules/ToastDemo/ToastDemoViewController.swift` | `Modules/ToastDemo/BAToastDemoViewController.swift` |
| `Modules/ComponentsDemo/ComponentsDemoViewModel.swift` | `Modules/ComponentsDemo/BAComponentsDemoViewModel.swift` |
| `Modules/ComponentsDemo/ComponentsDemoViewController.swift` | `Modules/ComponentsDemo/BAComponentsDemoViewController.swift` |

**所有 Swift 文件加上 Xcode 风格头注释**，统一格式：

```swift
//
//  <FileName>.swift
//  <ProjectName>   // Sources → BASwiftKit / Tests → BASwiftKitTests / Demo → BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//
```

覆盖范围：`Sources/BASwiftKit/**/*.swift` + `Tests/BASwiftKitTests/*.swift` + `Demo/BASwiftKitDemo/**/*.swift`。`Package.swift` 跳过（首行的 `// swift-tools-version` 是 SwiftPM 魔法注释，不能挪到第 2 行之后）。

**联动修复**

- `Demo/project.yml`：把 Info.plist 里 `UISceneDelegateClassName: $(PRODUCT_MODULE_NAME).SceneDelegate` 改成 `BASceneDelegate`，避免 App 启动后找不到 Scene 入口。
- `xcodegen generate` 重新生成 `Demo/BASwiftKitDemo.xcodeproj`。
- `xcodebuild -sdk iphonesimulator … build` ✅ **BUILD SUCCEEDED**。
- `swift test` ✅ 10/10 通过。

### 实现手法（便于复盘）

- 用 `perl -i -pe 's/\b旧名\b/新名/g'` 批量改 20 个 demo 文件里所有的旧类型名。
- 用 `mv` 重命名文件，再 `xcodegen generate` 让工程自动拾取（XcodeGen 是按目录扫描的，所以不用手改 pbxproj）。
- 加文件头用一个 bash 函数：先 `head -5` 检测是否已经存在 `Created by`，避免重复加。

---

## 2026-05-21 (第 2 轮)

### 用户输入概要

> xcodegen 我已经安装好了，你的工程都没创建，我怎么运行 demo

### 本轮完成

- 执行 `xcodegen generate` 真正生成 `Demo/BASwiftKitDemo.xcodeproj`
- 用 `xcodebuild -sdk iphonesimulator … build` 验证整工程编译通过（**BUILD SUCCEEDED**）

### 本轮修复

- 修复 `Demo/project.yml`：原先把 `info.path` 当成 Info.plist 的“读取源”，导致 XcodeGen 用空白模板覆盖我手写的 plist。改为通过 `info.properties` 内联注入所有需要的键（`UIApplicationSceneManifest` → `SceneDelegate`、`UISupportedInterfaceOrientations`、`UIUserInterfaceStyle`、`UILaunchScreen` 等），并保留 `GENERATE_INFOPLIST_FILE: NO`。
- 重新生成后 Info.plist 包含 SceneDelegate 入口，App 能从 `SceneDelegate` 正确拉起 `HomeViewController`。

### 运行方式

```bash
cd Demo
open BASwiftKitDemo.xcodeproj   # 已生成，直接 Cmd+R 即可
```

---

## 2026-05-21 (第 1 轮)

### 用户输入概要

> 在 `BASwiftKit/` 下创建一个 Swift Demo：
>
> - 用 **MVVM 架构**
> - 先把 Swift 的 `UIKit`、`Foundation` 等常用的公共封装、工具类等封装好
> - 所有方法用 `ba_` 开头
> - 要有 demo 展示
> - 后期要能单独拆分出来给其他项目用，**尽量不要耦合太严重**
> - demo UI 尽量美化一些
> - 把每次对话内容和完成 / 修复的内容简要列出来生成一个 md 文档放在根目录

### 本轮完成

#### 1. 仓库结构与构建系统

- 新建 SwiftPM 工程 `Package.swift`，最低支持 iOS 13、Swift 5.7
- 目录约定：`Sources/BASwiftKit`（库）/ `Demo`（示例 App）/ `Tests/BASwiftKitTests`

#### 2. Foundation 扩展（`Sources/BASwiftKit/Extensions/Foundation/`）

- `String+BA.swift`：`ba_trimmed`、`ba_isBlank`、`ba_isEmail`、`ba_isChinaMobile`、`ba_isURL`、`ba_isPureDigits`、`ba_md5`、`ba_base64Encoded/Decoded`、`ba_substring(in:)`、`ba_width/height(font:)`
- `Date+BA.swift`：`ba_string(format:)`、`ba_timestamp`、`ba_relativeFromNow`、`ba_components`、`ba_isSameDay`，`TimeInterval.ba_date`
- `Collection+BA.swift`：`ba_safe(_:)`、`Array.ba_unique()`、`Array.ba_chunked(into:)`、`Dictionary.ba_merged(with:)`

#### 3. UIKit 扩展（`Sources/BASwiftKit/Extensions/UIKit/`）

- `UIColor+BA.swift`：`init?(ba_hex:)`（支持 3/4/6/8 位）、`ba_rgb`、`ba_random`、`ba_dynamic(light:dark:)`、`ba_hexString`
- `UIView+BA.swift`：`ba_x/y/width/height`、`ba_setCornerRadius/Border/Shadow`、`ba_addSubviews`、`ba_snapshotImage`、`ba_parentViewController`、`ba_removeAllSubviews`
- `UIImage+BA.swift`：`ba_image(color:)`、`ba_resized(to:)`、`ba_roundedToCircle`、`ba_tinted`、`ba_compressed(toKB:)`
- `UIButton+BA.swift`：`ba_make(...)`、`ba_onTap`（关联对象实现闭包点击）
- `UILabel+BA.swift`：`ba_make(...)`、`ba_setLineSpacing`、`ba_highlight`
- `UIViewController+BA.swift`：`ba_alert`、`ba_actionSheet`、`ba_dismissKeyboard`、`ba_findInNavigation`

#### 4. 工具类（`Sources/BASwiftKit/Utilities/`）

- `BAUserDefaults.swift`：`@BAUserDefault` 与 `@BAUserDefaultCodable` 属性包装器
- `BALogger.swift`：5 级日志（verbose/debug/info/warning/error），Debug 自动开启
- `BAToast.swift`：4 种风格 Toast，自动定位 keyWindow，自带渐显/位移动画
- `BAKeychain.swift`：String / Data 的 Keychain 读写
- `BADeviceInfo.swift`：App、系统、屏幕、机型、刘海屏信息

#### 5. UI 组件（`Sources/BASwiftKit/UIComponents/`）

- `BAGradientView.swift`：`CAGradientLayer` 驱动的渐变 View，支持横竖向/双对角线
- `BACardView.swift`：圆角 + 柔和阴影的卡片容器（阴影挂到父视图避免被 mask 截断）
- `BABadgeView.swift`：自适应宽度的胶囊角标，自动变胶囊圆角

#### 6. MVVM Demo App（`Demo/BASwiftKitDemo/`）

- `App/`：`AppDelegate` + `SceneDelegate`
- `Common/Observable.swift`：极简单向绑定容器（VM → View）
- `Common/BaseViewController.swift`：统一深浅色背景、导航栏外观
- `Theme/AppTheme.swift`：调色板、字体、间距常量（深浅色自适应）
- `Modules/Home/`：列表入口 + 渐变 Header + 卡片 Cell
- `Modules/ColorDemo/`：调色板网格 + 随机色 Roll 卡片
- `Modules/StringDemo/`：实时计算 MD5/Base64/邮箱手机号校验
- `Modules/ToastDemo/`：四种 Toast 风格按钮
- `Modules/ComponentsDemo/`：渐变 / 卡片 / Badge / DeviceInfo 展示
- `Resources/Info.plist`：Scene-based、强制竖屏、自动深浅色

#### 7. 测试

- `Tests/BASwiftKitTests/BASwiftKitTests.swift`：10 个单测，覆盖 String / Array / Collection / Date / Base64 / MD5
- `swift test` 全部通过 ✅

#### 8. 工程配置 & 文档

- `Demo/project.yml`：XcodeGen 配置，本地 SwiftPM 依赖根目录，目标 iOS 13+
- `README.md`：库结构、API 速查、集成方式（SPM / 手动）、Demo 运行步骤、设计约束
- `CONVERSATIONS.md`：本文件，对话与完成项日志

### 本轮修复

- 初版 `String+BA.swift` 把 `import UIKit` 写在文件末尾且引入了不必要的 `UIApplicationCompat` 桥接，已重构为顶部 `#if canImport(UIKit)` 条件导入，`ba_isURL` 改为仅检查 URL scheme，移除对 UIApplication 的依赖。
- 初版漏写 `Tests/BASwiftKitTests/BASwiftKitTests.swift`，SwiftPM 会警告测试目标缺源；已补占位 + 真测试用例。

### 待办（如需继续）

- [ ] 给 `Demo` 加上 AppIcon / LaunchScreen 资源
- [ ] 增加更多扩展：`UITableView+BA`、`URLSession+BA`、`Notification+BA`
- [ ] 接入 Snapshot 单测验证 UI 组件渲染
- [ ] 发布 `0.1.0` tag 并写 podspec
