//
//  BAThemeBinding.swift
//  BASwiftKit
//
//  Created by boai on 2026/06/30.
//

#if canImport(UIKit)
import UIKit
import ObjectiveC.runtime

// MARK: - Theme Binder (Internal)

/// 主题绑定器（内部类型）。
///
/// 以「关联对象」形式被宿主视图持有，集中保存该视图的一组主题应用闭包，并监听
/// ``BAThemeManager/didChangeNotification`` 在主题切换时自动重跑这些闭包。
///
/// ## 无循环引用设计
///
/// - 绑定器对宿主视图持 `weak`；
/// - 保存的闭包以「参数」形式接收宿主视图（`(UIView, BAThemePalette) -> Void`），
///   因此闭包本身**不捕获视图**；
/// - 视图释放时，关联的绑定器随之释放，`deinit` 注销通知监听。
///
/// 由此形成 `视图 →(关联,retain) 绑定器 →(持有) 闭包 →(参数,不捕获) 视图` 的安全链路。
final class BAThemeBinder: NSObject {

    /// 宿主视图（弱引用）。
    private weak var owner: UIView?

    /// 主题应用闭包集合。视图与色板均以参数传入，闭包不捕获视图。
    private var applies: [(UIView, BAThemePalette) -> Void] = []

    init(owner: UIView) {
        self.owner = owner
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(themeDidChange),
            name: BAThemeManager.didChangeNotification,
            object: nil
        )
    }

    /// 追加一个主题应用闭包，并立即以当前色板执行一次。
    func addApply(_ apply: @escaping (UIView, BAThemePalette) -> Void) {
        applies.append(apply)
        if let owner = owner {
            apply(owner, BAThemeManager.shared.palette)
        }
    }

    @objc private func themeDidChange() {
        // 防御性兜底：UI 更新必须在主线程。BAThemeManager 默认在主线程发通知，
        // 但即便有其他路径在后台 post，这里也切回主线程，避免后台动 UI。
        if Thread.isMainThread {
            reapply()
        } else {
            DispatchQueue.main.async { [weak self] in self?.reapply() }
        }
    }

    private func reapply() {
        guard let owner = owner else { return }
        let palette = BAThemeManager.shared.palette
        applies.forEach { $0(owner, palette) }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UIView Theme Binding

private enum BAThemeAssociatedKeys {
    static var binder: UInt8 = 0
}

public extension UIView {

    /// 主题绑定 —— 自定义换肤的核心接入点。
    ///
    /// 传入的闭包会在**调用时立即执行一次**（以当前色板），并在**每次主题切换后自动重新执行**，
    /// 从而让视图始终与当前主题一致。
    ///
    /// 闭包通过参数拿到「自身」与「当前色板」，因此**无需写 `[weak self]`**，也不会产生循环引用：
    ///
    /// ```swift
    /// cardView.ba_applyTheme { view, palette in
    ///     view.backgroundColor = palette.elevatedBackground
    ///     view.layer.borderColor = palette.border.cgColor
    /// }
    /// ```
    ///
    /// - Parameter apply: 主题应用闭包，参数为 `(自身, 当前色板)`。
    /// - Note: 闭包首参的具体类型由**调用点的静态类型**决定（如以 `UILabel` 类型的变量调用则为 `UILabel`）。
    ///   绝大多数情况调用方就是具体子类，无需关心；若通过 `UIView` 静态类型的变量调用，参数即为 `UIView`。
    func ba_applyTheme(_ apply: @escaping (Self, BAThemePalette) -> Void) {
        ba_themeBinder().addApply { view, palette in
            guard let typed = view as? Self else { return }
            apply(typed, palette)
        }
    }

    /// 绑定背景色到色板的某个语义槽，主题切换时自动更新。
    ///
    /// ```swift
    /// containerView.ba_themeBackground(\.background)
    /// cardView.ba_themeBackground(\.elevatedBackground)
    /// ```
    func ba_themeBackground(_ keyPath: KeyPath<BAThemePalette, UIColor>) {
        ba_applyTheme { view, palette in
            view.backgroundColor = palette[keyPath: keyPath]
        }
    }

    /// 绑定 `tintColor` 到色板的某个语义槽，主题切换时自动更新。
    func ba_themeTintColor(_ keyPath: KeyPath<BAThemePalette, UIColor>) {
        ba_applyTheme { view, palette in
            view.tintColor = palette[keyPath: keyPath]
        }
    }

    /// 获取（必要时创建）当前视图的主题绑定器。
    private func ba_themeBinder() -> BAThemeBinder {
        if let existing = objc_getAssociatedObject(self, &BAThemeAssociatedKeys.binder) as? BAThemeBinder {
            return existing
        }
        let binder = BAThemeBinder(owner: self)
        objc_setAssociatedObject(self, &BAThemeAssociatedKeys.binder, binder, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return binder
    }
}

// MARK: - UILabel Theme Binding

public extension UILabel {

    /// 绑定文字颜色到色板的某个语义槽，主题切换时自动更新。
    ///
    /// ```swift
    /// titleLabel.ba_themeTextColor(\.label)
    /// subtitleLabel.ba_themeTextColor(\.secondaryLabel)
    /// ```
    func ba_themeTextColor(_ keyPath: KeyPath<BAThemePalette, UIColor>) {
        ba_applyTheme { label, palette in
            label.textColor = palette[keyPath: keyPath]
        }
    }
}

// MARK: - UIButton Theme Binding

public extension UIButton {

    /// 绑定指定状态下的标题颜色到色板的某个语义槽，主题切换时自动更新。
    func ba_themeTitleColor(_ keyPath: KeyPath<BAThemePalette, UIColor>, for state: UIControl.State = .normal) {
        ba_applyTheme { button, palette in
            button.setTitleColor(palette[keyPath: keyPath], for: state)
        }
    }
}

// MARK: - Snapshot Color Accessors

/// 当前色板的快照式取色入口（**一次性读取，不随主题切换自动更新**）。
///
/// 适用于绘制（`draw(_:)`）、`CALayer` 等无法用绑定自动刷新、或确实只需读取一次的场景。
/// 需要自动换肤时请使用 ``UIView/ba_applyTheme(_:)`` 等绑定 API。
public enum BAThemeColor {

    /// 当前生效色板。
    public static var palette: BAThemePalette { BAThemeManager.shared.palette }

    public static var primary: UIColor { palette.primary }
    public static var accent: UIColor { palette.accent }
    public static var background: UIColor { palette.background }
    public static var secondaryBackground: UIColor { palette.secondaryBackground }
    public static var elevatedBackground: UIColor { palette.elevatedBackground }
    public static var label: UIColor { palette.label }
    public static var secondaryLabel: UIColor { palette.secondaryLabel }
    public static var separator: UIColor { palette.separator }
    public static var success: UIColor { palette.success }
    public static var warning: UIColor { palette.warning }
    public static var error: UIColor { palette.error }
}
#endif
