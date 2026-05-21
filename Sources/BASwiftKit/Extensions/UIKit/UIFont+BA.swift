//
//  UIFont+BA.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

#if canImport(UIKit)
import UIKit
import CoreText

public extension UIFont {

    // MARK: - 系统字体快捷构造

    static func ba_regular(_ size: CGFloat) -> UIFont { .systemFont(ofSize: size, weight: .regular) }
    static func ba_medium(_ size: CGFloat) -> UIFont { .systemFont(ofSize: size, weight: .medium) }
    static func ba_semibold(_ size: CGFloat) -> UIFont { .systemFont(ofSize: size, weight: .semibold) }
    static func ba_bold(_ size: CGFloat) -> UIFont { .systemFont(ofSize: size, weight: .bold) }
    static func ba_mono(_ size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        .monospacedSystemFont(ofSize: size, weight: weight)
    }

    // MARK: - Dynamic Type 支持

    /// 包一层 `UIFontMetrics`，让自定义大小也能跟随系统辅助功能放大
    static func ba_scaled(_ size: CGFloat,
                          weight: UIFont.Weight = .regular,
                          textStyle: UIFont.TextStyle = .body) -> UIFont {
        let font = UIFont.systemFont(ofSize: size, weight: weight)
        return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: font)
    }

    // MARK: - 自定义字体加载

    /// 运行时从 Bundle 注册 ttf / otf 字体文件。
    /// 注册成功后可通过 `UIFont(name: psName, size:)` 使用。
    @discardableResult
    static func ba_registerFont(named name: String,
                                ext: String = "ttf",
                                bundle: Bundle = .main) -> Bool {
        guard let url = bundle.url(forResource: name, withExtension: ext),
              let data = try? Data(contentsOf: url),
              let provider = CGDataProvider(data: data as CFData),
              let cgFont = CGFont(provider) else {
            return false
        }
        var error: Unmanaged<CFError>?
        return CTFontManagerRegisterGraphicsFont(cgFont, &error)
    }
}
#endif
