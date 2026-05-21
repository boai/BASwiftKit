//
//  BAToast.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

#if canImport(UIKit)
import UIKit

/// 全局轻提示。直接调用静态方法即可：
/// ```swift
/// BAToast.ba_show("已复制")
/// BAToast.ba_show("出错了", style: .error)
/// ```
public enum BAToast {

    public enum Style {
        case `default`, success, error, warning

        var background: UIColor {
            switch self {
            case .default:  return UIColor(white: 0, alpha: 0.78)
            case .success:  return UIColor(red: 0.16, green: 0.65, blue: 0.27, alpha: 0.95)
            case .error:    return UIColor(red: 0.85, green: 0.18, blue: 0.18, alpha: 0.95)
            case .warning:  return UIColor(red: 0.95, green: 0.62, blue: 0.04, alpha: 0.95)
            }
        }
    }

    public static func ba_show(_ message: String,
                               style: Style = .default,
                               duration: TimeInterval = 1.8) {
        DispatchQueue.main.async {
            guard let window = keyWindow() else { return }
            let toast = BAToastView(text: message, style: style)
            toast.translatesAutoresizingMaskIntoConstraints = false
            window.addSubview(toast)

            NSLayoutConstraint.activate([
                toast.centerXAnchor.constraint(equalTo: window.centerXAnchor),
                toast.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.bottomAnchor, constant: -80),
                toast.leadingAnchor.constraint(greaterThanOrEqualTo: window.leadingAnchor, constant: 32),
                toast.trailingAnchor.constraint(lessThanOrEqualTo: window.trailingAnchor, constant: -32)
            ])

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
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first(where: { $0.isKeyWindow })
                ?? UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                    .first
        }
        return UIApplication.shared.windows.first { $0.isKeyWindow } ?? UIApplication.shared.windows.first
    }
}

final class BAToastView: UIView {

    init(text: String, style: BAToast.Style) {
        super.init(frame: .zero)
        backgroundColor = style.background
        layer.cornerRadius = 12
        layer.masksToBounds = true
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.15
        layer.shadowRadius = 10
        layer.shadowOffset = CGSize(width: 0, height: 4)

        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
#endif
