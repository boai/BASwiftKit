# BASwiftKit

> 一个面向 iOS UIKit 项目、可独立提取的 Swift 公共封装库 + MVVM Demo。

所有公开 API 均以 `ba_` 前缀挂载在系统类型上，避免与宿主工程冲突；
工具类、UI 组件、视图扩展之间保持低耦合，方便后续直接拷贝某一文件或整个 `Sources/BASwiftKit` 目录到其他工程使用。

```
BASwiftKit/
├─ Package.swift                  # Swift Package 入口（可直接 SwiftPM 引入）
├─ Sources/BASwiftKit/            # 库代码：扩展 + 工具 + UI 组件
│  ├─ Extensions/
│  │  ├─ Foundation/              # String / Date / Date+Calendar / Collection / NotificationCenter
│  │  └─ UIKit/                   # UIColor / UIView / UIView+Animation / UIImage / UIButton /
│  │                              # UILabel / UIFont / UITextField / UIStackView /
│  │                              # UIViewController / CALayer
│  ├─ Utilities/                  # Toast / Logger / UserDefaults / Keychain / DeviceInfo /
│  │                              # LoadingHUD / Localization
│  └─ UIComponents/               # GradientView / CardView / BadgeView /
│                                 # NavigationBarStyle / TabBarController
├─ Tests/BASwiftKitTests/         # XCTest 单测
├─ Demo/                          # MVVM Demo 工程
│  ├─ project.yml                 # XcodeGen 配置
│  └─ BASwiftKitDemo/             # App 源码（App / Theme / Common / 10 个 Modules）
└─ CONVERSATIONS.md               # 对话与完成项日志
```

## 功能速查

### Foundation 扩展（`ba_` 前缀）

| 类型 | API | 说明 |
| --- | --- | --- |
| `String` | `ba_trimmed` / `ba_isBlank` / `ba_compact` | 去空白、空校验 |
| `String` | `ba_isEmail` / `ba_isChinaMobile` / `ba_isURL` / `ba_isPureDigits` | 常用校验 |
| `String` | `ba_md5` / `ba_base64Encoded` / `ba_base64Decoded` | 编码摘要 |
| `String` | `ba_width(font:)` / `ba_height(font:maxWidth:)` | 文本测量 |
| `String` | `ba_localized` / `ba_localized(_:)` / `ba_date(format:)` | i18n / 解析为 Date |
| `Date` | `ba_string(format:)` / `ba_relativeFromNow` / `ba_components` | 格式化 / 相对时间 |
| `Date` | `ba_startOfDay` / `ba_endOfDay` / `ba_startOfMonth` / `ba_endOfMonth` | 日期边界 |
| `Date` | `ba_adding(days/months/years:)` / `ba_daysBetween(_:)` / `ba_ageInYears` | 日期算术 |
| `Date` | `ba_isToday` / `ba_isYesterday` / `ba_isWeekend` / `ba_weekdayName(locale:)` | 查询 |
| `Array` | `ba_unique()` / `ba_chunked(into:)` | 去重 / 分块 |
| `Collection` | `ba_safe(_:)` | 越界安全下标 |
| `Dictionary` | `ba_merged(with:)` | 合并 |
| `NotificationCenter` | `ba_observeKeyboardWillShow/Hide` | 键盘观察器（封装好 `BAKeyboardInfo`） |

### UIKit 扩展

