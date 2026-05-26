//
//  BAEmptyView.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/26.
//

#if canImport(UIKit)
import UIKit
import SnapKit

/// Configuration object for `BAEmptyView` content and layout.
///
/// All fields are mutable so one configuration can be copied, adjusted, and re-applied.
/// Any optional content (`image`, `title`, `message`, `buttonTitle`) can be omitted to hide
/// that corresponding subview.
public struct BAEmptyViewConfiguration {
    /// Optional image displayed above the text content.
    public var image: UIImage?
    /// Optional main title. Empty or `nil` titles are hidden.
    public var title: String?
    /// Optional detail message. Empty or `nil` messages are hidden.
    public var message: String?
    /// Optional action button title. Empty or `nil` titles hide the button.
    public var buttonTitle: String?
    /// Fixed display size for `image`.
    public var imageSize: CGSize
    /// Vertical spacing between visible arranged subviews.
    public var verticalSpacing: CGFloat
    /// Minimum distance between the content stack and the host view edges.
    public var contentInsets: UIEdgeInsets
    /// Font used by the title label.
    public var titleFont: UIFont
    /// Font used by the message label.
    public var messageFont: UIFont
    /// Font used by the action button.
    public var buttonFont: UIFont
    /// Text color used by the title label.
    public var titleColor: UIColor
    /// Text color used by the message label.
    public var messageColor: UIColor
    /// Title color used by the action button.
    public var buttonTitleColor: UIColor
    /// Background color used by the action button.
    public var buttonBackgroundColor: UIColor
    /// Fixed height used by the action button.
    public var buttonHeight: CGFloat
    /// Corner radius used by the action button.
    public var buttonCornerRadius: CGFloat

    /// Creates an empty-state configuration.
    ///
    /// - Parameters:
    ///   - image: Optional image shown at the top.
    ///   - title: Optional main title.
    ///   - message: Optional detail message.
    ///   - buttonTitle: Optional action button title.
    ///   - imageSize: Display size for the image view.
    ///   - verticalSpacing: Spacing between visible image, labels, and button.
    ///   - contentInsets: Minimum insets from the host view edges.
    ///   - titleFont: Font for the title label.
    ///   - messageFont: Font for the message label.
    ///   - buttonFont: Font for the action button.
    ///   - titleColor: Color for the title label.
    ///   - messageColor: Color for the message label.
    ///   - buttonTitleColor: Title color for the action button.
    ///   - buttonBackgroundColor: Background color for the action button.
    ///   - buttonHeight: Fixed height for the action button.
    ///   - buttonCornerRadius: Corner radius for the action button.
    public init(image: UIImage? = nil,
                title: String? = nil,
                message: String? = nil,
                buttonTitle: String? = nil,
                imageSize: CGSize = CGSize(width: 96, height: 96),
                verticalSpacing: CGFloat = 12,
                contentInsets: UIEdgeInsets = UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24),
                titleFont: UIFont = .systemFont(ofSize: 18, weight: .semibold),
                messageFont: UIFont = .systemFont(ofSize: 14, weight: .regular),
                buttonFont: UIFont = .systemFont(ofSize: 15, weight: .semibold),
                titleColor: UIColor = .label,
                messageColor: UIColor = .secondaryLabel,
                buttonTitleColor: UIColor = .white,
                buttonBackgroundColor: UIColor = .systemBlue,
                buttonHeight: CGFloat = 46,
                buttonCornerRadius: CGFloat = 12) {
        self.image = image
        self.title = title
        self.message = message
        self.buttonTitle = buttonTitle
        self.imageSize = imageSize
        self.verticalSpacing = verticalSpacing
        self.contentInsets = contentInsets
        self.titleFont = titleFont
        self.messageFont = messageFont
        self.buttonFont = buttonFont
        self.titleColor = titleColor
        self.messageColor = messageColor
        self.buttonTitleColor = buttonTitleColor
        self.buttonBackgroundColor = buttonBackgroundColor
        self.buttonHeight = buttonHeight
        self.buttonCornerRadius = buttonCornerRadius
    }
}

/// Reusable empty-state view with optional image, title, message, and action button.
///
/// Add it directly as a view, or use `UIView.ba_showEmptyView(_:onButtonTap:)` to attach it
/// full-screen to any container. The view hides optional subviews automatically when their
/// corresponding configuration value is `nil` or empty.
public final class BAEmptyView: UIView {

    /// Callback invoked when the optional action button is tapped.
    public var onButtonTap: (() -> Void)?

    private let stack = UIStackView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    private let actionButton = UIButton(type: .system)
    private var configuration: BAEmptyViewConfiguration

