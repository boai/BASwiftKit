//
//  BAColorDemoViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit
import SnapKit

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
        scroll.alwaysBounceVertical = true
        view.addSubview(scroll)

        content.axis = .vertical
        content.spacing = 24
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

        content.addArrangedSubview(makeSectionTitle("UIColor(ba_hex:) 调色板"))
        paletteStack.axis = .vertical
        paletteStack.spacing = 14
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
        randomCard.ba_cardColor = BAAppTheme.cardHighlight
        randomCard.ba_cornerRadius = BAAppTheme.cornerRadius

        randomPreview.layer.cornerRadius = 18
        randomPreview.layer.cornerCurve = .continuous
        randomPreview.layer.masksToBounds = true

        let button = UIButton.ba_make(title: "Roll 一个新颜色",
                                      titleColor: .white,
                                      backgroundColor: BAAppTheme.accent,
                                      cornerRadius: BAAppTheme.smallCornerRadius)
        button.ba_onTap { [weak self] _ in self?.viewModel.roll() }

        randomCard.contentView.addSubview(randomPreview)
        randomCard.contentView.addSubview(randomHexLabel)
        randomCard.contentView.addSubview(button)

        randomCard.snp.makeConstraints { make in
            make.height.equalTo(220)
        }
        randomPreview.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(100)
        }
        randomHexLabel.snp.makeConstraints { make in
            make.top.equalTo(randomPreview.snp.bottom).offset(10)
            make.left.right.equalToSuperview().inset(16)
        }
        button.snp.makeConstraints { make in
            make.top.equalTo(randomHexLabel.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(BAAppTheme.controlHeight)
        }
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
        card.ba_cardColor = BAAppTheme.cardHighlight
        card.ba_cornerRadius = BAAppTheme.cornerRadius

        let swatch = UIView()
        swatch.backgroundColor = s.color
        swatch.layer.cornerRadius = 14
        swatch.layer.cornerCurve = .continuous

        let title = UILabel.ba_make(text: s.title,
                                    font: .systemFont(ofSize: 15, weight: .semibold),
                                    color: BAAppTheme.textPrimary)

        let hex = UILabel.ba_make(text: s.hex,
                                  font: .monospacedSystemFont(ofSize: 12, weight: .regular),
                                  color: BAAppTheme.textSecondary)

        card.contentView.ba_addSubviews(swatch, title, hex)
        card.snp.makeConstraints { make in
            make.height.equalTo(118)
        }
        swatch.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(14)
            make.left.equalToSuperview().offset(14)
            make.width.equalTo(52)
        }
        title.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.left.equalTo(swatch.snp.right).offset(12)
            make.right.equalToSuperview().offset(-10)
        }
        hex.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(4)
            make.left.right.equalTo(title)
        }
        return card
    }
}
