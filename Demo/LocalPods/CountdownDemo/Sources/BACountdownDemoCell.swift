//
//  BACountdownDemoCell.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/06/02.
//

import UIKit
import BASwiftKit
import SnapKit
import DemoCommon

/// 限时抢购商品 Cell。
///
/// 左侧商品图标，中间名称 + 价格信息，右侧倒计时 + 抢购按钮。
/// 过期商品整体变灰，"抢购" 文案变为 "已结束"。
public final class BACountdownDemoCell: UITableViewCell {


    static let reuseIdentifier = "BACountdownDemoCell"

    /// 当前绑定的倒计时观察 ID，用于 `prepareForReuse` / `didEndDisplaying` 时取消注册。
    var countdownId: String?

    // MARK: - Subviews

    private let card = BACardView()
    private let iconView = UIImageView()
    private let nameLabel = UILabel()
    private let priceLabel = UILabel()
    private let originalPriceLabel = UILabel()
    private let countdownLabel = UILabel()
    private let actionButton = UIButton(type: .system)
    private let expiredOverlay = UIView()

    // MARK: - Init

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        setupHierarchy()
        setupLayout()
        setupStyle()
    }

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func prepareForReuse() {
        super.prepareForReuse()
        if let id = countdownId {
            BACountdownManager.shared.unregister(id: id)
            countdownId = nil
        }
    }

    // MARK: - Configure

    /// 刷新 Cell 内容并注册倒计时。
    func configure(with product: BACountdownProduct) {
        iconView.image = UIImage(systemName: product.image)
        nameLabel.text = product.name
        priceLabel.text = product.price
        originalPriceLabel.attributedText = NSAttributedString(
            string: product.originalPrice,
            attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue]
        )

        if product.isExpired {
            applyExpiredState()
        } else {
            applyActiveState(product: product)
        }
    }

    // MARK: - Private

    private func applyActiveState(product: BACountdownProduct) {
        contentView.alpha = 1.0
        actionButton.setTitle("抢购", for: .normal)
        actionButton.backgroundColor = BAAppTheme.accent
        actionButton.isEnabled = true
        expiredOverlay.isHidden = true

        // 注册倒计时
        let id = BACountdownManager.shared.register(endDate: product.endDate) { [weak self] status in
            DispatchQueue.main.async {
                self?.updateCountdown(status)
            }
        }
        countdownId = id
    }

    private func applyExpiredState() {
        contentView.alpha = 0.45
        actionButton.setTitle("已结束", for: .normal)
        actionButton.backgroundColor = BAAppTheme.textSecondary
        actionButton.isEnabled = false
        countdownLabel.text = "已结束"
        countdownLabel.textColor = BAAppTheme.textSecondary
    }

    private func updateCountdown(_ status: BACountdownStatus) {
        if status.isExpired {
            applyExpiredState()
            return
        }
        countdownLabel.text = "剩余 \(status.formatted)"
        // 最后 10 秒红色闪烁效果
        if status.remainingSeconds <= 10 {
            countdownLabel.textColor = BAAppTheme.danger
        } else {
            countdownLabel.textColor = .systemOrange
        }
    }

    // MARK: - Layout

    private func setupHierarchy() {
        contentView.addSubview(card)
        card.contentView.addSubview(iconView)
        card.contentView.addSubview(nameLabel)
        card.contentView.addSubview(priceLabel)
        card.contentView.addSubview(originalPriceLabel)
        card.contentView.addSubview(countdownLabel)
        card.contentView.addSubview(actionButton)
        card.contentView.addSubview(expiredOverlay)
    }

    private func setupLayout() {
        card.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(5)
            make.left.right.equalToSuperview().inset(16)
        }

        iconView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.size.equalTo(56)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.left.equalTo(iconView.snp.right).offset(12)
            make.right.equalTo(countdownLabel.snp.left).offset(-8)
        }

        priceLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(6)
            make.left.equalTo(nameLabel)
        }

        originalPriceLabel.snp.makeConstraints { make in
            make.left.equalTo(priceLabel.snp.right).offset(6)
            make.centerY.equalTo(priceLabel)
            make.bottom.equalToSuperview().offset(-14)
        }

        countdownLabel.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-14)
            make.centerY.equalTo(nameLabel).offset(-2)
            make.width.greaterThanOrEqualTo(80)
        }

        actionButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-14)
            make.top.equalTo(countdownLabel.snp.bottom).offset(6)
            make.width.equalTo(68)
            make.height.equalTo(28)
        }

        expiredOverlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupStyle() {
        card.ba_cardColor = BAAppTheme.cardHighlight
        card.ba_cornerRadius = 14

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = BAAppTheme.accent
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)

        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        nameLabel.textColor = BAAppTheme.textPrimary

        priceLabel.font = .systemFont(ofSize: 18, weight: .bold)
        priceLabel.textColor = BAAppTheme.danger

        originalPriceLabel.font = .systemFont(ofSize: 12, weight: .regular)
        originalPriceLabel.textColor = BAAppTheme.textSecondary

        countdownLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
        countdownLabel.textColor = .systemOrange
        countdownLabel.textAlignment = .right

        actionButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .bold)
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.layer.cornerRadius = 14
        actionButton.layer.masksToBounds = true

        expiredOverlay.backgroundColor = .clear
        expiredOverlay.isHidden = true
    }
}
