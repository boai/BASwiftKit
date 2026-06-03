#
#  BASwiftKit.podspec
#  BASwiftKit
#
#  CocoaPods 集成入口。
#  使用方式：pod 'BASwiftKit', '~> 0.1.0'
#

Pod::Spec.new do |s|
  # ──────────────────────────────────────────────
  #  基本信息
  # ──────────────────────────────────────────────
  s.name             = 'BASwiftKit'
  s.version          = '0.1.0'
  s.summary          = '一个面向 iOS UIKit 项目的 Swift 公共组件库，提供 Foundation/UIKit 扩展、网络层、加密、蓝牙、扫码等开箱即用的工具集。'
  s.description      = <<-DESC
    BASwiftKit 是一套低耦合、可独立提取的 Swift 工具组件集合，涵盖：
    - Foundation 扩展（String/Date/Array/Data/Bundle/NotificationCenter 等，ba_ 前缀）
    - UIKit 扩展（UIView/UIColor/UIImage/UIButton/UILabel 等链式构造与动画）
    - 网络层（URLSession 封装，支持 Endpoint/Interceptor/参数编码）
    - 加解密（SHA 系列摘要、HMAC 签名、AES-CBC 加解密）
    - 蓝牙（CoreBluetooth 封装，单/多设备连接、分包缓冲）
    - 扫码（AVFoundation 相机扫码会话 + 基础扫码页面）
    - WebSocket（Starscream 封装，支持自定义协议解析器）
    - 路由（URL pattern 匹配、参数注入、拦截器链）
    - 日志（分级日志、SQLite 持久化、自动埋点）
    - 响应式（轻量 Observable/Disposable 实现）
    - 存储（FileManager/UserDefaults/Cache/Keychain 便捷封装）
    - 布局（纵向/横向瀑布流、分页瀑布流 FlowLayout）
    - UI 组件（GradientView/CardView/BadgeView/TabBar/Toast/HUD 等）
    - 工具类（设备信息、权限请求、系统跳转、多语言、正则校验等）
    所有公开 API 以 `ba_` 前缀命名，避免与宿主工程符号冲突。
  DESC

  # ──────────────────────────────────────────────
  #  仓库 & 作者
  # ──────────────────────────────────────────────
  s.homepage         = 'https://github.com/boai/BASwiftKit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'boai' => '13014692+boai@users.noreply.github.com' }
  s.source           = { :git => 'https://github.com/boai/BASwiftKit.git', :tag => s.version.to_s }

  # ──────────────────────────────────────────────
  #  平台 & Swift 版本
  # ──────────────────────────────────────────────
  s.ios.deployment_target = '15.0'
  s.swift_version    = '5.0'

  # ──────────────────────────────────────────────
  #  源文件
  #  与 SPM Package.swift 中 target path 保持一致：
  #  Package/Sources/BASwiftKit/
  # ──────────────────────────────────────────────
  s.source_files     = 'Package/Sources/BASwiftKit/**/*.swift'

  # ──────────────────────────────────────────────
  #  第三方依赖
  #  与 Package.swift 中 dependency 版本对齐：
  #  - SnapKit   → 自动布局 DSL
  #  - Starscream → WebSocket 底层
  # ──────────────────────────────────────────────
  s.dependency 'SnapKit', '~> 5.7.0'
  s.dependency 'Starscream', '~> 4.0.0'

  # ──────────────────────────────────────────────
  #  系统框架依赖（必需）
  #  Swift Package 不需要显式声明，但 CocoaPods 需要。
  #  按模块实际使用的系统框架列出：
  # ──────────────────────────────────────────────
  s.frameworks = 'UIKit', 'Foundation', 'AVFoundation', 'CoreBluetooth', 'Security', 'WebKit'

  # ──────────────────────────────────────────────
  #  系统框架依赖（可选 / weak link）
  #  仅在特定模块中使用，为降低宿主工程的强制链接负担，
  #  声明为 weak_frameworks。若宿主未使用对应模块，
  #  这些框架不会在最终 App 中被强制引入。
  #
  #  - CoreLocation      → BASystemPermission 定位权限
  #  - Photos            → BASystemPermission 相册权限
  #  - UserNotifications → BASystemPermission 通知权限
  #  - CoreImage         → UIImage+BA 图像滤镜
  #  - CoreText          → UIFont+BA 自定义字体
  # ──────────────────────────────────────────────
  s.weak_frameworks = 'CoreLocation', 'Photos', 'UserNotifications', 'CoreImage', 'CoreText'

  # ──────────────────────────────────────────────
  #  系统 C 库依赖
  #  - sqlite3 → BALogSQLiteStore 日志 SQLite 持久化
  # ──────────────────────────────────────────────
  s.libraries = 'sqlite3'
end
