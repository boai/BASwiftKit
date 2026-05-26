//
//  BAAnimationDemoViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit
import SnapKit

final class BAAnimationDemoViewController: BABaseViewController {

    private let viewModel: BAAnimationDemoViewModel

    private let target = BAGradientView()
    private let icon = UIImageView(image: UIImage(systemName: "sparkles"))
    private let buttonsStack = UIStackView.ba_make(axis: .vertical, spacing: 10)
    private let scroll = UIScrollView()

    init(viewModel: BAAnimationDemoViewModel) {
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
        target.ba_colors = BAAppTheme.brandGradient
        target.ba_direction = .leadingDiagonal
        target.layer.cornerRadius = 32
        target.layer.cornerCurve = .continuous
        target.ba_setShadow(color: BAAppTheme.accent, opacity: 0.28, radius: 24, offset: CGSize(width: 0, height: 14))

        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        target.addSubview(icon)

        scroll.alwaysBounceVertical = true
        view.addSubview(scroll)
        scroll.addSubview(buttonsStack)

        view.addSubview(target)

        target.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(28)
            make.centerX.equalToSuperview()
            make.size.equalTo(132)
        }
        icon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(48)
        }
        scroll.snp.makeConstraints { make in
            make.top.equalTo(target.snp.bottom).offset(24)
            make.left.right.bottom.equalToSuperview()
        }
        buttonsStack.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview().offset(-24)
            make.left.right.equalToSuperview().inset(20)
            make.width.equalTo(scroll).offset(-40)
        }
    }

    private func bindViewModel() {
        viewModel.samples.bind { [weak self] samples in
            self?.renderButtons(samples)
        }
    }

    private func renderButtons(_ samples: [BAAnimationSample]) {
        buttonsStack.ba_removeAllArrangedSubviews()
        for s in samples {
            let btn = UIButton.ba_make(title: s.title,
                                       titleColor: .white,
                                       backgroundColor: BAAppTheme.accent,
                                       font: .ba_semibold(15),
                                       cornerRadius: BAAppTheme.smallCornerRadius)
            btn.snp.makeConstraints { make in make.height.equalTo(BAAppTheme.controlHeight) }
            btn.ba_onTap { [weak self] _ in
                guard let self = self else { return }
                s.apply(self.target)
            }
            buttonsStack.addArrangedSubview(btn)
        }
    }
}