    /// Creates an empty-state view with the supplied configuration.
    ///
    /// - Parameter configuration: Initial content, style, and spacing configuration.
    public init(configuration: BAEmptyViewConfiguration = BAEmptyViewConfiguration()) {
        self.configuration = configuration
        super.init(frame: .zero)
        setupViews()
        apply(configuration)
    }

    required init?(coder: NSCoder) {
        self.configuration = BAEmptyViewConfiguration()
        super.init(coder: coder)
        setupViews()
        apply(configuration)
    }

    /// Applies new content and layout values to the existing empty view.
    ///
    /// Call this method when the empty-state message, button, colors, or spacing need to
    /// change without removing and recreating the view.
    ///
    /// - Parameter configuration: New configuration to render.
    public func apply(_ configuration: BAEmptyViewConfiguration) {
        self.configuration = configuration

        stack.spacing = configuration.verticalSpacing

        imageView.image = configuration.image
        imageView.isHidden = configuration.image == nil
        imageView.snp.updateConstraints { make in
            make.size.equalTo(configuration.imageSize)
        }

        titleLabel.text = configuration.title
        titleLabel.font = configuration.titleFont
        titleLabel.textColor = configuration.titleColor
        titleLabel.isHidden = configuration.title?.isEmpty ?? true

        messageLabel.text = configuration.message
        messageLabel.font = configuration.messageFont
        messageLabel.textColor = configuration.messageColor
        messageLabel.isHidden = configuration.message?.isEmpty ?? true

        actionButton.setTitle(configuration.buttonTitle, for: .normal)
        actionButton.setTitleColor(configuration.buttonTitleColor, for: .normal)
        actionButton.titleLabel?.font = configuration.buttonFont
        actionButton.backgroundColor = configuration.buttonBackgroundColor
        actionButton.layer.cornerRadius = configuration.buttonCornerRadius
        actionButton.layer.cornerCurve = .continuous
        actionButton.isHidden = configuration.buttonTitle?.isEmpty ?? true
        actionButton.snp.updateConstraints { make in
            make.height.equalTo(configuration.buttonHeight)
        }

        stack.snp.updateConstraints { make in
            make.top.greaterThanOrEqualToSuperview().offset(configuration.contentInsets.top)
            make.left.greaterThanOrEqualToSuperview().offset(configuration.contentInsets.left)
            make.right.lessThanOrEqualToSuperview().offset(-configuration.contentInsets.right)
            make.bottom.lessThanOrEqualToSuperview().offset(-configuration.contentInsets.bottom)
        }
    }

    private func setupViews() {
        backgroundColor = .clear
        stack.axis = .vertical
        stack.alignment = .center
        stack.distribution = .fill

        imageView.contentMode = .scaleAspectFit

        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        actionButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 22, bottom: 0, right: 22)
        actionButton.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)

        addSubview(stack)
        stack.ba_addArrangedSubviews(imageView, titleLabel, messageLabel, actionButton)

        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview().offset(configuration.contentInsets.top)
            make.left.greaterThanOrEqualToSuperview().offset(configuration.contentInsets.left)
            make.right.lessThanOrEqualToSuperview().offset(-configuration.contentInsets.right)
            make.bottom.lessThanOrEqualToSuperview().offset(-configuration.contentInsets.bottom)
        }
        imageView.snp.makeConstraints { make in
            make.size.equalTo(configuration.imageSize)
        }
        actionButton.snp.makeConstraints { make in
            make.height.equalTo(configuration.buttonHeight)
        }
    }

    @objc private func buttonTapped() {
        onButtonTap?()
    }
}

public extension UIView {

    /// Shows an empty-state view pinned to all edges of the receiver.
    ///
    /// Existing `BAEmptyView` instances in the receiver are removed first, so repeated calls
    /// replace the previous empty state instead of stacking multiple overlays.
    ///
    /// - Parameters:
    ///   - configuration: Content, style, and spacing configuration for the empty view.
    ///   - onButtonTap: Optional callback for the empty-state action button.
    func ba_showEmptyView(_ configuration: BAEmptyViewConfiguration,
                          onButtonTap: (() -> Void)? = nil) {
        ba_hideEmptyView()
        let emptyView = BAEmptyView(configuration: configuration)
        emptyView.onButtonTap = onButtonTap
        addSubview(emptyView)
        emptyView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    /// Removes all `BAEmptyView` instances attached directly to the receiver.
    func ba_hideEmptyView() {
        subviews.filter { $0 is BAEmptyView }.forEach { $0.removeFromSuperview() }
    }
}
#endif
