//
//  BAHomeItemCell.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit

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
            $0.translatesAutoresizingMaskIntoConstraints = false
            card.contentView.addSubview($0)
        }
        iconWrap.addSubview(iconView)
        iconView.translatesAutoresizingMaskIntoConstraints = false
    }

    private func setupLayout() {
        card.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            iconWrap.leadingAnchor.constraint(equalTo: card.contentView.leadingAnchor, constant: 14),
            iconWrap.centerYAnchor.constraint(equalTo: card.contentView.centerYAnchor),
            iconWrap.widthAnchor.constraint(equalToConstant: 46),
            iconWrap.heightAnchor.constraint(equalToConstant: 46),

            iconView.centerXAnchor.constraint(equalTo: iconWrap.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconWrap.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            titleLabel.topAnchor.constraint(equalTo: card.contentView.topAnchor, constant: 18),
            titleLabel.leadingAnchor.constraint(equalTo: iconWrap.trailingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: card.contentView.bottomAnchor, constant: -18),

            chevron.centerYAnchor.constraint(equalTo: card.contentView.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: card.contentView.trailingAnchor, constant: -14),
            chevron.widthAnchor.constraint(equalToConstant: 12),
            chevron.heightAnchor.constraint(equalToConstant: 18)
        ])
    }

    private func setupStyle() {
        card.ba_cardColor = BAAppTheme.card
        card.ba_cornerRadius = BAAppTheme.cornerRadius

        iconWrap.ba_direction = .leadingDiagonal
        iconWrap.layer.cornerRadius = 12
        iconWrap.layer.masksToBounds = true

        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit

        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = BAAppTheme.textPrimary

        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = BAAppTheme.textSecondary
        subtitleLabel.numberOfLines = 2

        chevron.tintColor = BAAppTheme.textSecondary.withAlphaComponent(0.6)
        chevron.contentMode = .scaleAspectFit
    }
}
