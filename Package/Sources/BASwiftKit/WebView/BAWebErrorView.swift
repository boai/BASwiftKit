//
//  BAWebErrorView.swift
//  BASwiftKit
//
//  Created by boai on 2026/06/30.
//

#if canImport(UIKit)
import UIKit

/// WebView 加载失败错误页。
///
/// 自包含实现：**仅依赖 UIKit**，不引用 BASwiftKit 其它模块（如 UIComponents 的 BAEmptyView）
/// 或任何三方库（不使用 SnapKit，纯原生约束），以便 WebView 组件后续整体拆分为独立 Pod。
///
/// 提供图标 + 标题 + 描述 + 重试按钮的竖向居中布局，点击重试回调 `onRetry`。
final class BAWebErrorView: UIView {

    /// 重试按钮点击回调。
    var onRetry: (() -> Void)?

    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let retryButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    /// 配置错误页文案与图标。
    func configure(image: UIImage?, title: String, message: String, retryTitle: String) {
        imageView.image = image
        titleLabel.text = title
        messageLabel.text = message
        retryButton.setTitle(retryTitle, for: .normal)
        retryButton.isHidden = retryTitle.isEmpty
    }

    private func setup() {
        backgroundColor = .systemBackground

        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .tertiaryLabel
        imageView.setContentHuggingPriority(.required, for: .vertical)

        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        messageLabel.font = .systemFont(ofSize: 14, weight: .regular)
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        retryButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)

        // 竖向居中堆叠，纯原生约束（不依赖 SnapKit）。
        let stack = UIStackView(arrangedSubviews: [imageView, titleLabel, messageLabel, retryButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -32),
            imageView.widthAnchor.constraint(equalToConstant: 64),
            imageView.heightAnchor.constraint(equalToConstant: 64)
        ])
    }

    @objc private func retryTapped() {
        onRetry?()
    }
}
#endif
