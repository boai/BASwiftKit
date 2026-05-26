//
//  BAInfraDemoViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit
import SnapKit

final class BAInfraDemoViewController: BABaseViewController {

    private let viewModel: BAInfraDemoViewModel
    private let scroll = UIScrollView()
    private let stack = UIStackView.ba_make(axis: .vertical, spacing: 16)
    private let rowsStack = UIStackView.ba_make(axis: .vertical, spacing: 8)

    init(viewModel: BAInfraDemoViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        bindViewModel()
        viewModel.refresh()
    }

    private func setupLayout() {
        scroll.alwaysBounceVertical = true
        view.addSubview(scroll)
        scroll.addSubview(stack)

        scroll.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.bottom.equalToSuperview()
        }
        stack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.bottom.equalToSuperview().offset(-24)
            make.left.right.equalToSuperview().inset(16)
            make.width.equalTo(scroll).offset(-32)
        }

        stack.ba_addArrangedSubviews(
            sectionTitle("UIView.ba_onTap / ba_onLongPress"),
            makeTapCard(),
            sectionTitle("Bundle / Window / Top VC"),
            rowsStack,
            makeRefreshButton()
        )
    }

    private func sectionTitle(_ text: String) -> UILabel {
        UILabel.ba_make(text: text,
                        font: .ba_semibold(14),
                        color: BAAppTheme.textSecondary)
    }

    private func makeTapCard() -> UIView {
        let card = BACardView()
        card.ba_cardColor = BAAppTheme.cardHighlight
        card.ba_cornerRadius = BAAppTheme.cornerRadius

        let title = UILabel.ba_make(text: "👇 单击我 · 长按我",
                                    font: .ba_semibold(16),
                                    color: BAAppTheme.textPrimary,
                                    alignment: .center)
        let hint = UILabel.ba_make(text: "Tap → Toast；LongPress → Alert",
                                   font: .ba_regular(13),
                                   color: BAAppTheme.textSecondary,
                                   alignment: .center)
        let s = UIStackView.ba_make(axis: .vertical, spacing: 4, alignment: .center)
        s.ba_addArrangedSubviews(title, hint)
        card.contentView.addSubview(s)
        s.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(24)
            make.left.right.equalToSuperview().inset(16)
        }

        card.ba_onTap { _ in
            BAToast.ba_show("ba_onTap 触发", style: .success)
        }
        card.ba_onLongPress { [weak self] _ in
            self?.ba_alert(title: "长按事件",
                           message: "ba_onLongPress 触发，回调发生在 .began 阶段。",
                           confirmTitle: "好的")
        }
        return card
    }

    private func makeRefreshButton() -> UIButton {
        let btn = UIButton.ba_make(title: "刷新 Top VC / Window 信息",
                                   titleColor: .white,
                                   backgroundColor: BAAppTheme.accent,
                                   font: .ba_semibold(15),
                                   cornerRadius: BAAppTheme.smallCornerRadius)
        btn.snp.makeConstraints { make in
            make.height.equalTo(BAAppTheme.controlHeight)
        }
        btn.ba_onTap { [weak self] _ in
            self?.viewModel.refresh()
            BAToast.ba_show("已刷新")
        }
        return btn
    }

    private func bindViewModel() {
        viewModel.rows.bind { [weak self] rows in
            self?.renderRows(rows)
        }
    }

    private func renderRows(_ rows: [BAInfraRow]) {
        rowsStack.ba_removeAllArrangedSubviews()
        for r in rows {
            let card = BACardView()
            card.ba_cardColor = BAAppTheme.cardHighlight
            card.ba_cornerRadius = BAAppTheme.smallCornerRadius

            let key = UILabel.ba_make(text: r.label,
                                      font: .ba_medium(13),
                                      color: BAAppTheme.textSecondary)
            let val = UILabel.ba_make(text: r.value,
                                      font: .ba_mono(12, weight: .regular),
                                      color: BAAppTheme.textPrimary,
                                      numberOfLines: 0)

            card.contentView.ba_addSubviews(key, val)
            key.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(10)
                make.left.right.equalToSuperview().inset(12)
            }
            val.snp.makeConstraints { make in
                make.top.equalTo(key.snp.bottom).offset(4)
                make.left.right.equalTo(key)
                make.bottom.equalToSuperview().offset(-12)
            }
            rowsStack.addArrangedSubview(card)
        }
    }
}
