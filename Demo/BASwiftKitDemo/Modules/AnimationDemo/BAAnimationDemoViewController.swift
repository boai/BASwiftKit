//
//  BAAnimationDemoViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit

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
        target.layer.cornerRadius = 16
        target.layer.masksToBounds = true
        target.translatesAutoresizingMaskIntoConstraints = false

        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        target.addSubview(icon)

        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.alwaysBounceVertical = true
        view.addSubview(scroll)
        scroll.addSubview(buttonsStack)

        view.addSubview(target)

        NSLayoutConstraint.activate([
            target.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            target.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            target.widthAnchor.constraint(equalToConstant: 120),
            target.heightAnchor.constraint(equalToConstant: 120),

            icon.centerXAnchor.constraint(equalTo: target.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: target.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 48),
            icon.heightAnchor.constraint(equalToConstant: 48),

            scroll.topAnchor.constraint(equalTo: target.bottomAnchor, constant: 24),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            buttonsStack.topAnchor.constraint(equalTo: scroll.topAnchor),
            buttonsStack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -24),
            buttonsStack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 20),
            buttonsStack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -20),
            buttonsStack.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -40)
        ])
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
                                       cornerRadius: 12)
            btn.heightAnchor.constraint(equalToConstant: 44).isActive = true
            btn.ba_onTap { [weak self] _ in
                guard let self = self else { return }
                s.apply(self.target)
            }
            buttonsStack.addArrangedSubview(btn)
        }
    }
}
