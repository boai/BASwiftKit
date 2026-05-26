//
//  BANavBarDemoViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit
import SnapKit

final class BANavBarDemoViewController: BABaseViewController {

    private let viewModel: BANavBarDemoViewModel
    private let stack = UIStackView.ba_make(axis: .vertical, spacing: 12)
    private let hint = UILabel()

    init(viewModel: BANavBarDemoViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private let defaultStyle = BANavigationBarStyle(
        background: .solid(BAAppTheme.background),
        tintColor: BAAppTheme.accent,
        titleColor: BAAppTheme.textPrimary
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        bindViewModel()
        viewModel.loadData()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 退出本页时还原全局导航栏样式，避免污染其他页面
        navigationController?.ba_apply(style: defaultStyle)
    }

    private func setupLayout() {
        hint.text = "点击下面任一按钮，会跳到预览页展示该导航栏样式。\n最后一项「滑动渐变」演示透明 → 实色过渡。\n返回时自动还原默认外观。"
        hint.font = .ba_medium(13)
        hint.textColor = BAAppTheme.textSecondary
        hint.numberOfLines = 0
        stack.addArrangedSubview(hint)

        view.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
            make.left.right.equalToSuperview().inset(20)
        }
    }

    private func bindViewModel() {
        viewModel.presets.bind { [weak self] presets in
            self?.renderButtons(presets)
        }
    }

    private func renderButtons(_ presets: [BANavBarStylePreset]) {
        for v in stack.arrangedSubviews.dropFirst() {
            stack.removeArrangedSubview(v)
            v.removeFromSuperview()
        }
        for p in presets {
            let btn = UIButton.ba_make(title: p.title,
                                       titleColor: .white,
                                       backgroundColor: BAAppTheme.accent,
                                       font: .ba_semibold(15),
                                       cornerRadius: BAAppTheme.smallCornerRadius)
            btn.snp.makeConstraints { make in make.height.equalTo(BAAppTheme.controlHeight) }
            btn.ba_onTap { [weak self] _ in
                guard let self else { return }
                let preview = BANavBarPreviewViewController(
                    presetTitle: p.title,
                    style: p.style,
                    restoreStyle: self.defaultStyle
                )
                self.navigationController?.pushViewController(preview, animated: true)
            }
            stack.addArrangedSubview(btn)
        }

        let scrollBtn = UIButton.ba_make(title: "滑动渐变 · 透明 → 实色",
                                         titleColor: .white,
                                         backgroundColor: BAAppTheme.accentSecondary,
                                         font: .ba_semibold(15),
                                         cornerRadius: BAAppTheme.smallCornerRadius)
        scrollBtn.snp.makeConstraints { make in make.height.equalTo(BAAppTheme.controlHeight) }
        scrollBtn.ba_onTap { [weak self] _ in
            let scrollDemo = BANavBarScrollGradientViewController()
            self?.navigationController?.pushViewController(scrollDemo, animated: true)
        }
        stack.addArrangedSubview(scrollBtn)
    }
}
