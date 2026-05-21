//
//  BAInfraDemoViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit

final class BAInfraDemoViewController: BABaseViewController {

    private let viewModel: BAInfraDemoViewModel
    private let scroll = UIScrollView()
    private let stack = UIStackView.ba_make(axis: .vertical, spacing: 16)
    private let rowsStack = UIStackView.ba_make(axis: .vertical, spacing: 8)

    init(viewModel: BAInfraDemoViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        bindViewModel()
        viewModel.refresh()
    }

    private func setupLayout() {
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.alwaysBounceVertical = true
        view.addSubview(scroll)
        scroll.addSubview(stack)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            stack.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -24),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -16),
            stack.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -32)
        ])

        stack.ba_addArrangedSubviews(
            sectionTitle("UIView.ba_onTap / ba_onLongPress"),
            makeTapCard(),
            sectionTitle("Bundle / Window / Top VC"),
            rowsStack,
            makeRefreshButton()
        )
    }

    private func sectionTitle(_ text: String) -> UILabel {
        UILabel.ba_make(text: text,
                        font: .ba_semibold(14),
                        color: BAAppTheme.textSecondary)
    }

    private func makeTapCard() -> UIView {
        let card = BACardView()
        card.ba_cardColor = BAAppTheme.card
        card.ba_cornerRadius = BAAppTheme.cornerRadius

        let title = UILabel.ba_make(text: "👇 单击我 · 长按我",
                                    font: .ba_semibold(16),
                                    color: BAAppTheme.textPrimary,
                                    alignment: .center)
        let hint = UILabel.ba_make(text: "Tap → Toast；LongPress → Alert",
                                   font: .ba_regular(13),
                                   color: BAAppTheme.textSecondary,
                                   alignment: .center)
        let s = UIStackView.ba_make(axis: .vertical, spacing: 4, alignment: .center)
        s.ba_addArrangedSubviews(title, hint)
        s.translatesAutoresizingMaskIntoConstraints = false
        card.contentView.addSubview(s)
        NSLayoutConstraint.activate([
            s.topAnchor.constraint(equalTo: card.contentView.topAnchor, constant: 24),
            s.bottomAnchor.constraint(equalTo: card.contentView.bottomAnchor, constant: -24),
            s.leadingAnchor.constraint(equalTo: card.contentView.leadingAnchor, constant: 16),
            s.trailingAnchor.constraint(equalTo: card.contentView.trailingAnchor, constant: -16)
        ])

        card.ba_onTap { _ in
            BAToast.ba_show("ba_onTap 触发", style: .success)
        }
        card.ba_onLongPress { [weak self] _ in
            self?.ba_alert(title: "长按事件",
                           message: "ba_onLongPress 触发，回调发生在 .began 阶段。",
                           confirmTitle: "好的")
        }
        return card
    }

    private func makeRefreshButton() -> UIButton {
        let btn = UIButton.ba_make(title: "刷新 Top VC / Window 信息",
                                   titleColor: .white,
                                   backgroundColor: BAAppTheme.accent,
                                   font: .ba_semibold(15),
                                   cornerRadius: 12)
        btn.heightAnchor.constraint(equalToConstant: 44).isActive = true
        btn.ba_onTap { [weak self] _ in
            self?.viewModel.refresh()
            BAToast.ba_show("已刷新")
        }
        return btn
    }

    private func bindViewModel() {
        viewModel.rows.bind { [weak self] rows in
            self?.renderRows(rows)
        }
    }

    private func renderRows(_ rows: [BAInfraRow]) {
        rowsStack.ba_removeAllArrangedSubviews()
        for r in rows {
            let card = BACardView()
            card.ba_cardColor = BAAppTheme.card
            card.ba_cornerRadius = 12

            let key = UILabel.ba_make(text: r.label,
                                      font: .ba_medium(13),
                                      color: BAAppTheme.textSecondary)
            let val = UILabel.ba_make(text: r.value,
                                      font: .ba_mono(12, weight: .regular),
                                      color: BAAppTheme.textPrimary,
                                      numberOfLines: 0)
            key.translatesAutoresizingMaskIntoConstraints = false
            val.translatesAutoresizingMaskIntoConstraints = false

            card.contentView.ba_addSubviews(key, val)
            NSLayoutConstraint.activate([
                key.topAnchor.constraint(equalTo: card.contentView.topAnchor, constant: 10),
                key.leadingAnchor.constraint(equalTo: card.contentView.leadingAnchor, constant: 12),
                key.trailingAnchor.constraint(equalTo: card.contentView.trailingAnchor, constant: -12),

                val.topAnchor.constraint(equalTo: key.bottomAnchor, constant: 4),
                val.leadingAnchor.constraint(equalTo: key.leadingAnchor),
                val.trailingAnchor.constraint(equalTo: key.trailingAnchor),
                val.bottomAnchor.constraint(equalTo: card.contentView.bottomAnchor, constant: -12)
            ])
            rowsStack.addArrangedSubview(card)
        }
    }
}
