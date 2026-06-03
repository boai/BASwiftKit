//
//  BAScannerDemoViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/27.
//

import UIKit
import BASwiftKit
import SnapKit
import DemoCommon

final class BAScannerDemoViewController: BABaseViewController {

    private let stack = UIStackView()
    private let resultLabel = UILabel.ba_make(text: "点击按钮打开扫一扫，识别二维码或条形码后会回到这里显示结果。",
                                              font: .ba_regular(14),
                                              color: BAAppTheme.textSecondary,
                                              numberOfLines: 0)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "扫一扫 Demo"
        setupLayout()
    }

    private func setupLayout() {
        view.addSubview(stack)
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill

        let intro = makeCard(title: "独立扫码封装",
                             value: "BAScannerSession 负责相机采集和识别，BAScannerViewController 只负责基础扫码页面，不依赖权限工具、导航工具或业务模块。")
        let resultCard = makeResultCard()
        let scanButton = UIButton(type: .system)
        scanButton.setTitle("打开扫一扫", for: .normal)
        scanButton.titleLabel?.font = .ba_semibold(16)
        scanButton.backgroundColor = BAAppTheme.accent
        scanButton.tintColor = .white
        scanButton.layer.cornerRadius = BAAppTheme.smallCornerRadius
        scanButton.addTarget(self, action: #selector(openScanner), for: .touchUpInside)

        stack.addArrangedSubview(intro)
        stack.addArrangedSubview(resultCard)
        stack.addArrangedSubview(scanButton)

        stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(16)
            make.left.right.equalToSuperview().inset(16)
        }
        scanButton.snp.makeConstraints { make in
            make.height.equalTo(48)
        }
    }

    private func makeResultCard() -> UIView {
        let card = BACardView()
        card.ba_cardColor = BAAppTheme.cardHighlight
        card.ba_cornerRadius = BAAppTheme.cornerRadius

        let titleLabel = UILabel.ba_make(text: "扫码结果",
                                         font: .ba_semibold(15),
                                         color: BAAppTheme.textPrimary)
        card.contentView.ba_addSubviews(titleLabel, resultLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview().inset(16)
        }
        resultLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.right.bottom.equalToSuperview().inset(16)
        }
        return card
    }

    private func makeCard(title: String, value: String) -> UIView {
        let card = BACardView()
        card.ba_cardColor = BAAppTheme.cardHighlight
        card.ba_cornerRadius = BAAppTheme.cornerRadius

        let titleLabel = UILabel.ba_make(text: title,
                                         font: .ba_semibold(15),
                                         color: BAAppTheme.textPrimary)
        let valueLabel = UILabel.ba_make(text: value,
                                         font: .ba_regular(13),
                                         color: BAAppTheme.textSecondary,
                                         numberOfLines: 0)
        card.contentView.ba_addSubviews(titleLabel, valueLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview().inset(16)
        }
        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.right.bottom.equalToSuperview().inset(16)
        }
        return card
    }

    @objc private func openScanner() {
        let scanner = BAScannerViewController(configuration: BAScannerConfiguration(codeTypes: [.qr, .ean13, .code128]))
        scanner.title = "扫一扫"
        scanner.onResult = { [weak self, weak scanner] result in
            scanner?.navigationController?.popViewController(animated: true)
            self?.resultLabel.text = "type=\(result.metadataObjectType.rawValue)\nvalue=\(result.value)"
        }
        scanner.onError = { [weak self] error in
            self?.resultLabel.text = "扫码失败：\(error)"
        }
        navigationController?.pushViewController(scanner, animated: true)
    }
}
