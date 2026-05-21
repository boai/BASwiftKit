//
//  BALoadingDemoViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit

final class BALoadingDemoViewController: BABaseViewController {

    private let viewModel: BALoadingDemoViewModel
    private let stack = UIStackView.ba_make(axis: .vertical, spacing: 12)

    init(viewModel: BALoadingDemoViewModel) {
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
        let hint = UILabel.ba_make(
            text: "BALoadingHUD 支持全屏阻塞、局部容器、运行时更新文案。",
            font: .ba_medium(13),
            color: BAAppTheme.textSecondary,
            numberOfLines: 0
        )
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
        viewModel.scenarios.bind { [weak self] list in
            self?.renderButtons(list)
        }
    }

    private func renderButtons(_ scenarios: [BALoadingScenario]) {
        for v in stack.arrangedSubviews.dropFirst() {
            stack.removeArrangedSubview(v)
            v.removeFromSuperview()
        }
        for s in scenarios {
            let btn = UIButton.ba_make(title: s.title,
                                       titleColor: .white,
                                       backgroundColor: BAAppTheme.accent,
                                       font: .ba_semibold(15),
                                       cornerRadius: 12)
            btn.heightAnchor.constraint(equalToConstant: 48).isActive = true
            btn.ba_onTap { [weak self] _ in
                guard let host = self?.view else { return }
                s.action(host)
            }
            stack.addArrangedSubview(btn)
        }
    }
}
