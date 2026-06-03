//
//  BASocketMessageCell.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/28.
//

import UIKit
import BASwiftKit
import SnapKit
import DemoCommon

/// Socket Demo 消息气泡 Cell。
///
/// 发送消息右对齐蓝色渐变，接收消息左对齐灰色卡片，附带类型标签和时间戳。
public final class BASocketMessageCell: UITableViewCell {


    static let reuseIdentifier = "BASocketMessageCell"

    private let bubbleView = UIView()
    private let contentLabel = UILabel()
    private let typeLabel = UILabel()
    private let timeLabel = UILabel()

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        bubbleView.layer.cornerRadius = 16
        bubbleView.layer.masksToBounds = true
        contentView.addSubview(bubbleView)

        contentLabel.numberOfLines = 0
        bubbleView.addSubview(contentLabel)

        typeLabel.font = .systemFont(ofSize: 10, weight: .semibold)
        contentView.addSubview(typeLabel)

        timeLabel.font = .systemFont(ofSize: 11, weight: .regular)
        timeLabel.textColor = BAAppTheme.textSecondary
        contentView.addSubview(timeLabel)

        contentLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(12)
        }
    }

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(content: String, type: String, isOutgoing: Bool, timestamp: String) {
        contentLabel.text = content
        typeLabel.text = type
        timeLabel.text = timestamp

        if isOutgoing {
            bubbleView.backgroundColor = BAAppTheme.accent
            contentLabel.textColor = .white
            typeLabel.textColor = BAAppTheme.accent

            bubbleView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(4)
                make.bottom.equalToSuperview().offset(-20)
                make.right.equalToSuperview().offset(-16)
                make.left.greaterThanOrEqualToSuperview().offset(60)
            }

            typeLabel.snp.remakeConstraints { make in
                make.right.equalTo(bubbleView.snp.left).offset(-6)
                make.centerY.equalTo(bubbleView)
            }

            timeLabel.snp.remakeConstraints { make in
                make.right.equalTo(bubbleView)
                make.top.equalTo(bubbleView.snp.bottom).offset(4)
            }
        } else {
            bubbleView.backgroundColor = BAAppTheme.card
            contentLabel.textColor = BAAppTheme.textPrimary
            typeLabel.textColor = BAAppTheme.textSecondary

            bubbleView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(4)
                make.bottom.equalToSuperview().offset(-20)
                make.left.equalToSuperview().offset(16)
                make.right.lessThanOrEqualToSuperview().offset(-60)
            }

            typeLabel.snp.remakeConstraints { make in
                make.left.equalTo(bubbleView.snp.right).offset(6)
                make.centerY.equalTo(bubbleView)
            }

            timeLabel.snp.remakeConstraints { make in
                make.left.equalTo(bubbleView)
                make.top.equalTo(bubbleView.snp.bottom).offset(4)
            }
        }
    }
}
