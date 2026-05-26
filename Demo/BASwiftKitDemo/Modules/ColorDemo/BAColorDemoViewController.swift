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
    private let content = UIStackView.ba_make(axis: .vertical, spacing: 22)
    private let paletteStack = UIStackView.ba_make(axis: .vertical, spacing: 12)
    private let randomCard = BACardView()
    private let randomPreview = BAGradientView()
    private let randomHexLabel = UILabel.ba_make(font: .monospacedSystemFont(ofSize: 20, weight: .bold),
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
        scroll.addSubview(content)

        scroll.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.bottom.equalToSuperview()
        }
        content.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-28)
            make.left.right.equalToSuperview().inset(16)
            make.width.equalTo(scroll).offset(-32)
        }

        content.addArrangedSubview(makeHero())
        content.addArrangedSubview(makeSectionHeader(title: "精选调色板", subtitle: "UIColor(ba_hex:) + 暗黑模式友好色阶"))
        content.addArrangedSubview(paletteStack)
        content.addArrangedSubview(makeSectionHeader(title: "随机灵感", subtitle: "UIColor.ba_random 快速生成视觉占位色"))
        content.addArrangedSubview(buildRandomSection())
    }

    private func makeHero() -> UIView {
        let hero = BAGradientView()
        hero.ba_colors = BAAppTheme.brandGradient
        hero.ba_direction = .leadingDiagonal
        hero.layer.cornerRadius = 28
        hero.layer.cornerCurve = .continuous
        hero.ba_setShadow(color: BAAppTheme.accent, opacity: 0.22, radius: 24, offset: CGSize(width: 0, height: 12))

        let badge = BABadgeView()
        badge.ba_text = "Color System"
        badge.ba_badgeColor = UIColor.white.withAlphaComponent(0.22)
        badge.ba_textColor = .white
        badge.ba_font = .ba_semibold(12)

        let title = UILabel.ba_make(text: "让颜色更像产品设计稿",
                                    font: .systemFont(ofSize: 24, weight: .heavy),
                                    color: .white,
                                    numberOfLines: 0)
        let subtitle = UILabel.ba_make(text: "Hex、随机色、动态颜色组合成一套轻量 Demo 调色板。",
                                       font: .ba_medium(13),
                                       color: UIColor.white.withAlphaComponent(0.86),
                                       numberOfLines: 0)
        let dots = UIStackView.ba_make(axis: .horizontal, spacing: 8)
        BAAppTheme.brandGradient.forEach { color in
            let dot = UIView()
            dot.backgroundColor = color
            dot.layer.cornerRadius = 8
            dot.layer.borderWidth = 2
            dot.layer.borderColor = UIColor.white.withAlphaComponent(0.55).cgColor
            dot.snp.makeConstraints { make in make.size.equalTo(16) }
            dots.addArrangedSubview(dot)
        }

        hero.ba_addSubviews(badge, title, subtitle, dots)
        hero.snp.makeConstraints { make in make.height.equalTo(170) }
        badge.snp.makeConstraints { make in
            make.top.left.equalToSuperview().offset(20)
        }
        title.snp.makeConstraints { make in
            make.top.equalTo(badge.snp.bottom).offset(16)
            make.left.right.equalToSuperview().inset(20)
        }
        subtitle.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(8)
            make.left.right.equalTo(title)
        }
        dots.snp.makeConstraints { make in
            make.left.equalTo(title)
            make.bottom.equalToSuperview().offset(-20)
        }
        return hero
    }

    private func makeSectionHeader(title: String, subtitle: String) -> UIView {
        let stack = UIStackView.ba_make(axis: .vertical, spacing: 3)
        stack.ba_addArrangedSubviews(
            UILabel.ba_make(text: title, font: .ba_bold(18), color: BAAppTheme.textPrimary),
            UILabel.ba_make(text: subtitle, font: .ba_medium(12), color: BAAppTheme.textSecondary, numberOfLines: 0)
        )
        return stack
    }

    private func buildRandomSection() -> UIView {
        randomCard.ba_cardColor = BAAppTheme.cardHighlight
        randomCard.ba_cornerRadius = 26

        randomPreview.ba_colors = [BAAppTheme.accent, BAAppTheme.accentSecondary]
        randomPreview.ba_direction = .leadingDiagonal
        randomPreview.layer.cornerRadius = 24
        randomPreview.layer.cornerCurve = .continuous
        randomPreview.layer.masksToBounds = true

        let hint = UILabel.ba_make(text: "点击按钮刷新一张随机色彩名片",
                                   font: .ba_medium(12),
                                   color: BAAppTheme.textSecondary,
                                   alignment: .center)
        let button = UIButton.ba_make(title: "Roll 新颜色",
                                      titleColor: .white,
                                      backgroundColor: BAAppTheme.accent,
                                      font: .ba_semibold(15),
                                      cornerRadius: BAAppTheme.smallCornerRadius)
        button.ba_onTap { [weak self] _ in self?.viewModel.roll() }

        randomCard.contentView.ba_addSubviews(randomPreview, randomHexLabel, hint, button)
        randomCard.snp.makeConstraints { make in make.height.equalTo(292) }
        randomPreview.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview().inset(16)
            make.height.equalTo(138)
        }
        randomHexLabel.snp.makeConstraints { make in
            make.top.equalTo(randomPreview.snp.bottom).offset(14)
            make.left.right.equalToSuperview().inset(16)
        }
        hint.snp.makeConstraints { make in
            make.top.equalTo(randomHexLabel.snp.bottom).offset(4)
            make.left.right.equalToSuperview().inset(16)
        }
        button.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview().inset(16)
            make.height.equalTo(BAAppTheme.controlHeight)
        }
        return randomCard
    }

    private func bindViewModel() {
        viewModel.swatches.bind { [weak self] swatches in
            self?.renderPalette(swatches)
        }
        viewModel.randomColor.bind { [weak self] color in
            self?.randomPreview.ba_colors = [color.withAlphaComponent(0.72), color]
            self?.randomHexLabel.text = color.ba_hexString
        }
    }

    private func renderPalette(_ swatches: [BAColorSwatch]) {
        paletteStack.ba_removeAllArrangedSubviews()
        for row in swatches.ba_chunked(into: 2) {
            let rowStack = UIStackView.ba_make(axis: .horizontal, spacing: 12, distribution: .fillEqually)
            row.forEach { rowStack.addArrangedSubview(makeSwatchCell($0)) }
            if row.count == 1 {
                rowStack.addArrangedSubview(UIView())
            }
            paletteStack.addArrangedSubview(rowStack)
        }
    }

    private func makeSwatchCell(_ swatchModel: BAColorSwatch) -> UIView {
        let card = BACardView()
        card.ba_cardColor = BAAppTheme.cardHighlight
        card.ba_cornerRadius = 20

        let swatch = BAGradientView()
        swatch.ba_colors = [swatchModel.color.withAlphaComponent(0.72), swatchModel.color]
        swatch.ba_direction = .leadingDiagonal
        swatch.layer.cornerRadius = 18
        swatch.layer.cornerCurve = .continuous
        swatch.layer.masksToBounds = true

        let title = UILabel.ba_make(text: swatchModel.title,
                                    font: .ba_bold(15),
                                    color: BAAppTheme.textPrimary)
        let hex = UILabel.ba_make(text: swatchModel.hex,
                                  font: .monospacedSystemFont(ofSize: 12, weight: .medium),
                                  color: BAAppTheme.textSecondary)
        let chip = BABadgeView()
        chip.ba_text = "HEX"
        chip.ba_badgeColor = swatchModel.color.withAlphaComponent(0.16)
        chip.ba_textColor = swatchModel.color
        chip.ba_font = .ba_semibold(10)

        card.contentView.ba_addSubviews(swatch, title, hex, chip)
        card.snp.makeConstraints { make in make.height.equalTo(154) }
        swatch.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview().inset(12)
            make.height.equalTo(70)
        }
        title.snp.makeConstraints { make in
            make.top.equalTo(swatch.snp.bottom).offset(12)
            make.left.equalToSuperview().offset(12)
            make.right.equalToSuperview().offset(-12)
        }
        hex.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(4)
            make.left.equalTo(title)
        }
        chip.snp.makeConstraints { make in
            make.centerY.equalTo(hex)
            make.right.equalToSuperview().offset(-12)
        }
        return card
    }
}
