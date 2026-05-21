//
//  BAColorDemoViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit

final class BAColorDemoViewController: BABaseViewController {

    private let viewModel: BAColorDemoViewModel

    private let scroll = UIScrollView()
    private let content = UIStackView()
    private let paletteStack = UIStackView()
    private let randomCard = BACardView()
    private let randomPreview = UIView()
    private let randomHexLabel = UILabel.ba_make(font: .monospacedSystemFont(ofSize: 18, weight: .semibold),
                                                 color: BAAppTheme.textPrimary,
                                                 alignment: .center)

    init(viewModel: BAColorDemoViewModel) {
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

        content.axis = .vertical
        content.spacing = 24
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

        content.addArrangedSubview(makeSectionTitle("UIColor(ba_hex:) 调色板"))
        paletteStack.axis = .vertical
        paletteStack.spacing = 12
        paletteStack.distribution = .fillEqually
        content.addArrangedSubview(paletteStack)

        content.addArrangedSubview(makeSectionTitle("UIColor.ba_random 随机色"))
        content.addArrangedSubview(buildRandomSection())
    }

    private func makeSectionTitle(_ text: String) -> UILabel {
        UILabel.ba_make(text: text,
                        font: .systemFont(ofSize: 14, weight: .semibold),
                        color: BAAppTheme.textSecondary)
    }

    private func buildRandomSection() -> UIView {
        randomCard.ba_cardColor = BAAppTheme.card
        randomCard.ba_cornerRadius = BAAppTheme.cornerRadius
        randomCard.translatesAutoresizingMaskIntoConstraints = false

        randomPreview.layer.cornerRadius = 12
        randomPreview.layer.masksToBounds = true
        randomPreview.translatesAutoresizingMaskIntoConstraints = false

        let button = UIButton.ba_make(title: "Roll 一个新颜色",
                                      titleColor: .white,
                                      backgroundColor: BAAppTheme.accent,
                                      cornerRadius: 12)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.ba_onTap { [weak self] _ in self?.viewModel.roll() }

        randomCard.contentView.addSubview(randomPreview)
        randomCard.contentView.addSubview(randomHexLabel)
        randomCard.contentView.addSubview(button)
        randomHexLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            randomCard.heightAnchor.constraint(equalToConstant: 220),

            randomPreview.topAnchor.constraint(equalTo: randomCard.contentView.topAnchor, constant: 16),
            randomPreview.leadingAnchor.constraint(equalTo: randomCard.contentView.leadingAnchor, constant: 16),
            randomPreview.trailingAnchor.constraint(equalTo: randomCard.contentView.trailingAnchor, constant: -16),
            randomPreview.heightAnchor.constraint(equalToConstant: 100),

            randomHexLabel.topAnchor.constraint(equalTo: randomPreview.bottomAnchor, constant: 10),
            randomHexLabel.leadingAnchor.constraint(equalTo: randomCard.contentView.leadingAnchor, constant: 16),
            randomHexLabel.trailingAnchor.constraint(equalTo: randomCard.contentView.trailingAnchor, constant: -16),

            button.topAnchor.constraint(equalTo: randomHexLabel.bottomAnchor, constant: 12),
            button.leadingAnchor.constraint(equalTo: randomCard.contentView.leadingAnchor, constant: 16),
            button.trailingAnchor.constraint(equalTo: randomCard.contentView.trailingAnchor, constant: -16),
            button.heightAnchor.constraint(equalToConstant: 44)
        ])
        return randomCard
    }

    private func bindViewModel() {
        viewModel.swatches.bind { [weak self] swatches in
            self?.renderPalette(swatches)
        }
        viewModel.randomColor.bind { [weak self] color in
            self?.randomPreview.backgroundColor = color
            self?.randomHexLabel.text = color.ba_hexString
        }
    }

    private func renderPalette(_ swatches: [BAColorSwatch]) {
        paletteStack.ba_removeAllSubviews()
        for row in swatches.ba_chunked(into: 2) {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 12
            rowStack.distribution = .fillEqually
            row.forEach { rowStack.addArrangedSubview(makeSwatchCell($0)) }
            // 末行单元素时补一个占位避免拉伸
            if row.count == 1 {
                let placeholder = UIView()
                placeholder.backgroundColor = .clear
                rowStack.addArrangedSubview(placeholder)
            }
            paletteStack.addArrangedSubview(rowStack)
        }
    }

    private func makeSwatchCell(_ s: BAColorSwatch) -> UIView {
        let card = BACardView()
        card.ba_cardColor = BAAppTheme.card
        card.ba_cornerRadius = BAAppTheme.cornerRadius

        let swatch = UIView()
        swatch.backgroundColor = s.color
        swatch.layer.cornerRadius = 10
        swatch.translatesAutoresizingMaskIntoConstraints = false

        let title = UILabel.ba_make(text: s.title,
                                    font: .systemFont(ofSize: 15, weight: .semibold),
                                    color: BAAppTheme.textPrimary)
        title.translatesAutoresizingMaskIntoConstraints = false

        let hex = UILabel.ba_make(text: s.hex,
                                  font: .monospacedSystemFont(ofSize: 12, weight: .regular),
                                  color: BAAppTheme.textSecondary)
        hex.translatesAutoresizingMaskIntoConstraints = false

        card.contentView.ba_addSubviews(swatch, title, hex)
        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(equalToConstant: 110),

            swatch.topAnchor.constraint(equalTo: card.contentView.topAnchor, constant: 12),
            swatch.leadingAnchor.constraint(equalTo: card.contentView.leadingAnchor, constant: 12),
            swatch.bottomAnchor.constraint(equalTo: card.contentView.bottomAnchor, constant: -12),
            swatch.widthAnchor.constraint(equalToConstant: 50),

            title.topAnchor.constraint(equalTo: card.contentView.topAnchor, constant: 18),
            title.leadingAnchor.constraint(equalTo: swatch.trailingAnchor, constant: 12),
            title.trailingAnchor.constraint(equalTo: card.contentView.trailingAnchor, constant: -10),

            hex.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 4),
            hex.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            hex.trailingAnchor.constraint(equalTo: title.trailingAnchor)
        ])
        return card
    }
}
