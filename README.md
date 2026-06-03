# BASwiftKit

[![CocoaPods](https://img.shields.io/cocoapods/v/BASwiftKit?color=blue&label=CocoaPods)](https://cocoapods.org/pods/BASwiftKit)
[![Platform](https://img.shields.io/cocoapods/p/BASwiftKit?color=lightgrey&label=Platform)](https://cocoapods.org/pods/BASwiftKit)
[![Swift 5.0](https://img.shields.io/badge/Swift-5.0-orange?logo=swift)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![SPM](https://img.shields.io/badge/SPM-supported-brightgreen)](https://github.com/boai/BASwiftKit)

> 面向 iOS UIKit 项目的 Swift 公共组件库，提供 Foundation/UIKit 扩展、网络层、加密、蓝牙、扫码等开箱即用的工具集。

---

## 目录

- [一、功能特性](#一功能特性)
- [二、环境要求](#二环境要求)
- [三、安装集成](#三安装集成)
- [四、功能概览](#四功能概览)
  - [Foundation 扩展](#foundation-扩展)
  - [UIKit 扩展](#uikit-扩展)
  - [网络请求](#网络请求)
  - [加解密](#加解密)
  - [存储与缓存](#存储与缓存)
  - [蓝牙](#蓝牙)
  - [扫码](#扫码)
  - [WebSocket](#websocket)
  - [路由](#路由)
  - [日志](#日志)
  - [响应式](#响应式)
  - [布局](#布局)
  - [UI 组件](#ui-组件)
  - [工具类](#工具类)
- [五、快速上手](#五快速上手)
- [六、Demo 工程](#六demo-工程)
- [七、测试](#七测试)
- [八、设计原则](#八设计原则)
- [九、贡献者](#九贡献者)
- [十、License](#十license)

---

## 一、功能特性

- 🧩 **Foundation 扩展** — `String` / `Date` / `Array` / `Dictionary` / `Data` / `Bundle` 等常用类型扩展，所有 API 以 `ba_` 前缀命名
- 🎨 **UIKit 扩展** — `UIView` / `UIColor` / `UIImage` / `UIButton` / `UILabel` 等链式构造、动画、手势闭包
- 🌐 **网络请求** — 基于 `URLSession` 的轻量网络层，支持 Endpoint 描述、请求/响应拦截器、参数编码
- 🔐 **加解密** — SHA 系列摘要、HMAC 签名、AES-CBC-PKCS7 加解密
- 📦 **存储与缓存** — FileManager / UserDefaults / Keychain 封装 + 内存/磁盘/混合缓存框架
- 📡 **蓝牙** — `CoreBluetooth` 封装，支持单/多设备连接、数据收发、分包缓冲
- 📷 **扫码** — `AVFoundation` 相机扫码会话 + 基础扫码页面，支持二维码和主流条码
- 🔌 **WebSocket** — Starscream 封装，支持自定义协议解析器、心跳、断线重连
- 🧭 **路由** — URL pattern 匹配、参数注入、拦截器链，解耦页面跳转
- 📝 **日志** — 分级日志系统，支持控制台输出和 SQLite 持久化
- ⚡ **响应式** — 轻量 `Observable` / `Disposable` 实现
- 🏞️ **布局** — 纵向/横向瀑布流、横向分页瀑布流 `UICollectionViewFlowLayout`
- 🧱 **UI 组件** — `GradientView` / `CardView` / `BadgeView` / `TabBarController` / `Toast` / `HUD` 等
- 🛠️ **工具类** — 设备信息、权限请求、系统跳转、多语言切换、正则校验等

---

## 二、环境要求

| 项目 | 版本 |
|------|------|
| iOS | 15.0+ |
| Swift | 5.0+ |
| Xcode | 14.0+ |
| 第三方依赖 | [SnapKit](https://github.com/SnapKit/SnapKit) ~> 5.7.0 / [Starscream](https://github.com/daltoniam/Starscream) ~> 4.0.0 |

---

## 三、安装集成

### CocoaPods

```ruby
# Podfile
platform :ios, '15.0'

pod 'BASwiftKit', '~> 0.1.0'
```

### Swift Package Manager

在 Xcode 中：`File → Add Package Dependencies…`，输入：

```
https://github.com/boai/BASwiftKit.git
```

或在 `Package.swift` 中添加：

```swift
.package(url: "https://github.com/boai/BASwiftKit.git", from: "0.1.0")
```

### 手动集成

将 `Package/Sources/BASwiftKit` 目录拖入工程即可，需自行引入 SnapKit 和 Starscream 依赖。

---

## 四、功能概览

### Foundation 扩展

所有 Foundation 扩展均以 `ba_` 前缀挂载在系统类型上，避免符号冲突。

```swift
// String
"hello@example.com".ba_isEmail          // true
"Hello World".ba_md5                    // "b10a8db164e0754105b7a99be72e3fe5"
"   trim me   ".ba_trimmed              // "trim me"

// Date
Date().ba_string(format: "yyyy-MM-dd")  // "2026-06-03"
Date().ba_isToday                       // true
Date().ba_adding(days: 7)               // 7 天后的日期

// Array
[1, 2, 2, 3].ba_unique()               // [1, 2, 3]
[1, 2, 3, 4, 5].ba_chunked(into: 2)     // [[1, 2], [3, 4], [5]]

// Collection（安全下标）
let arr = [1, 2, 3]
arr.ba_safe(5)                          // nil，不会越界崩溃

// Bundle
Bundle.main.ba_appName                  // "MyApp"
Bundle.main.ba_appVersion               // "1.0.0"
Bundle.main.ba_buildNumber              // "42"
```

**API 速查：**

| 类型 | API | 说明 |
|------|-----|------|
| `String` | `ba_trimmed` / `ba_isBlank` / `ba_compact` | 空白处理 |
| `String` | `ba_isEmail` / `ba_isChinaMobile` / `ba_isURL` / `ba_isPureDigits` | 格式校验 |
| `String` | `ba_md5` / `ba_base64Encoded` / `ba_base64Decoded` | 编码摘要 |
| `String` | `ba_width(font:)` / `ba_height(font:maxWidth:)` | 文本测量 |
| `String` | `ba_localized` / `ba_date(format:)` | 国际化 / 日期解析 |
| `Date` | `ba_string(format:)` / `ba_relativeFromNow` | 格式化 / 相对时间 |
| `Date` | `ba_startOfDay` / `ba_endOfMonth` / `ba_startOfMonth` | 日期边界 |
| `Date` | `ba_adding(days:months:years:)` / `ba_daysBetween(_:)` | 日期运算 |
| `Date` | `ba_isToday` / `ba_isYesterday` / `ba_isWeekend` | 日期查询 |
| `Array` | `ba_unique()` / `ba_chunked(into:)` | 去重 / 分块 |
| `Collection` | `ba_safe(_:)` | 越界安全下标 |
| `Dictionary` | `ba_merged(with:)` | 字典合并 |
| `Bundle` | `ba_appName` / `ba_appVersion` / `ba_bundleId` / `ba_resourceURL` | App 元数据 |
| `NotificationCenter` | `ba_observeKeyboardWillShow/Hide` | 键盘事件观察 |

---

### UIKit 扩展

所有 UIKit 扩展均放置在 `#if canImport(UIKit)` 条件编译块内，对非 iOS 平台无害。

```swift
// UIColor — 十六进制颜色、深浅色动态切换
let color = UIColor(ba_hex: "#FF5733")
let adaptive = UIColor.ba_dynamic(light: .white, dark: .black)

// UIView — 快捷布局、圆角阴影、链式动画
view.ba_setCornerRadius(8)
view.ba_setShadow(radius: 4, opacity: 0.2)
view.ba_addSubviews(titleLabel, iconView, badge)
view.ba_fadeIn(duration: 0.3)
view.ba_shake()

// UIView — 闭包式手势
view.ba_onTap { view in
    print("Tapped!")
}

// UIButton — 链式构造
let btn = UIButton.ba_make(title: "提交", titleColor: .white, font: .ba_bold(16))
btn.ba_onTap { btn in
    print("Button tapped")
}

// UIImage — 纯色生成、缩放裁剪
let avatar = UIImage.ba_image(color: .blue, size: CGSize(width: 40, height: 40))
let compressed = image.ba_compressed(toKB: 500)
```

**API 速查：**

| 类型 | API | 说明 |
|------|-----|------|
| `UIColor` | `init?(ba_hex:)` / `ba_random` / `ba_dynamic(light:dark:)` / `ba_hexString` | 颜色构造 |
| `UIView` | `ba_x/y/width/height` / `ba_setCornerRadius` / `ba_setBorder` / `ba_setShadow` | 布局与样式 |
| `UIView` | `ba_addSubviews(...)` / `ba_snapshotImage()` / `ba_parentViewController` | 视图层级 |
| `UIView` | `ba_fadeIn/Out` / `ba_shake` / `ba_pulse` / `ba_springAppear` / `ba_slideIn(from:)` | 动画 |
| `UIView` | `ba_onTap { }` / `ba_onLongPress { }` | 手势闭包 |
| `UIImage` | `ba_image(color:size:)` / `ba_resized(to:)` / `ba_roundedToCircle()` / `ba_tinted` / `ba_compressed(toKB:)` | 图像处理 |
| `UIButton` | `ba_make(...)` / `ba_onTap` | 构造与事件 |
| `UILabel` | `ba_make(...)` / `ba_setLineSpacing` | 文本样式 |
| `UIFont` | `ba_regular/medium/semibold/bold(_:)` / `ba_mono(_:weight:)` / `ba_scaled(_:)` | 字体快捷 |
| `UIStackView` | `ba_make(axis:spacing:)` / `ba_addArrangedSubviews(...)` | 堆叠布局 |
| `UITextField` | `ba_placeholderColor` / `ba_maxLength` / `ba_toggleSecureEntry` | 输入框 |
| `UIViewController` | `ba_alert` / `ba_actionSheet` / `ba_dismissKeyboard` | 弹窗 |
| `UINavigationController` | `ba_apply(style:)` | 导航栏样式 |
| `UIApplication` | `ba_keyWindow` / `ba_topViewController` | 窗口与层级 |
| `UICollectionView` | `ba_register(_:)` / `ba_dequeue(_:for:)` | Cell 复用 |
| `CALayer` | `ba_rasterize` / `ba_softShadow` / `ba_border` | 渲染与样式 |

---

### 网络请求

基于 `URLSession` 的轻量网络层，支持 Endpoint 风格描述、请求/响应拦截器链路、多种参数编码方式。

```swift
// 定义 Endpoint
enum UserAPI {
    case profile(userId: String)
}

extension UserAPI: BANetworkEndpoint {
    var path: String {
        switch self {
        case .profile(let id): return "/users/\(id)"
        }
    }
    var method: BAHTTPMethod { .get }
}

// 发起请求
BANetworkClient.shared.request(UserAPI.profile(userId: "123"), responseType: UserModel.self) { result in
    switch result {
    case .success(let user): print(user.name)
    case .failure(let error): print(error)
    }
}
```

**核心类型：**

| 类型 | 说明 |
|------|------|
| `BANetworkClient` | 网络请求客户端，支持泛型响应解析 |
| `BANetworkEndpoint` | Endpoint 协议，描述 path / method / headers / parameters |
| `BANetworkRequest` | 请求值类型 |
| `BAURLRequestInterceptor` | 请求/响应拦截器协议 |
| `BAParameterEncoding` | 参数编码策略（URL、JSON 等） |

---

### 加解密

基于 `CommonCrypto` 的独立加解密模块，支持摘要、HMAC 签名、AES-CBC 加解密。

```swift
// 摘要
let sha256 = BADigest.hexString("hello world", algorithm: .sha256)

// HMAC 签名
let signature = BAHMAC.hexString("message", key: "secret", algorithm: .sha256)

// AES-CBC 加解密
let key = "0123456789abcdef0123456789abcdef".data(using: .utf8)!
let iv  = "0123456789abcdef".data(using: .utf8)!
let encrypted = BAAES.cbcEncrypt(plainData, key: key, iv: iv)
let decrypted = BAAES.cbcDecrypt(encrypted, key: key, iv: iv)

// Data / String 快捷入口
"hello".ba_sha256String
data.ba_aesCBCEncryptedBase64(key: key, iv: iv)
```

**核心类型：**

| 类型 | API | 说明 |
|------|-----|------|
| `BADigest` | `digest(_:algorithm:)` / `hexString(_:algorithm:)` | SHA-256/512 摘要 |
| `BAHMAC` | `sign(_:key:algorithm:)` / `hexString(_:key:algorithm:)` | HMAC 签名 |
| `BAAES` | `cbcEncrypt(_:key:iv:)` / `cbcDecrypt(_:key:iv:)` | AES-CBC 加解密 |

---

### 存储与缓存

```swift
// UserDefaults 属性包装器
@BAUserDefault("user_name", defaultValue: "")
var userName: String

// Cache 管理器
BACacheManager.shared.set("key", value: myObject, ttl: 3600)
let cached: MyModel? = BACacheManager.shared.get("key")

// Keychain
BAKeychain.shared.set("secret_token", forKey: "auth_token")
let token = BAKeychain.shared.string(forKey: "auth_token")
```

**核心类型：**

| 类型 | 说明 |
|------|------|
| `BAFileManager` | Documents / Caches / tmp 路径、文件读写删除、大小计算 |
| `BAUserDefaults` / `@BAUserDefault` | 基础类型和 Codable 存取 |
| `BACacheManager` | 内存 / 磁盘 / 混合缓存，支持过期策略和 LRU 淘汰 |
| `BABaseModel` | 接口 Model 手动缓存生命周期管理 |
| `BAKeychain` | Keychain 安全读写 |

---

### 蓝牙

`CoreBluetooth` 完整封装，支持扫描、单/多设备并发连接、数据收发订阅、按帧头帧尾缓冲拆包。

```swift
// 扫描并连接
BABluetoothManager.shared.scanForPeripherals(withServices: [serviceUUID]) { peripheral in
    BABluetoothManager.shared.connect(peripheral) { result in
        // 连接成功
    }
}

// 数据收发
BABluetoothManager.shared.send(data, to: peripheral, characteristic: charUUID)

// 缓冲拆包
buffer.ba_append(incomingData)
while let frame = buffer.ba_popFrame() {
    // 处理完整数据帧
}
```

**核心类型：**

| 类型 | 说明 |
|------|------|
| `BABluetoothManager` | 扫描、单/多设备连接、读写特征、订阅通知 |
| `BABluetoothDataBuffer` | 按帧头/帧尾分包缓冲 |

---

### 扫码

基于 `AVFoundation` 的相机扫码模块，支持二维码和主流条码格式。

```swift
// 使用基础扫码页面
let scanner = BAScannerViewController()
scanner.onResult = { result in
    print("扫码结果: \(result.value)")
}
present(scanner, animated: true)

// 或只使用会话层自定义 UI
let session = BAScannerSession()
session.prepare(in: previewView)
session.start()
```

**核心类型：**

| 类型 | 说明 |
|------|------|
| `BAScannerSession` | 相机扫码会话，扫码类型可配置 |
| `BAScannerViewController` | 基础扫码页面，可继承或组合使用 |
| `BAScanCodeType` | 扫码类型：`.qr` / `.ean13` / `.code128` / `.pdf417` / `.aztec` 等 |

---

### WebSocket

Starscream 的高层封装，支持自定义协议解析器、心跳保活、自动重连。

```swift
let config = BASocketConfiguration(url: "wss://echo.example.com/socket")
let client = BASocketClient(configuration: config)

client.onConnected = { print("已连接") }
client.onMessage = { message in print("收到: \(message)") }
client.connect()
```

**核心类型：**

| 类型 | 说明 |
|------|------|
| `BASocketClient` | WebSocket 客户端主体 |
| `BASocketConfiguration` | 连接配置（URL、超时、重连策略） |
| `BASocketParser` | 自定义协议解析器协议 |
| `BASocketState` | 连接状态枚举 |

---

### 路由

URL pattern 匹配路由，支持页面跳转、参数注入、拦截器链。

```swift
// 注册路由
BARouter.shared.register(BARouteConfig(
    pattern: "/user/:userId",
    targetType: .viewController(UserProfileVC.self),
    sourceType: .push
))

// 调用路由
BARouter.shared.open("/user/123", params: ["name": "张三"])
```

**核心类型：**

| 类型 | 说明 |
|------|------|
| `BARouter` | 路由管理器，注册/打开路由 |
| `BARouteConfig` | 路由配置（pattern、目标、拦截器） |
| `BARouteInterceptor` | 路由拦截器协议 |
| `BARoutable` / `BAServiceable` | 页面/服务协议 |

---

### 日志

分级日志系统，支持 Debug / Info / Warning / Error 四级，可输出到控制台或 SQLite 持久化。

```swift
BALog.debug("调试信息")
BALog.info("用户登录，id: \(userId)")
BALog.warning("缓存过期，重新请求")
BALog.error("网络请求失败: \(error)")
```

**核心类型：**

| 类型 | 说明 |
|------|------|
| `BALogManager` | 日志管理器，控制日志等级和输出目标 |
| `BALogSQLiteStore` | SQLite 持久化存储 |
| `BALogExporter` | 日志导出 |
| `BAAutoTracker` | 自动埋点（页面进入/离开） |

---

### 响应式

轻量 Observable / Disposable 实现，零依赖。

```swift
let observable = BAObservable<Int>(0)
let disposable = observable.subscribe { value in
    print("值变为: \(value)")
}
observable.value = 42  // 输出: 值变为: 42
disposable.dispose()
```

---

### 布局

自定义 `UICollectionViewFlowLayout`，支持纵向/横向瀑布流和横向分页布局。

```swift
let layout = BAWaterfallFlowLayout()
layout.columnCount = 2
collectionView.collectionViewLayout = layout
```

**核心类型：**

| 类型 | 说明 |
|------|------|
| `BAWaterfallFlowLayout` | 自适应纵向/横向瀑布流 |
| `BAPagedWaterfallFlowLayout` | 横向分页瀑布流，每页行优先排列 |

---

### UI 组件

开箱即用的 UI 组件，均可独立使用。

```swift
// GradientView
let gradient = BAGradientView(colors: [.red, .blue], direction: .topToBottom)
view.addSubview(gradient)

// Toast
BAToast.show("操作成功", style: .success)

// Loading HUD
BALoadingHUD.show("加载中...")
BALoadingHUD.dismiss()
```

**组件列表：**

| 组件 | 说明 |
|------|------|
| `BAGradientView` | 自动布局渐变 View，4 个方向 |
| `BACardView` | 圆角 + 柔和阴影卡片容器 |
| `BABadgeView` | 自适应宽度胶囊角标 |
| `BANavigationBarStyle` | 导航栏样式（实心/渐变/透明） |
| `BATabBarController` | 选中弹跳动画 + 角标 API |
| `BAEmptyView` | 空状态视图（图+标题+按钮） |
| `BACustomAlertViewController` | 自定义弹窗容器 |

---

### 工具类

| 类型 | 说明 |
|------|------|
| `BAToast` | 全局轻提示，4 种风格 |
| `BALoadingHUD` | 全屏/局部 Loading |
| `BAProgressHUD` | 进度 HUD |
| `BALocalization` | 运行时语言切换 |
| `BAResourceBundle` | 组件化资源 bundle 查找 |
| `BADeviceInfo` | 设备型号、电池、存储、网络信息 |
| `BAAppEnvironment` | 屏幕尺寸、安全区、状态栏、导航栏高度 |
| `BACache` | 缓存目录大小统计与清除 |
| `BASystemPermission` | 相机、麦克风、相册、定位、通知权限 |
| `BAAppNavigator` | 系统设置、电话、短信、邮件、浏览器跳转 |
| `BARegexValidator` | 正则校验工具 |
| `BACountdownManager` | 倒计时管理器 |

---

## 五、快速上手

```swift
import BASwiftKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        // 设置导航栏样式
        navigationController?.ba_apply(style: .solid(.systemBlue))

        // 十六进制颜色
        view.backgroundColor = UIColor(ba_hex: "#F5F5F5")

        // 添加一个带圆角和阴影的卡片
        let card = BACardView()
        card.ba_setCornerRadius(12)
        view.addSubview(card)

        // 发一个网络请求
        BANetworkClient.shared.get("/api/config") { (result: Result<Config, BANetworkError>) in
            switch result {
            case .success(let config): print(config)
            case .failure(let error): BAToast.show(error.localizedDescription, style: .error)
            }
        }
    }
}
```

---

## 六、Demo 工程

Demo 通过 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 生成 `.xcodeproj`，再通过 [CocoaPods](https://cocoapods.org) 集成 BASwiftKit 本地 pod，避免二进制文件和依赖冲突。

```bash
# 1. 安装 XcodeGen（如已安装可跳过）
brew install xcodegen

# 2. 生成工程 + 安装依赖
cd Demo
xcodegen generate
pod install

# 3. 打开 workspace
open BASwiftKitDemo.xcworkspace
```

> **注意**：必须打开 `.xcworkspace` 而不是 `.xcodeproj`，否则无法加载 CocoaPods 依赖。

---

## 七、测试

```bash
cd Package && swift test
```

已覆盖 String / Array / Date / Calendar / Collection / Base64 / MD5 / Localization / Data 字节 / Bluetooth 数据缓冲 / BaseModel 缓存 / Network 请求构建 / Crypto SHA-HMAC-AES 等核心用例。

---

## 八、设计原则

- **命名规范** — 所有公开 API 以 `ba_` 前缀挂载，`grep "ba_"` 即可定位所有 BASwiftKit 调用
- **低耦合** — 每个文件仅依赖 Foundation / UIKit 与本模块，可单独抽取到其他工程
- **平台安全** — UIKit 代码统一使用 `#if canImport(UIKit)` 条件编译保护
- **最小依赖** — 仅依赖 SnapKit 和 Starscream 两个第三方库，核心能力零外部依赖

---

## 九、贡献者

| 贡献者 | 角色 |
|--------|------|
| [boai](https://github.com/boai) | 作者 & 维护者 |
| [Claude](https://claude.ai) | AI 协作开发 |

---

## 十、License

BASwiftKit is available under the [MIT License](LICENSE).
