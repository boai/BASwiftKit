# BASwiftKit

> 一个面向 iOS UIKit 项目、可独立提取的 Swift 公共封装库 + MVVM Demo。

所有公开 API 均以 `ba_` 前缀挂载在系统类型上，避免与宿主工程冲突；
工具类、UI 组件、视图扩展之间保持低耦合，方便后续直接拷贝某一文件或整个 `Package/Sources/BASwiftKit` 目录到其他工程使用。

```
BASwiftKit/
├─ Package/                       # Swift Package root（SPM 引入指向此目录）
│  ├─ Package.swift               # Swift Package 入口（可直接 SwiftPM 引入）
│  ├─ Sources/BASwiftKit/         # 库代码：扩展 + 工具 + UI 组件
│  │  ├─ Extensions/
│  │  │  ├─ Foundation/           # String 按 Trim / Validation / Encoding / Size 拆分，
│  │  │  │                        # Date / Date+Calendar / Collection / Bundle / Data 等
│  │  │  └─ UIKit/                # UIColor / UIView / UIView+Animation / UIView+Gesture /
│  │  │                           # UIImage / UIButton / UILabel / UIFont / UITextField /
│  │  │                           # UIStackView / UIViewController / UIApplication / CALayer
│  │  ├─ Network/                 # URLSession 网络请求、Endpoint、拦截器、参数编码
│  │  ├─ Crypto/                  # Digest / HMAC / AES-CBC 独立加密封装
│  │  ├─ Storage/                 # FileManager / UserDefaults / Cache / BaseModel 缓存
│  │  ├─ Scanner/                 # 扫一扫：相机扫码会话 + 基础扫码页面
│  │  ├─ Layout/                  # 瀑布流 FlowLayout / 横向分页瀑布流
│  │  ├─ Bluetooth/               # 单设备 / 多设备蓝牙连接、收发、分包缓冲
│  │  ├─ Utilities/               # Logger / DeviceInfo / AppEnvironment / 权限 / 系统跳转
│  │  └─ UIComponents/            # GradientView / CardView / BadgeView /
│  │                              # NavigationBarStyle / TabBarController / Toast / HUD
│  └─ Tests/BASwiftKitTests/      # XCTest 单测
├─ Demo/                          # MVVM Demo 工程（与 Package 解耦，避免 Xcode 重复显示）
│  ├─ project.yml                 # XcodeGen 配置，path: ../Package
│  └─ BASwiftKitDemo/             # App 源码（App / Theme / Common / Modules）
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
| `Bundle` | `ba_appName` / `ba_appVersion` / `ba_buildNumber` / `ba_bundleId` / `ba_infoValue(forKey:)` / `ba_resourceURL/Data/JSON` | App 元数据 + 资源查找 |
| `NotificationCenter` | `ba_observeKeyboardWillShow/Hide` | 键盘观察器（封装好 `BAKeyboardInfo`） |

### UIKit 扩展

| 类型 | API | 说明 |
| --- | --- | --- |
| `UIColor` | `init?(ba_hex:)` / `ba_rgb` / `ba_random` / `ba_dynamic(light:dark:)` / `ba_hexString` | 颜色一站式 |
| `UIView` | `ba_x/y/width/height` / `ba_setCornerRadius/Border/Shadow` / `ba_addSubviews(...)` / `ba_snapshotImage()` / `ba_parentViewController` | View 便利 |
| `UIView` (animation) | `ba_fadeIn/Out` / `ba_shake` / `ba_pulse` / `ba_springAppear` / `ba_slideIn(from:)` / `ba_rotate(by:)` | 常用动画 |
| `UIView` (gesture) | `ba_onTap { view in ... }` / `ba_onLongPress { view in ... }` | 任意 View 闭包式手势 |
| `UIImage` | `ba_image(color:size:)` / `ba_resized(to:)` / `ba_roundedToCircle()` / `ba_tinted` / `ba_compressed(toKB:)` | 图像处理 |
| `UIButton` | `ba_make(...)` / `ba_onTap` | 链式构造 + 闭包点击 |
| `UILabel` | `ba_make(...)` / `ba_setLineSpacing` / `ba_highlight` | 文本样式 |
| `UIFont` | `ba_regular/medium/semibold/bold(_:)` / `ba_mono(_:weight:)` / `ba_scaled(_:weight:textStyle:)` / `ba_registerFont(named:)` | 字体快捷构造 / Dynamic Type / 自定义字体注册 |
| `UIStackView` | `ba_make(axis:spacing:...)` / `ba_addArrangedSubviews(...)` / `ba_removeAllArrangedSubviews` / `ba_insert(_:after:)` | 堆叠便利 |
| `UITextField` | `ba_placeholderColor` / `ba_maxLength` / `ba_toggleSecureEntry` / `ba_leftPadding(_:)` | 文本框便利 |
| `UIViewController` | `ba_alert` / `ba_actionSheet` / `ba_dismissKeyboard` / `ba_findInNavigation` | 弹窗与导航 |
| `UINavigationController` | `ba_apply(style:)` | 应用 `BANavigationBarStyle` |
| `UIApplication` | `ba_keyWindow` / `ba_topViewController` / `ba_currentViewController` | 多 scene 安全的 keyWindow + 当前顶层 VC |
| `UIWindow` | `ba_topViewController` / `ba_replaceRootViewController(_:duration:options:)` | Root VC 切换（带交叉淡入） |
| `UICollectionView` | `ba_register(_:)` / `ba_dequeue(_:for:)` / `ba_subscribe(...)` | Cell 注册、复用、简单绑定 |
| `CALayer` | `ba_rasterize` / `ba_softShadow` / `ba_border` | layer 便利 |

### 网络 / 加密

| 模块 | API | 说明 |
| --- | --- | --- |
| `BANetworkClient` | `request(_:)` / `request(_:responseType:)` / `get` / `post` / `makeURLRequest(_:)` | 基于 URLSession 的轻量网络层 |
| `BANetworkEndpoint` | `path` / `method` / `headers` / `parameters` / `encoding` / `ba_request` | 类型安全 Endpoint 描述 |
| `BANetworkRequest` | `path` / `method` / `headers` / `parameters` / `encoding` | 请求模型 |
| `BAURLRequestInterceptor` | `adapt(_:)` / `process(_:data:)` | 请求和响应拦截 |
| `BADigest` | `digest(_:algorithm:)` / `hexString(_:algorithm:)` | MD5/SHA 系列摘要，MD5/SHA1 仅建议兼容旧接口 |
| `BAHMAC` | `sign(_:key:algorithm:)` / `hexString(_:key:algorithm:)` | HMAC 签名，默认 SHA256 |
| `BAAES` | `cbcEncrypt(_:key:iv:)` / `cbcDecrypt(_:key:iv:)` | AES-CBC-PKCS7 加解密 |
| `Data` / `String` Crypto | `ba_sha256String` / `ba_hmac` / `ba_aesCBCEncryptedBase64` / `ba_aesCBCDecryptedFromBase64` | 常用加密快捷入口 |

### 存储 / 数据 / 蓝牙

| 模块 | API | 说明 |
| --- | --- | --- |
| `BAFileManager` | Documents/Caches/tmp 路径、读写、删除、大小统计 | 文件管理常用能力 |
| `BAUserDefaults` / `@BAUserDefault` | 基础类型和 Codable 存取 | UserDefaults 快捷封装 |
| `BACacheManager` | 内存 / 磁盘 / 混合缓存、过期策略、LRU | 通用缓存框架 |
| `BABaseModel` | `ba_saveCache` / `ba_updateCache` / `ba_removeCache` / `ba_cache` | 接口 Model 手动缓存生命周期 |
| `Data` Bytes | `ba_hexString` / `ba_spacedHexString` / `ba_uint16` / `ba_chunks` / `ba_crc16ModbusData` | 字节解析、分包、校验 |
| `BADataReader` | `readUInt8` / `readUInt16` / `readData` | 顺序读 Data |
| `BABluetoothManager` | 扫描、单设备/多设备连接、读写、订阅 | CoreBluetooth 常用封装 |
| `BABluetoothDataBuffer` | `ba_append` / `ba_popFrame` | 按 header/footer 缓冲拆包 |

### 扫码 / 布局 / 运行环境

| 模块 | API | 说明 |
| --- | --- | --- |
| `BAScannerSession` | `prepare(in:)` / `start` / `stop` / `setTorch` | 独立相机扫码会话，支持二维码和常见条码 |
| `BAScannerViewController` | `onResult` / `onError` / `restartScanning` | 基础扫一扫页面，可直接用或二次定制 |
| `BAScanCodeType` | `.qr` / `.ean13` / `.code128` / `.pdf417` / `.aztec` 等 | 扫码类型配置 |
| `BAWaterfallFlowLayout` | `scrollDirection` / `columnCount` / `rowCount` / `BAWaterfallFlowLayoutDelegate` | 自适应纵向/横向瀑布流 |
| `BAPagedWaterfallFlowLayout` | `rowCount` / `columnCount` / `itemsPerPage` / `pageCount` | 横向分页瀑布流，每页行优先排列 |
| `BAAppEnvironment` | `ba_screenWidth` / `ba_keyWindow` / `ba_currentViewController` / `ba_safeAreaTop` / `ba_statusBarHeight` / `ba_scaleWidth` | 替代常见宏定义的运行环境变量 |

### 工具类

| 类 | 用途 |
| --- | --- |
| `BAToast` | 全局轻提示，4 种风格，自动找 keyWindow |
| `BALoadingHUD` | 全屏 / 局部阻塞型 loading，支持运行时更新文案 |
| `BALocalization` | 运行时切换语言，支持运行时字典 + .lproj 双路 |
| `BAResourceBundle` | 组件化资源 bundle 查找（按 anchor 类 + bundleName 解析），支持 `ba_image(named:from:)` |
| `BADeviceInfo`（扩展） | `ba_modelName`（机型映射 iPhone / iPad / Watch 主流型号）、`ba_userDeviceName`、`ba_isSimulator`、`ba_processorCount`、`ba_physicalMemoryBytes`；电池 `ba_enableBatteryMonitoring()` / `ba_batteryLevel` / `ba_batteryState(+Description)`；存储 `ba_totalDiskBytes / ba_freeDiskBytes / ba_usedDiskBytes`；地域 `ba_localeIdentifier / ba_timeZoneIdentifier / ba_languageCode`；`ba_formatBytes(_:)` |
| `BAAppEnvironment` | 屏幕宽高、KeyWindow、当前 VC、安全区、状态栏、导航栏/TabBar 高度、设计稿等比换算 |
| `BACache` | `ba_size(of:)` / `ba_sizeAsync` 统计 Library/Caches + tmp 占用；`ba_clear(directories:)` / `ba_clearAsync` 一键清除 |
| `BALogger` | 等级化日志，Debug 自动开启 |
| `BAUserDefault` / `BAUserDefaultCodable` | UserDefaults 属性包装器，支持 Codable |
| `BAKeychain` | 轻量 Keychain 读写 |
| `BADeviceInfo` | App / 系统 / 屏幕 / 电池 / 存储信息一站式 |
| `BASystemPermission` | 相机、麦克风、相册、定位、通知权限查询和请求 |
| `BAAppNavigator` | App 设置页、电话、短信、邮件、浏览器和地图跳转 |

### UI 组件

| 组件 | 说明 |
| --- | --- |
| `BAGradientView` | 自动布局尺寸跟随的渐变 View，支持 4 个方向 |
| `BACardView` | 带圆角和柔和阴影的卡片容器 |
| `BABadgeView` | 自适应宽度的胶囊角标 |
| `BANavigationBarStyle` | NavigationBar 样式描述（实心 / 渐变 / 透明），配合 `UINavigationController.ba_apply` 一键应用 |
| `BATabBarController` | 自带选中弹跳动画 + 角标快捷 API 的 TabBarController |
| `BAEmptyView` | 空状态视图，支持图片、标题、内容和操作按钮 |
| `BACustomAlertViewController` | 自定义弹窗容器，支持表单类弹窗组合 |

## 集成方式

### Swift Package Manager（推荐）

在你的 `Package.swift` 中：

```swift
.package(url: "https://your-git-host/BASwiftKit.git", from: "0.1.0")
```

或在 Xcode 中：`File → Add Package Dependencies…`，输入仓库地址。

### 手动拷贝

直接把 `Package/Sources/BASwiftKit` 目录拖入工程也能用，全部 UIKit 相关代码都使用条件编译（`#if canImport(UIKit)`），不会强依赖具体平台。

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
4. 把 Package 目录加为 Swift Package：`File → Add Package Dependencies → Add Local…`，选中本仓库下的 `Package/` 目录即可。
5. Build & Run。

## 测试

仓库自带单测，跑：

```bash
cd Package && swift test
```

当前 20 个核心用例：String / Array / Date / Date+Calendar / Collection / Base64 / MD5 / Localization / Data 字节处理 / Bluetooth 数据缓冲 / BaseModel 缓存 / Network 请求构建 / Crypto SHA-HMAC-AES 等均已通过。

## 设计约束

- **命名**：所有公开 API 必须以 `ba_` 前缀挂载，确保宿主工程能 grep 到所有 BASwiftKit 调用。
- **解耦**：单个文件只能依赖 Foundation / UIKit 与本 module 内部，禁止跨模块强耦合，方便单独抽出。
- **平台保护**：UIKit 相关代码必须放在 `#if canImport(UIKit)` 中。
- **零依赖**：不引入任何第三方库。
