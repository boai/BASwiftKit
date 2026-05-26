//
//  BADeviceInfoDemoViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit
import SnapKit

final class BADeviceInfoDemoViewController: BABaseViewController {

    private let viewModel: BADeviceInfoDemoViewModel
    private let disposeBag = BADisposeBag()
    private let scroll = UIScrollView()
    private let stack = UIStackView.ba_make(axis: .vertical, spacing: 18)
    private let cacheCard = BACardView()
    private let cacheValueLabel = UILabel.ba_make(font: .ba_mono(13, weight: .medium),
                                                  color: BAAppTheme.textPrimary,
                                                  alignment: .right)

    init(viewModel: BADeviceInfoDemoViewModel) {
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
            make.top.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-28)
            make.left.right.equalToSuperview().inset(16)
            make.width.equalTo(scroll).offset(-32)
        }

        stack.addArrangedSubview(makeCacheCard())
    }

    private func makeCacheCard() -> UIView {
        cacheCard.ba_cardColor = BAAppTheme.cardHighlight
        cacheCard.ba_cornerRadius = BAAppTheme.cornerRadius

        let title = UILabel.ba_make(text: "App 缓存",
                                    font: .ba_semibold(15),
                                    color: BAAppTheme.textPrimary)
        let hint = UILabel.ba_make(text: "Library/Caches + tmp",
                                   font: .ba_regular(12),
                                   color: BAAppTheme.textSecondary)
        let leftStack = UIStackView.ba_make(axis: .vertical, spacing: 2)
        leftStack.ba_addArrangedSubviews(title, hint)

        cacheValueLabel.setContentHuggingPriority(.required, for: .horizontal)

        let clearBtn = UIButton.ba_make(title: "清除",
                                        titleColor: .white,
                                        backgroundColor: BAAppTheme.danger,
                                        font: .ba_semibold(13),
                                        cornerRadius: BAAppTheme.smallCornerRadius)
        clearBtn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        clearBtn.setContentHuggingPriority(.required, for: .horizontal)
        clearBtn.ba_onTap { [weak self] _ in self?.confirmAndClear() }

        cacheCard.contentView.ba_addSubviews(leftStack, cacheValueLabel, clearBtn)
        leftStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(14)
            make.left.equalToSuperview().offset(14)
        }
        cacheValueLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.greaterThanOrEqualTo(leftStack.snp.right).offset(12)
            make.right.equalTo(clearBtn.snp.left).offset(-12)
        }
        clearBtn.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-14)
        }
        return cacheCard
    }

    private func confirmAndClear() {
        ba_alert(title: "清除缓存？",
                 message: "将清空 Library/Caches 和 tmp 下的所有文件，Documents 不会被动到。",
                 confirmTitle: "清除",
                 cancelTitle: "取消",
                 onConfirm: { [weak self] in
                     BALoadingHUD.ba_show(message: "正在清理…")
                     self?.viewModel.clearCache { ok in
                         BALoadingHUD.ba_hide()
                         BAToast.ba_show(ok ? "已清空" : "部分文件清理失败",
                                         style: ok ? .success : .warning)
                     }
                 })
    }

    private func bindViewModel() {
        viewModel.sections.bind { [weak self] sections in
            self?.renderSections(sections)
        }.disposed(by: disposeBag)
        viewModel.cacheSizeText.bind { [weak self] text in
            self?.cacheValueLabel.text = text
        }.disposed(by: disposeBag)
    }

    private func renderSections(_ sections: [BADeviceInfoSection]) {
        // 移除除 cacheCard 之外的旧 section
        for v in stack.arrangedSubviews where v !== cacheCard {
            stack.removeArrangedSubview(v)
            v.removeFromSuperview()
        }
        for sec in sections {
            stack.addArrangedSubview(makeSectionHeader(sec.title))
            stack.addArrangedSubview(makeSectionCard(rows: sec.rows))
        }
    }

    private func makeSectionHeader(_ text: String) -> UILabel {
        UILabel.ba_make(text: text,
                        font: .ba_semibold(14),
                        color: BAAppTheme.textSecondary)
    }

    private func makeSectionCard(rows: [(String, String)]) -> UIView {
        let card = BACardView()
        card.ba_cardColor = BAAppTheme.cardHighlight
        card.ba_cornerRadius = BAAppTheme.cornerRadius

        let inner = UIStackView.ba_make(axis: .vertical, spacing: 10)
        for (k, v) in rows {
            let row = UIStackView.ba_make(axis: .horizontal, spacing: 8, distribution: .equalSpacing)
            let key = UILabel.ba_make(text: k,
                                      font: .ba_medium(13),
                                      color: BAAppTheme.textSecondary)
            let val = UILabel.ba_make(text: v,
                                      font: .ba_mono(12, weight: .regular),
                                      color: BAAppTheme.textPrimary,
                                      alignment: .right,
                                      numberOfLines: 0)
            row.addArrangedSubview(key)
            row.addArrangedSubview(val)
            inner.addArrangedSubview(row)
        }
        card.contentView.addSubview(inner)
        inner.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(14)
        }
        return card
    }
}
