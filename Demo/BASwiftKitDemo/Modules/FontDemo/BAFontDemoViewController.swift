//
//  BAFontDemoViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit

final class BAFontDemoViewController: BABaseViewController {

    private let viewModel: BAFontDemoViewModel

    private let scroll = UIScrollView()
    private let stack = UIStackView.ba_make(axis: .vertical, spacing: 16)

    init(viewModel: BAFontDemoViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        bindViewModel()
        viewModel.loadData()
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
    }

    private func bindViewModel() {
        viewModel.rows.bind { [weak self] rows in
            self?.renderRows(rows)
        }
    }

    private func renderRows(_ rows: [BAFontDemoRow]) {
        stack.ba_removeAllArrangedSubviews()
        for r in rows {
            let card = BACardView()
            card.ba_cardColor = BAAppTheme.card
            card.ba_cornerRadius = 12

            let api = UILabel.ba_make(text: r.label,
                                      font: .ba_mono(11, weight: .medium),
                                      color: BAAppTheme.textSecondary)
            api.translatesAutoresizingMaskIntoConstraints = false

            let preview = UILabel.ba_make(text: "永远相信美好的事情即将发生 · The quick brown fox",
                                          font: r.font,
                                          color: BAAppTheme.textPrimary,
                                          numberOfLines: 0)
            preview.translatesAutoresizingMaskIntoConstraints = false

            card.contentView.ba_addSubviews(api, preview)
            NSLayoutConstraint.activate([
                api.topAnchor.constraint(equalTo: card.contentView.topAnchor, constant: 12),
                api.leadingAnchor.constraint(equalTo: card.contentView.leadingAnchor, constant: 14),
                api.trailingAnchor.constraint(equalTo: card.contentView.trailingAnchor, constant: -14),

                preview.topAnchor.constraint(equalTo: api.bottomAnchor, constant: 6),
                preview.leadingAnchor.constraint(equalTo: api.leadingAnchor),
                preview.trailingAnchor.constraint(equalTo: api.trailingAnchor),
                preview.bottomAnchor.constraint(equalTo: card.contentView.bottomAnchor, constant: -14)
            ])
            stack.addArrangedSubview(card)
        }
    }
}
