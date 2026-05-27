//
//  BACustomAlertViewController.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/26.
//

#if canImport(UIKit)
import UIKit
import SnapKit

/// A button action displayed by `BACustomAlertViewController`.
public struct BAAlertAction {
    /// Visual style used to distinguish the action's intent.
    public enum Style {
        /// Primary confirm action with highlighted appearance.
        case normal
        /// Neutral cancel action with secondary appearance.
        case cancel
        /// Destructive action for delete or irreversible operations.
        case destructive
    }

    /// Button title shown in the alert.
    public let title: String
    /// Button style used to derive background and title colors.
    public let style: Style
    /// Closure invoked after the alert is dismissed.
    public let handler: (() -> Void)?

    /// Creates an alert action.
    ///
    /// - Parameters:
    ///   - title: Button title shown to users.
    ///   - style: Visual intent of the button. Defaults to `.normal`.
    ///   - handler: Optional callback executed after dismissal.
    public init(title: String, style: Style = .normal, handler: (() -> Void)? = nil) {
        self.title = title
        self.style = style
        self.handler = handler
    }
}

/// Custom modal alert controller with title, message, optional custom content, and configurable actions.
///
/// Use this controller when `UIAlertController` is not flexible enough for custom views such as
/// forms, pickers, or rich preview content. The controller presents over the current screen and
/// keeps its own dimmed backdrop, rounded card, and action button styling.
public final class BACustomAlertViewController: UIViewController {

    private let alertTitle: String?
    private let alertMessage: String?
    private let content: UIView?
    private let actions: [BAAlertAction]
    private let dismissOnBackdropTap: Bool

    private let backdrop = UIControl()
    private let card = UIView()
    private let stack = UIStackView()
    private var actionButtons: [UIButton: BAAlertAction] = [:]

    /// Creates a custom alert controller.
    ///
    /// - Parameters:
    ///   - title: Optional title displayed at the top of the card.
    ///   - message: Optional descriptive text displayed below the title.
    ///   - contentView: Optional custom view inserted between message and actions.
    ///   - actions: Action buttons displayed from top to bottom.
    ///   - dismissOnBackdropTap: Whether tapping outside the card dismisses the alert.
    public init(title: String?,
                message: String?,
                contentView: UIView? = nil,
                actions: [BAAlertAction],
                dismissOnBackdropTap: Bool = true) {
        self.alertTitle = title
        self.alertMessage = message
        self.content = contentView
        self.actions = actions
        self.dismissOnBackdropTap = dismissOnBackdropTap
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    /// 加载视图并构建弹窗 UI。
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupContent()
    }

    private func setupViews() {
        view.backgroundColor = .clear
        backdrop.backgroundColor = UIColor.black.withAlphaComponent(0.34)
        if dismissOnBackdropTap {
            backdrop.addTarget(self, action: #selector(backdropTapped), for: .touchUpInside)
        }

        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 22
        card.layer.cornerCurve = .continuous
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.18
        card.layer.shadowRadius = 28
        card.layer.shadowOffset = CGSize(width: 0, height: 16)

        stack.axis = .vertical
        stack.spacing = 14
        stack.alignment = .fill

        view.addSubview(backdrop)
        view.addSubview(card)
        card.addSubview(stack)

        backdrop.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        card.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(28)
        }
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
        }
    }

    private func setupContent() {
        if let alertTitle {
            let label = UILabel()
            label.text = alertTitle
            label.font = .systemFont(ofSize: 20, weight: .bold)
            label.textColor = .label
            label.textAlignment = .center
            label.numberOfLines = 0
            stack.addArrangedSubview(label)
        }

        if let alertMessage {
            let label = UILabel()
            label.text = alertMessage
            label.font = .systemFont(ofSize: 14, weight: .regular)
            label.textColor = .secondaryLabel
            label.textAlignment = .center
            label.numberOfLines = 0
            stack.addArrangedSubview(label)
        }

        if let content {
            stack.addArrangedSubview(content)
        }

        let buttonStack = UIStackView()
        buttonStack.axis = .vertical
        buttonStack.spacing = 10
        actions.forEach { action in
            let button = UIButton(type: .system)
            button.setTitle(action.title, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
            button.layer.cornerRadius = 12
            button.layer.cornerCurve = .continuous
            button.backgroundColor = backgroundColor(for: action.style)
            button.setTitleColor(titleColor(for: action.style), for: .normal)
            button.snp.makeConstraints { make in make.height.equalTo(46) }
            actionButtons[button] = action
            button.addTarget(self, action: #selector(actionButtonTapped(_:)), for: .touchUpInside)
            buttonStack.addArrangedSubview(button)
        }
        stack.addArrangedSubview(buttonStack)
    }

    private func backgroundColor(for style: BAAlertAction.Style) -> UIColor {
        switch style {
        case .normal: return .systemBlue
        case .cancel: return .tertiarySystemFill
        case .destructive: return .systemRed
        }
    }

    private func titleColor(for style: BAAlertAction.Style) -> UIColor {
        switch style {
        case .normal, .destructive: return .white
        case .cancel: return .label
        }
    }

    @objc private func backdropTapped() {
        dismiss(animated: true)
    }

    @objc private func actionButtonTapped(_ sender: UIButton) {
        guard let action = actionButtons[sender] else { return }
        dismiss(animated: true) { action.handler?() }
    }
}

public extension UIViewController {

    /// Presents a `BACustomAlertViewController` from the current view controller.
    ///
    /// - Parameters:
    ///   - title: Optional title displayed at the top of the alert.
    ///   - message: Optional message displayed below the title.
    ///   - contentView: Optional custom content, such as an input form or picker.
    ///   - actions: Buttons displayed in the alert. Each action dismisses the alert before its handler runs.
    ///   - dismissOnBackdropTap: Whether tapping the dimmed background closes the alert.
    func ba_customAlert(title: String?,
                        message: String?,
                        contentView: UIView? = nil,
                        actions: [BAAlertAction],
                        dismissOnBackdropTap: Bool = true) {
        let alert = BACustomAlertViewController(title: title,
                                                message: message,
                                                contentView: contentView,
                                                actions: actions,
                                                dismissOnBackdropTap: dismissOnBackdropTap)
        present(alert, animated: true)
    }
}
#endif
