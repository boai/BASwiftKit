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
  s.author           = { 'boai' => 'boai@users.noreply.github.com' }
  s.source           = { :git => 'https://github.com/boai/BASwiftKit.git', :tag => s.version.to_s }

  # ──────────────────────────────────────────────
  #  平台 & Swift 版本
  # ──────────────────────────────────────────────
  s.ios.deployment_target = '15.0'
  s.swift_version    = '5.0'

  # ──────────────────────────────────────────────
  #  Subspecs（模块化）
  #
  #  默认安装 Core + WebView，保持 `pod 'BASwiftKit'` 行为不变（= 全量）。
  #  WebView 子模块完全自包含（仅依赖 UIKit/WebKit，不依赖 SnapKit/Starscream/其它模块），
  #  可单独安装：`pod 'BASwiftKit/WebView'`，为后续整体拆分为独立 Pod 做好准备。
  #  源文件路径与 SPM Package.swift 的 target path 一致：Package/Sources/BASwiftKit/
  # ──────────────────────────────────────────────
  s.default_subspecs = ['Core', 'WebView']

  # 核心：除 WebView 外的全部能力（Foundation/UIKit 扩展、网络、加密、蓝牙、扫码、
  #       WebSocket、路由、日志、响应式、存储、布局、UI 组件、工具类、主题等）
  s.subspec 'Core' do |core|
    core.source_files  = 'Package/Sources/BASwiftKit/**/*.swift'
    core.exclude_files = 'Package/Sources/BASwiftKit/WebView/**/*.swift'

    # 第三方依赖（与 Package.swift 版本对齐）
    core.dependency 'SnapKit', '~> 5.7.0'      # 自动布局 DSL
    core.dependency 'Starscream', '~> 4.0.0'   # WebSocket 底层

    # 必需系统框架（WebKit 归 WebView 子模块）
    core.frameworks = 'UIKit', 'Foundation', 'AVFoundation', 'CoreBluetooth', 'Security'
    # 可选 / weak link：仅特定模块使用，降低宿主强制链接负担
    core.weak_frameworks = 'CoreLocation', 'Photos', 'UserNotifications', 'CoreImage', 'CoreText'
    # 系统 C 库：sqlite3 → BALogSQLiteStore 日志持久化
    core.libraries = 'sqlite3'
  end

  # WebView：自包含组件，零三方/跨模块依赖（仅 UIKit + WebKit），可独立拆分为单独 Pod
  s.subspec 'WebView' do |web|
    web.source_files = 'Package/Sources/BASwiftKit/WebView/**/*.swift'
    web.frameworks   = 'UIKit', 'Foundation', 'WebKit'
  end
end
