//
//  BALoadingHUD.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

#if canImport(UIKit)
import UIKit

/// 全屏阻塞型 Loading。直接 `BALoadingHUD.ba_show(in: view)` 即可。
public enum BALoadingHUD {

    public static func ba_show(in container: UIView? = nil,
                               message: String? = nil) {
        DispatchQueue.main.async {
            let host = container ?? keyWindow()
            guard let host = host else { return }
            // 复用同一 host 上已有的 hud
            if let existing = host.subviews.first(where: { $0 is BALoadingHUDView }) as? BALoadingHUDView {
                existing.updateMessage(message)
                return
            }
            let hud = BALoadingHUDView(message: message)
            hud.translatesAutoresizingMaskIntoConstraints = false
            host.addSubview(hud)
            NSLayoutConstraint.activate([
                hud.topAnchor.constraint(equalTo: host.topAnchor),
                hud.bottomAnchor.constraint(equalTo: host.bottomAnchor),
                hud.leadingAnchor.constraint(equalTo: host.leadingAnchor),
                hud.trailingAnchor.constraint(equalTo: host.trailingAnchor)
            ])
            hud.alpha = 0
            UIView.animate(withDuration: 0.18) { hud.alpha = 1 }
        }
    }

    public static func ba_hide(from container: UIView? = nil) {
        DispatchQueue.main.async {
            let host = container ?? keyWindow()
            guard let host = host,
                  let hud = host.subviews.first(where: { $0 is BALoadingHUDView }) else { return }
            UIView.animate(withDuration: 0.18, animations: {
                hud.alpha = 0
            }, completion: { _ in hud.removeFromSuperview() })
        }
    }

    private static func keyWindow() -> UIWindow? {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first(where: { $0.isKeyWindow })
        }
        return UIApplication.shared.windows.first { $0.isKeyWindow }
    }
}

final class BALoadingHUDView: UIView {

    private let dimmer = UIView()
    private let card = UIView()
    private let indicator = UIActivityIndicatorView(style: .large)
    private let label = UILabel()

    init(message: String?) {
        super.init(frame: .zero)
        backgroundColor = .clear

        dimmer.backgroundColor = UIColor(white: 0, alpha: 0.18)
        dimmer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dimmer)

        card.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(white: 0.15, alpha: 1) : .white
        }
        card.layer.cornerRadius = 16
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.12
        card.layer.shadowRadius = 16
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        card.translatesAutoresizingMaskIntoConstraints = false
        addSubview(card)

        indicator.color = .secondaryLabel
        indicator.startAnimating()
        indicator.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(indicator)

        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.text = message
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(label)

        NSLayoutConstraint.activate([
            dimmer.topAnchor.constraint(equalTo: topAnchor),
            dimmer.bottomAnchor.constraint(equalTo: bottomAnchor),
            dimmer.leadingAnchor.constraint(equalTo: leadingAnchor),
            dimmer.trailingAnchor.constraint(equalTo: trailingAnchor),

            card.centerXAnchor.constraint(equalTo: centerXAnchor),
            card.centerYAnchor.constraint(equalTo: centerYAnchor),
            card.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),

            indicator.topAnchor.constraint(equalTo: card.topAnchor, constant: 22),
            indicator.centerXAnchor.constraint(equalTo: card.centerXAnchor),

            label.topAnchor.constraint(equalTo: indicator.bottomAnchor, constant: 12),
            label.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            label.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            label.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func updateMessage(_ message: String?) {
        label.text = message
    }
}
#endif
