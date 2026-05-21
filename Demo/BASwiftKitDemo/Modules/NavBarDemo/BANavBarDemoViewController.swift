//
//  BANavBarDemoViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit

final class BANavBarDemoViewController: BABaseViewController {

    private let viewModel: BANavBarDemoViewModel
    private let stack = UIStackView.ba_make(axis: .vertical, spacing: 12)
    private let hint = UILabel()

    init(viewModel: BANavBarDemoViewModel) {
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

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 退出本页时还原全局导航栏样式，避免污染其他页面
        navigationController?.ba_apply(style: BANavigationBarStyle(
            background: .solid(BAAppTheme.background),
            tintColor: BAAppTheme.accent,
            titleColor: BAAppTheme.textPrimary
        ))
    }

    private func setupLayout() {
        hint.text = "点击下面任一按钮，看导航栏样式立即切换。\n离开本页时会自动还原默认外观。"
        hint.font = .ba_medium(13)
        hint.textColor = BAAppTheme.textSecondary
        hint.numberOfLines = 0
        stack.addArrangedSubview(hint)

        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
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
                                       cornerRadius: 12)
            btn.heightAnchor.constraint(equalToConstant: 48).isActive = true
            btn.ba_onTap { [weak self] _ in
                self?.navigationController?.ba_apply(style: p.style)
            }
            stack.addArrangedSubview(btn)
        }
    }
}
