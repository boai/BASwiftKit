//
//  BAThemePalette.swift
//  BASwiftKit
//
//  Created by boai on 2026/06/30.
//

#if canImport(UIKit)
import UIKit

// MARK: - Theme Palette

/// 主题语义色板协议。
///
/// 主题系统的核心抽象：以「语义」而非「具体颜色」描述 UI 用色（如 `background`、`label`、
/// `primary`），业务层只引用语义槽，真正的颜色由当前生效的色板决定。切换主题即切换色板。
///
/// ## 低接入成本设计
///
/// 协议的**所有色槽都提供了默认实现**（默认映射到系统语义色，本身即随系统深浅色自适应）。
/// 因此自定义一套品牌主题只需声明 `identifier` 并覆盖关心的几个槽即可，其余自动回落：
///
/// ```swift
/// struct OceanTheme: BAThemePalette {
///     let identifier = "ocean"
///     let userInterfaceStyle: UIUserInterfaceStyle = .light
///     var primary: UIColor    { UIColor(ba_hex: "#0A84FF")! }
///     var background: UIColor { UIColor(ba_hex: "#F2F8FF")! }
///     // 其余色槽走协议默认（系统语义色），无需逐一声明
/// }
///
/// BAThemeManager.shared.apply(.custom(OceanTheme()))
/// ```
///
/// - Note: 内置的深浅色（`.light` / `.dark` / `.system` 模式）直接复用系统语义色 +
///   `overrideUserInterfaceStyle` 驱动，**无需任何 per-view 代码**；自定义品牌主题则通过
///   ``UIView/ba_applyTheme(_:)`` 等绑定在切换时自动重渲染。详见 ``BAThemeManager``。
public protocol BAThemePalette {

    /// 主题唯一标识，用于持久化与按 id 恢复。
    var identifier: String { get }

    /// 该主题对应的系统外观。
    ///
    /// 切换到本主题时，框架会把所有窗口的 `overrideUserInterfaceStyle` 设为该值，
    /// 使系统控件（键盘、Alert、`UIScrollView` 指示条等）与主题保持一致。
    /// 自定义主题通常返回 `.light` 或 `.dark`；内置 `.system` 模式返回 `.unspecified`。
    var userInterfaceStyle: UIUserInterfaceStyle { get }

    // MARK: 品牌色

    /// 主品牌色（按钮、强调、选中态等）。
    var primary: UIColor { get }
    /// 主品牌色的深/浅变体（按下态、渐变等）。
    var primaryVariant: UIColor { get }
    /// 次强调色 / 点缀色。
    var accent: UIColor { get }

    // MARK: 背景层级

    /// 一级背景（页面底色）。
    var background: UIColor { get }
    /// 二级背景（分组、卡片底色）。
    var secondaryBackground: UIColor { get }
    /// 浮层背景（弹窗、菜单等抬升内容）。
    var elevatedBackground: UIColor { get }

    // MARK: 文字

    /// 主要文字。
    var label: UIColor { get }
    /// 次要文字。
    var secondaryLabel: UIColor { get }
    /// 三级 / 占位文字。
    var tertiaryLabel: UIColor { get }

    // MARK: 线条

    /// 分割线。
    var separator: UIColor { get }
    /// 描边 / 边框。
    var border: UIColor { get }

    // MARK: 语义状态色

    /// 成功 / 正向。
    var success: UIColor { get }
    /// 警示。
    var warning: UIColor { get }
    /// 错误 / 危险。
    var error: UIColor { get }
}

// MARK: - Default Implementations

/// 默认色槽实现：全部映射到系统语义色（本身随系统深浅色自适应）。
/// 自定义主题只需覆盖差异化的槽，其余自动回落到此处，最大限度降低接入成本。
public extension BAThemePalette {

    var userInterfaceStyle: UIUserInterfaceStyle { .unspecified }

    var primary: UIColor { .systemBlue }
    var primaryVariant: UIColor { primary }
    var accent: UIColor { .systemIndigo }

    var background: UIColor { .systemBackground }
    var secondaryBackground: UIColor { .secondarySystemBackground }
    var elevatedBackground: UIColor { .tertiarySystemBackground }

    var label: UIColor { .label }
    var secondaryLabel: UIColor { .secondaryLabel }
    var tertiaryLabel: UIColor { .tertiaryLabel }

    var separator: UIColor { .separator }
    var border: UIColor { .separator }

    var success: UIColor { .systemGreen }
    var warning: UIColor { .systemOrange }
    var error: UIColor { .systemRed }
}

// MARK: - Built-in System Palette

/// 内置「系统」色板。
///
/// 全部使用系统语义色，因此天然随系统/窗口的 `userInterfaceStyle` 在深浅色间自适应。
/// 配合 ``BAThemeManager`` 的 `.system` / `.light` / `.dark` 模式（通过
/// `overrideUserInterfaceStyle` 驱动），实现**零 per-view 代码**的暗黑/白天切换。
public struct BASystemPalette: BAThemePalette {

    public let identifier: String
    public let userInterfaceStyle: UIUserInterfaceStyle

    /// - Parameters:
    ///   - identifier: 主题标识，默认 `"system"`。
    ///   - userInterfaceStyle: 对应外观，默认 `.unspecified`（跟随系统）。
    public init(identifier: String = "system", userInterfaceStyle: UIUserInterfaceStyle = .unspecified) {
        self.identifier = identifier
        self.userInterfaceStyle = userInterfaceStyle
    }
}
#endif
