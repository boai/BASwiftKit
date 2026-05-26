//
//  BAToastDemoViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit
import SnapKit

final class BAToastDemoViewController: BABaseViewController {

    private let viewModel: BAToastDemoViewModel
    private let disposeBag = BADisposeBag()
    private let stack = UIStackView()

    init(viewModel: BAToastDemoViewModel) {
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
        stack.axis = .vertical
        stack.spacing = 14
        view.addSubview(stack)

        let hint = UILabel.ba_make(
            text: "点击下方按钮触发不同样式的 BAToast。\nToast 通过 keyWindow 渲染，VC 无需任何额外配置。",
            font: .systemFont(ofSize: 13, weight: .medium),
            color: BAAppTheme.textSecondary,
            alignment: .left,
            numberOfLines: 0
        )
        stack.addArrangedSubview(hint)

        stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
            make.left.right.equalToSuperview().inset(20)
        }
    }

    private func bindViewModel() {
        viewModel.options.bind { [weak self] options in
            self?.renderButtons(options)
        }.disposed(by: disposeBag)
    }

    private func renderButtons(_ options: [BAToastDemoOption]) {
        // 移除旧按钮（保留 hint）
        for view in stack.arrangedSubviews.dropFirst() {
            stack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        for opt in options {
            let btn = UIButton.ba_make(
                title: "\(opt.title)：\(opt.message)",
                titleColor: .white,
                backgroundColor: opt.color,
                font: .systemFont(ofSize: 15, weight: .semibold),
                cornerRadius: 12
            )
            btn.contentEdgeInsets = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
            btn.titleLabel?.numberOfLines = 0
            btn.titleLabel?.textAlignment = .left
            btn.contentHorizontalAlignment = .left
            btn.ba_setShadow(color: opt.color, opacity: 0.18, radius: 10, offset: CGSize(width: 0, height: 4))
            btn.ba_onTap { [weak self] _ in self?.viewModel.show(opt) }
            stack.addArrangedSubview(btn)
        }
    }
}
