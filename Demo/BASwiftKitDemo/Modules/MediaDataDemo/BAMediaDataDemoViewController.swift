//
//  BAMediaDataDemoViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/27.
//

import UIKit
import BASwiftKit
import SnapKit

final class BAMediaDataDemoViewController: BABaseViewController {

    private let scroll = UIScrollView()
    private let stack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Data & Image Demo"
        setupLayout()
        renderDemo()
    }

    private func setupLayout() {
        view.addSubview(scroll)
        stack.axis = .vertical
        stack.spacing = 14
        scroll.addSubview(stack)

        scroll.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        stack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.left.right.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-24)
            make.width.equalTo(scroll).offset(-32)
        }
    }

    private func renderDemo() {
        stack.addArrangedSubview(makeImagePreview())
        makeDataRows().forEach { stack.addArrangedSubview(makeTextCard(title: $0.title, value: $0.value)) }
    }

    private func makeImagePreview() -> UIView {
        let card = BACardView()
        card.ba_cardColor = BAAppTheme.cardHighlight
        card.ba_cornerRadius = BAAppTheme.cornerRadius

        let image = UIImage.ba_gradientImage(colors: [BAAppTheme.accent, BAAppTheme.accentSecondary],
                                             size: CGSize(width: 160, height: 100))?
            .ba_rounded(radius: 18)
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 18
        imageView.clipsToBounds = true

        let info = UILabel.ba_make(
            text: "UIImage 封装：渐变图、圆角、像素尺寸、Base64、压缩等\nsize=\(image?.size ?? .zero), pixel=\(image?.ba_pixelSize ?? .zero)",
            font: .ba_regular(13),
            color: BAAppTheme.textSecondary,
            numberOfLines: 0
        )

        card.contentView.ba_addSubviews(imageView, info)
        imageView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview().inset(16)
            make.height.equalTo(120)
        }
        info.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(12)
            make.left.right.bottom.equalToSuperview().inset(16)
        }
        return card
    }

    private func makeDataRows() -> [(title: String, value: String)] {
        do {
            let data = try Data(ba_hexString: "AA 01 02 0A FF")
            var reader = BADataReader(data: data)
            let header = try reader.readUInt8()
            let length = try reader.readUInt16(byteOrder: .bigEndian)
            return [
                ("Hex 解析", data.ba_spacedHexString),
                ("字节数组", "\(data.ba_bytes)"),
                ("顺序读取", "header=0x\(String(format: "%02X", header)), length=\(length), remaining=\(reader.remainingCount)"),
                ("校验值", "checksum8=0x\(String(format: "%02X", data.ba_checksum8)), xor=0x\(String(format: "%02X", data.ba_xorChecksum))"),
                ("CRC16-MODBUS", data.ba_crc16ModbusData.ba_spacedHexString),
                ("分包", data.ba_chunks(size: 2).map(\.ba_spacedHexString).joined(separator: " | "))
            ]
        } catch {
            return [("Data 解析失败", error.localizedDescription)]
        }
    }

    private func makeTextCard(title: String, value: String) -> UIView {
        let card = BACardView()
        card.ba_cardColor = BAAppTheme.cardHighlight
        card.ba_cornerRadius = BAAppTheme.smallCornerRadius

        let badge = BABadgeView()
        badge.ba_text = title
        badge.ba_badgeColor = BAAppTheme.accent.withAlphaComponent(0.14)
        badge.ba_textColor = BAAppTheme.accent

        let valueLabel = UILabel.ba_make(text: value,
                                         font: .ba_mono(13, weight: .regular),
                                         color: BAAppTheme.textPrimary,
                                         numberOfLines: 0)

        card.contentView.ba_addSubviews(badge, valueLabel)
        badge.snp.makeConstraints { make in
            make.top.left.equalToSuperview().offset(14)
        }
        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(badge.snp.bottom).offset(10)
            make.left.right.bottom.equalToSuperview().inset(14)
        }
        return card
    }
}