| 类型 | API | 说明 |
| --- | --- | --- |
| `UIColor` | `init?(ba_hex:)` / `ba_rgb` / `ba_random` / `ba_dynamic(light:dark:)` / `ba_hexString` | 颜色一站式 |
| `UIView` | `ba_x/y/width/height` / `ba_setCornerRadius/Border/Shadow` / `ba_addSubviews(...)` / `ba_snapshotImage()` / `ba_parentViewController` | View 便利 |
| `UIView` (animation) | `ba_fadeIn/Out` / `ba_shake` / `ba_pulse` / `ba_springAppear` / `ba_slideIn(from:)` / `ba_rotate(by:)` | 常用动画 |
| `UIImage` | `ba_image(color:size:)` / `ba_resized(to:)` / `ba_roundedToCircle()` / `ba_tinted` / `ba_compressed(toKB:)` | 图像处理 |
| `UIButton` | `ba_make(...)` / `ba_onTap` | 链式构造 + 闭包点击 |
| `UILabel` | `ba_make(...)` / `ba_setLineSpacing` / `ba_highlight` | 文本样式 |
| `UIFont` | `ba_regular/medium/semibold/bold(_:)` / `ba_mono(_:weight:)` / `ba_scaled(_:weight:textStyle:)` / `ba_registerFont(named:)` | 字体快捷构造 / Dynamic Type / 自定义字体注册 |
| `UIStackView` | `ba_make(axis:spacing:...)` / `ba_addArrangedSubviews(...)` / `ba_removeAllArrangedSubviews` / `ba_insert(_:after:)` | 堆叠便利 |
| `UITextField` | `ba_placeholderColor` / `ba_maxLength` / `ba_toggleSecureEntry` / `ba_leftPadding(_:)` | 文本框便利 |
| `UIViewController` | `ba_alert` / `ba_actionSheet` / `ba_dismissKeyboard` / `ba_findInNavigation` | 弹窗与导航 |
| `UINavigationController` | `ba_apply(style:)` | 应用 `BANavigationBarStyle` |
| `CALayer` | `ba_rasterize` / `ba_softShadow` / `ba_border` | layer 便利 |

### 工具类

| 类 | 用途 |
| --- | --- |
| `BAToast` | 全局轻提示，4 种风格，自动找 keyWindow |
| `BALoadingHUD` | 全屏 / 局部阻塞型 loading，支持运行时更新文案 |
| `BALocalization` | 运行时切换语言，支持运行时字典 + .lproj 双路 |
| `BALogger` | 等级化日志，Debug 自动开启 |
| `BAUserDefault` / `BAUserDefaultCodable` | UserDefaults 属性包装器，支持 Codable |
| `BAKeychain` | 轻量 Keychain 读写 |
| `BADeviceInfo` | App / 系统 / 屏幕信息一站式 |

### UI 组件

| 组件 | 说明 |
| --- | --- |
| `BAGradientView` | 自动布局尺寸跟随的渐变 View，支持 4 个方向 |
| `BACardView` | 带圆角和柔和阴影的卡片容器 |
| `BABadgeView` | 自适应宽度的胶囊角标 |
| `BANavigationBarStyle` | NavigationBar 样式描述（实心 / 渐变 / 透明），配合 `UINavigationController.ba_apply` 一键应用 |
| `BATabBarController` | 自带选中弹跳动画 + 角标快捷 API 的 TabBarController |

## 集成方式

### Swift Package Manager（推荐）

在你的 `Package.swift` 中：

```swift
.package(url: "https://your-git-host/BASwiftKit.git", from: "0.1.0")
```

或在 Xcode 中：`File → Add Package Dependencies…`，输入仓库地址。

### 手动拷贝

直接把 `Sources/BASwiftKit` 目录拖入工程也能用，全部 UIKit 相关代码都使用条件编译（`#if canImport(UIKit)`），不会强依赖具体平台。

## 跑通 Demo

> Demo 工程通过 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 生成，避免把 `.xcodeproj` 这种易冲突的二进制提交进仓库。

```bash
# 1. 安装 XcodeGen（任选其一）
brew install xcodegen

# 2. 生成工程并打开
cd Demo
xcodegen generate
open BASwiftKitDemo.xcodeproj
```

如果不想装 XcodeGen，也可以在 Xcode 里手动新建 iOS App：

1. 新建一个 `iOS App`，名为 `BASwiftKitDemo`，最低系统 iOS 13。
2. 删除 Xcode 自动生成的 `ContentView` / `ViewController` 等。
3. 把 `Demo/BASwiftKitDemo/` 下所有 `.swift` 文件拖入工程（勾选 `Copy if needed` 视需要）。
4. 把项目根目录加为 Swift Package：`File → Add Package Dependencies → Add Local…`，选中本仓库根目录即可。
5. Build & Run。

## 测试

仓库自带单测，跑：

```bash
swift test
```

当前 14 个核心用例：String / Array / Date / Date+Calendar / Collection / Base64 / MD5 / Localization 等均已通过。

## 设计约束

- **命名**：所有公开 API 必须以 `ba_` 前缀挂载，确保宿主工程能 grep 到所有 BASwiftKit 调用。
- **解耦**：单个文件只能依赖 Foundation / UIKit 与本 module 内部，禁止跨模块强耦合，方便单独抽出。
- **平台保护**：UIKit 相关代码必须放在 `#if canImport(UIKit)` 中。
- **零依赖**：不引入任何第三方库。
