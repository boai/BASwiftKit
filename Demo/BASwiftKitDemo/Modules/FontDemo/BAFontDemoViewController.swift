//
//  BAFontDemoViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit
import SnapKit

final class BAFontDemoViewController: BABaseViewController {

    private let viewModel: BAFontDemoViewModel
    private let disposeBag = BADisposeBag()

    private let scroll = UIScrollView()
    private let stack = UIStackView.ba_make(axis: .vertical, spacing: 16)

    init(viewModel: BAFontDemoViewModel) {
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
    }

    private func bindViewModel() {
        viewModel.rows.bind { [weak self] rows in
            self?.renderRows(rows)
        }.disposed(by: disposeBag)
    }

    private func renderRows(_ rows: [BAFontDemoRow]) {
        stack.ba_removeAllArrangedSubviews()
        for r in rows {
            let card = BACardView()
            card.ba_cardColor = BAAppTheme.cardHighlight
            card.ba_cornerRadius = BAAppTheme.smallCornerRadius

            let api = UILabel.ba_make(text: r.label,
                                      font: .ba_mono(11, weight: .medium),
                                      color: BAAppTheme.textSecondary)

            let cnLabel = UILabel.ba_make(text: "永远相信美好的事情即将发生",
                                          font: r.font,
                                          color: BAAppTheme.textPrimary,
                                          numberOfLines: 0)
            let enLabel = UILabel.ba_make(text: "The quick brown fox jumps over the lazy dog",
                                          font: r.font,
                                          color: BAAppTheme.textPrimary,
                                          numberOfLines: 0)
            let preview = UIStackView.ba_make(axis: .vertical, spacing: 4)
            preview.ba_addArrangedSubviews(cnLabel, enLabel)

            card.contentView.ba_addSubviews(api, preview)
            api.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(12)
                make.left.right.equalToSuperview().inset(14)
            }
            preview.snp.makeConstraints { make in
                make.top.equalTo(api.snp.bottom).offset(6)
                make.left.right.equalTo(api)
                make.bottom.equalToSuperview().offset(-14)
            }
            stack.addArrangedSubview(card)
        }
    }
}
