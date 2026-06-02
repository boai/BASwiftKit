//
//  BAToast.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

#if canImport(UIKit)
import UIKit
import SnapKit

/// 全局轻提示。直接调用静态方法即可：
/// ```swift
/// BAToast.ba_show("已复制")
/// BAToast.ba_show("出错了", style: .error)
/// ```
public enum BAToast {

    /// Toast 展示样式。
    public enum Style {
        /// 默认深色提示。
        case `default`
        /// 成功提示。
        case success
        /// 错误提示。
        case error
        /// 警告提示。
        case warning

        var background: UIColor {
            switch self {
            case .default:  return UIColor(white: 0, alpha: 0.78)
            case .success:  return UIColor(red: 0.16, green: 0.65, blue: 0.27, alpha: 0.95)
            case .error:    return UIColor(red: 0.85, green: 0.18, blue: 0.18, alpha: 0.95)
            case .warning:  return UIColor(red: 0.95, green: 0.62, blue: 0.04, alpha: 0.95)
            }
        }
    }

    /// 显示一条全局 Toast。
    ///
    /// - Parameters:
    ///   - message: 提示文案。
    ///   - style: 展示样式，默认 `.default`。
    ///   - duration: 停留时长，默认 1.8 秒。
    public static func ba_show(_ message: String,
                               style: Style = .default,
                               duration: TimeInterval = 1.8) {
        DispatchQueue.main.async {
            guard let window = keyWindow() else { return }
            let toast = BAToastView(text: message, style: style)
            window.addSubview(toast)

            toast.snp.makeConstraints { make in
                make.centerX.equalToSuperview()
                make.bottom.equalTo(window.safeAreaLayoutGuide.snp.bottom).offset(-80)
                make.left.greaterThanOrEqualToSuperview().offset(32)
                make.right.lessThanOrEqualToSuperview().offset(-32)
            }

            toast.alpha = 0
            toast.transform = CGAffineTransform(translationX: 0, y: 12)
            UIView.animate(withDuration: 0.22, delay: 0,
                           options: .curveEaseOut) {
                toast.alpha = 1
                toast.transform = .identity
            } completion: { _ in
                UIView.animate(withDuration: 0.25, delay: duration,
                               options: .curveEaseIn) {
                    toast.alpha = 0
                    toast.transform = CGAffineTransform(translationX: 0, y: -8)
                } completion: { _ in
                    toast.removeFromSuperview()
                }
            }
        }
    }

    private static func keyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })
            ?? UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first
    }
}

final class BAToastView: UIView {

    init(text: String, style: BAToast.Style) {
        super.init(frame: .zero)
        backgroundColor = style.background
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.15
        layer.shadowRadius = 10
        layer.shadowOffset = CGSize(width: 0, height: 4)
        // 注意：不要设 masksToBounds/clipsToBounds，否则 shadow 会被裁剪不可见。
        // cornerRadius 本身已能裁剪背景色圆角，子视图（UILabel）由 SnapKit inset 约束保证不溢出。

        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        addSubview(label)

        label.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(12)
            make.left.right.equalToSuperview().inset(18)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
#endif
