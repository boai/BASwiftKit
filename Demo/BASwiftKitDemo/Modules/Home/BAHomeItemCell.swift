//
//  BAHomeItemCell.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit
import SnapKit

/// Home 列表中的一张 Demo 卡片
final class BAHomeItemCell: UITableViewCell {

    static let reuseId = "BAHomeItemCell"

    private let card = BACardView()
    private let iconWrap = BAGradientView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none
        setupHierarchy()
        setupLayout()
        setupStyle()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(with item: BADemoItem) {
        titleLabel.text = item.title
        subtitleLabel.text = item.subtitle
        iconView.image = UIImage(systemName: item.iconSystemName)
        iconWrap.ba_colors = item.gradient
    }

    private func setupHierarchy() {
        contentView.addSubview(card)
        [iconWrap, titleLabel, subtitleLabel, chevron].forEach {
            card.contentView.addSubview($0)
        }
        iconWrap.addSubview(iconView)
    }

    private func setupLayout() {
        card.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(7)
            make.left.right.equalToSuperview().inset(16)
        }
        iconWrap.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(50)
        }
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(24)
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(19)
            make.left.equalTo(iconWrap.snp.right).offset(15)
            make.right.equalTo(chevron.snp.left).offset(-8)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.left.right.equalTo(titleLabel)
            make.bottom.equalToSuperview().offset(-18)
        }
        chevron.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-14)
            make.width.equalTo(12)
            make.height.equalTo(18)
        }
    }

    private func setupStyle() {
        card.ba_cardColor = BAAppTheme.cardHighlight
        card.ba_cornerRadius = 20

        iconWrap.ba_direction = .leadingDiagonal
        iconWrap.layer.cornerRadius = 16
        iconWrap.layer.cornerCurve = .continuous
        iconWrap.layer.masksToBounds = true

        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)

        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = BAAppTheme.textPrimary

        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = BAAppTheme.textSecondary
        subtitleLabel.numberOfLines = 2

        chevron.tintColor = BAAppTheme.textSecondary.withAlphaComponent(0.6)
        chevron.contentMode = .scaleAspectFit
    }
}
