//
//  BAStringDemoViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit

final class BAStringDemoViewController: BABaseViewController {

    private let viewModel: BAStringDemoViewModel

    private let inputCard = BACardView()
    private let textField = UITextField()
    private let resultsStack = UIStackView()
    private let scroll = UIScrollView()
    private let content = UIStackView()

    init(viewModel: BAStringDemoViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        bindViewModel()
        textField.text = viewModel.input.value
        viewModel.recompute()

        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
    }

    @objc private func handleTap() { ba_dismissKeyboard() }

    private func setupLayout() {
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.alwaysBounceVertical = true
        scroll.keyboardDismissMode = .interactive
        view.addSubview(scroll)

        content.axis = .vertical
        content.spacing = 18
        content.alignment = .fill
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            content.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 16),
            content.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -24),
            content.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -16),
            content.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -32)
        ])

        // 输入卡
        inputCard.ba_cardColor = BAAppTheme.card
        inputCard.ba_cornerRadius = BAAppTheme.cornerRadius

        textField.font = .systemFont(ofSize: 15)
        textField.textColor = BAAppTheme.textPrimary
        textField.placeholder = "随便输入点什么"
        textField.borderStyle = .none
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.addTarget(self, action: #selector(textChanged(_:)), for: .editingChanged)

        let icon = UIImageView(image: UIImage(systemName: "pencil.tip.crop.circle"))
        icon.tintColor = BAAppTheme.accent
        icon.translatesAutoresizingMaskIntoConstraints = false

        inputCard.contentView.ba_addSubviews(icon, textField)
        NSLayoutConstraint.activate([
            inputCard.heightAnchor.constraint(equalToConstant: 64),
            icon.leadingAnchor.constraint(equalTo: inputCard.contentView.leadingAnchor, constant: 14),
            icon.centerYAnchor.constraint(equalTo: inputCard.contentView.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 26),
            icon.heightAnchor.constraint(equalToConstant: 26),
            textField.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 10),
            textField.trailingAnchor.constraint(equalTo: inputCard.contentView.trailingAnchor, constant: -14),
            textField.centerYAnchor.constraint(equalTo: inputCard.contentView.centerYAnchor)
        ])

        content.addArrangedSubview(inputCard)

        let header = UILabel.ba_make(text: "解析结果",
                                     font: .systemFont(ofSize: 14, weight: .semibold),
                                     color: BAAppTheme.textSecondary)
        content.addArrangedSubview(header)

        resultsStack.axis = .vertical
        resultsStack.spacing = 10
        content.addArrangedSubview(resultsStack)
    }

    @objc private func textChanged(_ tf: UITextField) {
        viewModel.update(tf.text ?? "")
    }

    private func bindViewModel() {
        viewModel.results.bind { [weak self] rows in
            self?.renderResults(rows)
        }
    }

    private func renderResults(_ rows: [BAStringDemoResult]) {
        resultsStack.ba_removeAllSubviews()
        for r in rows {
            resultsStack.addArrangedSubview(makeResultRow(r))
        }
    }

    private func makeResultRow(_ r: BAStringDemoResult) -> UIView {
        let card = BACardView()
        card.ba_cardColor = BAAppTheme.card
        card.ba_cornerRadius = 12

        let badge = BABadgeView()
        badge.ba_text = r.title
        badge.ba_badgeColor = BAAppTheme.accent.withAlphaComponent(0.14)
        badge.ba_textColor = BAAppTheme.accent
        badge.translatesAutoresizingMaskIntoConstraints = false

        let value = UILabel.ba_make(text: r.value,
                                    font: .monospacedSystemFont(ofSize: 13, weight: .regular),
                                    color: BAAppTheme.textPrimary,
                                    numberOfLines: 0)
        value.translatesAutoresizingMaskIntoConstraints = false

        card.contentView.ba_addSubviews(badge, value)
        NSLayoutConstraint.activate([
            badge.topAnchor.constraint(equalTo: card.contentView.topAnchor, constant: 12),
            badge.leadingAnchor.constraint(equalTo: card.contentView.leadingAnchor, constant: 12),

            value.topAnchor.constraint(equalTo: badge.bottomAnchor, constant: 8),
            value.leadingAnchor.constraint(equalTo: card.contentView.leadingAnchor, constant: 12),
            value.trailingAnchor.constraint(equalTo: card.contentView.trailingAnchor, constant: -12),
            value.bottomAnchor.constraint(equalTo: card.contentView.bottomAnchor, constant: -14)
        ])
        return card
    }
}
