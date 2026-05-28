//
//  BAProgressHUD.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/26.
//

#if canImport(UIKit)
import UIKit
import SnapKit

/// Display style for `BAProgressHUD`.
public enum BAProgressHUDStyle {
    /// Shows an activity indicator and blocks touches inside the HUD overlay.
    case loading
    /// Shows a success icon and dismisses automatically.
    case success
    /// Shows an error icon and dismisses automatically.
    case error
    /// Shows an informational icon and dismisses automatically.
    case info
}

/// Lightweight global progress HUD similar to SVProgressHUD.
///
/// `BAProgressHUD` can be shown in a custom container or, when no container is provided,
/// in the current key window. All public methods dispatch to the main queue internally.
public enum BAProgressHUD {

    /// Shows a loading HUD that stays visible until `dismiss(from:)` is called.
    ///
    /// - Parameters:
    ///   - message: Optional text displayed below the spinner.
    ///   - container: Optional host view. Defaults to the key window.
    public static func show(_ message: String? = nil, in container: UIView? = nil) {
        show(style: .loading, message: message, in: container, autoDismissAfter: nil)
    }

    /// Shows a success HUD and dismisses it automatically after a short delay.
    ///
    /// - Parameters:
    ///   - message: Optional text displayed below the success icon.
    ///   - container: Optional host view. Defaults to the key window.
    public static func showSuccess(_ message: String? = nil, in container: UIView? = nil) {
        show(style: .success, message: message, in: container, autoDismissAfter: 1.4)
    }

    /// Shows an error HUD and dismisses it automatically after a short delay.
    ///
    /// - Parameters:
    ///   - message: Optional text displayed below the error icon.
    ///   - container: Optional host view. Defaults to the key window.
    public static func showError(_ message: String? = nil, in container: UIView? = nil) {
        show(style: .error, message: message, in: container, autoDismissAfter: 1.6)
    }

    /// Shows an informational HUD and dismisses it automatically after a short delay.
    ///
    /// - Parameters:
    ///   - message: Optional text displayed below the info icon.
    ///   - container: Optional host view. Defaults to the key window.
    public static func showInfo(_ message: String? = nil, in container: UIView? = nil) {
        show(style: .info, message: message, in: container, autoDismissAfter: 1.4)
    }

    /// Dismisses all progress HUDs attached to the specified container or key window.
    ///
    /// - Parameter container: Optional host view. Pass the same view used when showing a local HUD.
    public static func dismiss(from container: UIView? = nil) {
        DispatchQueue.main.async {
            guard let host = container ?? keyWindow() else { return }
            host.subviews.compactMap { $0 as? BAProgressHUDView }.forEach { hud in
                UIView.animate(withDuration: 0.18, animations: {
                    hud.alpha = 0
                    hud.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
                }, completion: { _ in hud.removeFromSuperview() })
            }
        }
    }

    private static func show(style: BAProgressHUDStyle,
                             message: String?,
                             in container: UIView?,
                             autoDismissAfter delay: TimeInterval?) {
        DispatchQueue.main.async {
            guard let host = container ?? keyWindow() else { return }
            host.subviews.compactMap { $0 as? BAProgressHUDView }.forEach { $0.removeFromSuperview() }
            let hud = BAProgressHUDView(style: style, message: message)
            host.addSubview(hud)
            hud.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            hud.alpha = 0
            hud.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
            UIView.animate(withDuration: 0.18) {
                hud.alpha = 1
                hud.transform = .identity
            }
            if let delay {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    guard hud.superview != nil else { return }
                    dismiss(from: host)
                }
            }
        }
    }

    private static func keyWindow() -> UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })
    }
}

private final class BAProgressHUDView: UIView {

    private let card = UIView()
    private let indicator = UIActivityIndicatorView(style: .large)
    private let iconLabel = UILabel()
    private let messageLabel = UILabel()

    init(style: BAProgressHUDStyle, message: String?) {
        super.init(frame: .zero)
        backgroundColor = .clear
        isUserInteractionEnabled = style == .loading

        card.backgroundColor = UIColor(white: 0.08, alpha: 0.88)
        card.layer.cornerRadius = 18
        card.layer.cornerCurve = .continuous
        addSubview(card)

        indicator.color = .white
        iconLabel.font = .systemFont(ofSize: 34, weight: .bold)
        iconLabel.textColor = .white
        iconLabel.textAlignment = .center

        messageLabel.text = message
        messageLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        messageLabel.textColor = .white
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 2

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        card.addSubview(stack)

        switch style {
        case .loading:
            indicator.startAnimating()
            stack.addArrangedSubview(indicator)
        case .success:
            iconLabel.text = "✓"
            stack.addArrangedSubview(iconLabel)
        case .error:
            iconLabel.text = "×"
            stack.addArrangedSubview(iconLabel)
        case .info:
            iconLabel.text = "i"
            stack.addArrangedSubview(iconLabel)
        }
        if let message, !message.isEmpty {
            stack.addArrangedSubview(messageLabel)
        }

        card.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.greaterThanOrEqualTo(118)
            make.height.greaterThanOrEqualTo(108)
            make.left.greaterThanOrEqualToSuperview().offset(48)
            make.right.lessThanOrEqualToSuperview().offset(-48)
        }
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(22)
        }
        iconLabel.snp.makeConstraints { make in
            make.size.equalTo(38)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
#endif
