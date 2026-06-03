//
//  BAUtilitiesDemoViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/27.
//

import UIKit
import BASwiftKit
import SnapKit
import DemoCommon

public final class BAUtilitiesDemoViewController: BABaseViewController {

    public init() { super.init(nibName: nil, bundle: nil) }


    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private struct Row {
        let title: String
        let value: String
    }

    private let scroll = UIScrollView()
    private let stack = UIStackView()

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "工具封装 Demo"
        setupLayout()
        renderRows()
    }

    private func setupLayout() {
        view.addSubview(scroll)
        stack.axis = .vertical
        stack.spacing = 12
        scroll.addSubview(stack)

        scroll.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.bottom.equalToSuperview()
        }
        stack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.left.right.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-24)
            make.width.equalTo(scroll).offset(-32)
        }
    }

    private func renderRows() {
        let rows = makeRows()
        rows.forEach { stack.addArrangedSubview(makeCard($0)) }
    }

    private func makeRows() -> [Row] {
        let idCard = "11010519491231002X"
        let strongPassword = "BAKit@2026"
        let phone = "13800138000"
        let ip = "192.168.1.10"
        let canOpenSettings = UIApplication.shared.canOpenURL(URL(string: UIApplication.openSettingsURLString)!)
        let cameraStatus = BASystemPermission.ba_cameraStatus
        let photoStatus = BASystemPermission.ba_photoLibraryStatus

        return [
            Row(title: "身份证校验", value: "\(idCard) → \(idCard.ba_isChinaIDCard ? "通过" : "失败")"),
            Row(title: "强密码校验", value: "\(strongPassword) → \(strongPassword.ba_isStrongPassword ? "通过" : "失败")"),
            Row(title: "手机号校验", value: "\(phone) → \(phone.ba_isChinaMobile ? "通过" : "失败")"),
            Row(title: "IPv4 校验", value: "\(ip) → \(ip.ba_isIPv4 ? "通过" : "失败")"),
            Row(title: "系统跳转", value: "BAAppNavigator.ba_openAppSettings() 可打开设置页，当前 canOpen=\(canOpenSettings)"),
            Row(title: "相册权限状态", value: "\(photoStatus)"),
            Row(title: "相机权限状态", value: "\(cameraStatus)")
        ]
    }

    private func makeCard(_ row: Row) -> UIView {
        let card = BACardView()
        card.ba_cardColor = BAAppTheme.cardHighlight
        card.ba_cornerRadius = BAAppTheme.smallCornerRadius

        let titleLabel = UILabel.ba_make(text: row.title,
                                         font: .ba_semibold(15),
                                         color: BAAppTheme.textPrimary)
        let valueLabel = UILabel.ba_make(text: row.value,
                                         font: .ba_regular(13),
                                         color: BAAppTheme.textSecondary,
                                         numberOfLines: 0)

        card.contentView.ba_addSubviews(titleLabel, valueLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview().inset(14)
        }
        valueLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.left.right.bottom.equalToSuperview().inset(14)
        }
        return card
    }
}
