//
//  BAStringDemoViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit
import SnapKit

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
        scroll.alwaysBounceVertical = true
        scroll.keyboardDismissMode = .interactive
        view.addSubview(scroll)

        content.axis = .vertical
        content.spacing = 18
        content.alignment = .fill
        scroll.addSubview(content)

        scroll.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.bottom.equalToSuperview()
        }
        content.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-24)
            make.left.right.equalToSuperview().inset(16)
            make.width.equalTo(scroll).offset(-32)
        }

        // 输入卡
        inputCard.ba_cardColor = BAAppTheme.cardHighlight
        inputCard.ba_cornerRadius = BAAppTheme.cornerRadius

        textField.font = .systemFont(ofSize: 15, weight: .medium)
        textField.textColor = BAAppTheme.textPrimary
        textField.placeholder = "随便输入点什么"
        textField.borderStyle = .none
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.addTarget(self, action: #selector(textChanged(_:)), for: .editingChanged)

        let icon = UIImageView(image: UIImage(systemName: "pencil.tip.crop.circle"))
        icon.tintColor = BAAppTheme.accent
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)

        inputCard.contentView.ba_addSubviews(icon, textField)
        inputCard.snp.makeConstraints { make in
            make.height.equalTo(68)
        }
        icon.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.size.equalTo(26)
        }
        textField.snp.makeConstraints { make in
            make.left.equalTo(icon.snp.right).offset(10)
            make.right.equalToSuperview().offset(-14)
            make.centerY.equalToSuperview()
        }

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
        card.ba_cardColor = BAAppTheme.cardHighlight
        card.ba_cornerRadius = BAAppTheme.smallCornerRadius

        let badge = BABadgeView()
        badge.ba_text = r.title
        badge.ba_badgeColor = BAAppTheme.accent.withAlphaComponent(0.14)
        badge.ba_textColor = BAAppTheme.accent

        let value = UILabel.ba_make(text: r.value,
                                    font: .monospacedSystemFont(ofSize: 13, weight: .regular),
                                    color: BAAppTheme.textPrimary,
                                    numberOfLines: 0)

        card.contentView.ba_addSubviews(badge, value)
        badge.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.left.equalToSuperview().offset(12)
        }
        value.snp.makeConstraints { make in
            make.top.equalTo(badge.snp.bottom).offset(8)
            make.left.right.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().offset(-14)
        }
        return card
    }
}
