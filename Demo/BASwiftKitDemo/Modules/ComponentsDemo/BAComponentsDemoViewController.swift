//
//  BAComponentsDemoViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit

final class BAComponentsDemoViewController: BABaseViewController {

    private let viewModel: BAComponentsDemoViewModel
    private let scroll = UIScrollView()
    private let content = UIStackView()

    private let gradientsStack = UIStackView()
    private let badgesWrap = UIView()
    private let cardSample = BACardView()
    private let deviceCard = BACardView()

    init(viewModel: BAComponentsDemoViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        bindViewModel()
        viewModel.loadData()
        renderDeviceCard()
    }

    private func setupLayout() {
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.alwaysBounceVertical = true
        view.addSubview(scroll)

        content.axis = .vertical
        content.spacing = 22
        content.alignment = .fill
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            content.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 16),
            content.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -24),
            content.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 16),
            content.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -16),
            content.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -32)
        ])

        // BAGradientView 区
        content.addArrangedSubview(sectionTitle("BAGradientView"))
        gradientsStack.axis = .vertical
        gradientsStack.spacing = 10
        content.addArrangedSubview(gradientsStack)

        // BABadgeView 区
        content.addArrangedSubview(sectionTitle("BABadgeView"))
        content.addArrangedSubview(badgesWrap)

        // BACardView 区
        content.addArrangedSubview(sectionTitle("BACardView"))
        cardSample.ba_cardColor = BAAppTheme.card
        cardSample.ba_cornerRadius = BAAppTheme.cornerRadius
        cardSample.translatesAutoresizingMaskIntoConstraints = false
        cardSample.heightAnchor.constraint(equalToConstant: 110).isActive = true

        let title = UILabel.ba_make(text: "卡片容器",
                                    font: .systemFont(ofSize: 16, weight: .semibold),
                                    color: BAAppTheme.textPrimary)
        let body = UILabel.ba_make(text: "BACardView 自带圆角和柔和阴影，挂内容到 contentView 即可。",
                                   font: .systemFont(ofSize: 13),
                                   color: BAAppTheme.textSecondary,
                                   numberOfLines: 0)
        title.translatesAutoresizingMaskIntoConstraints = false
        body.translatesAutoresizingMaskIntoConstraints = false
        cardSample.contentView.ba_addSubviews(title, body)
        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: cardSample.contentView.topAnchor, constant: 16),
            title.leadingAnchor.constraint(equalTo: cardSample.contentView.leadingAnchor, constant: 16),
            title.trailingAnchor.constraint(equalTo: cardSample.contentView.trailingAnchor, constant: -16),
            body.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 6),
            body.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            body.trailingAnchor.constraint(equalTo: title.trailingAnchor)
        ])
        content.addArrangedSubview(cardSample)

        // BADeviceInfo 区
        content.addArrangedSubview(sectionTitle("BADeviceInfo"))
        deviceCard.ba_cardColor = BAAppTheme.card
        deviceCard.ba_cornerRadius = BAAppTheme.cornerRadius
        deviceCard.translatesAutoresizingMaskIntoConstraints = false
        content.addArrangedSubview(deviceCard)
    }

    private func sectionTitle(_ text: String) -> UILabel {
        UILabel.ba_make(text: text,
                        font: .systemFont(ofSize: 14, weight: .semibold),
                        color: BAAppTheme.textSecondary)
    }

    private func bindViewModel() {
        viewModel.gradients.bind { [weak self] list in self?.renderGradients(list) }
        viewModel.badges.bind { [weak self] list in self?.renderBadges(list) }
    }

    private func renderGradients(_ list: [BAComponentsDemoViewModel.GradientSample]) {
        gradientsStack.ba_removeAllSubviews()
        for sample in list {
            let g = BAGradientView()
            g.ba_colors = sample.colors
            g.ba_direction = sample.direction
            g.layer.cornerRadius = 14
            g.layer.masksToBounds = true
            g.translatesAutoresizingMaskIntoConstraints = false
            g.heightAnchor.constraint(equalToConstant: 72).isActive = true

            let label = UILabel.ba_make(text: sample.name,
                                        font: .systemFont(ofSize: 16, weight: .semibold),
                                        color: .white)
            label.translatesAutoresizingMaskIntoConstraints = false
            g.addSubview(label)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 18),
                label.centerYAnchor.constraint(equalTo: g.centerYAnchor)
            ])
            gradientsStack.addArrangedSubview(g)
        }
    }

    private func renderBadges(_ list: [BAComponentsDemoViewModel.BadgeSample]) {
        badgesWrap.ba_removeAllSubviews()
        // 简易换行 flow 布局
        var x: CGFloat = 0
        var y: CGFloat = 0
        let spacing: CGFloat = 8
        let maxWidth = view.bounds.width - 32

        let temp = UIView(frame: .zero)
        badgesWrap.addSubview(temp)
        badgesWrap.translatesAutoresizingMaskIntoConstraints = false

        for sample in list {
            let badge = BABadgeView()
            badge.ba_text = sample.text
            badge.ba_badgeColor = sample.color
            badge.ba_textColor = .white
            badge.ba_font = .systemFont(ofSize: 12, weight: .semibold)
            let size = badge.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
            if x + size.width > maxWidth {
                x = 0
                y += size.height + spacing
            }
            badge.frame = CGRect(x: x, y: y, width: size.width, height: size.height)
            badgesWrap.addSubview(badge)
            x += size.width + spacing
        }
        temp.removeFromSuperview()

        let totalHeight = y + 30
        for c in badgesWrap.constraints where c.firstAttribute == .height {
            badgesWrap.removeConstraint(c)
        }
        badgesWrap.heightAnchor.constraint(equalToConstant: totalHeight).isActive = true
    }

    private func renderDeviceCard() {
        let rows: [(String, String)] = [
            ("App",         BADeviceInfo.ba_appName.isEmpty ? "BASwiftKitDemo" : BADeviceInfo.ba_appName),
            ("Version",     "\(BADeviceInfo.ba_appVersion) (\(BADeviceInfo.ba_buildNumber))"),
            ("BundleID",    BADeviceInfo.ba_bundleId),
            ("System",      "\(BADeviceInfo.ba_systemName) \(BADeviceInfo.ba_systemVersion)"),
            ("Model",       BADeviceInfo.ba_machineModel),
            ("Screen",      "\(Int(BADeviceInfo.ba_screenSize.width))×\(Int(BADeviceInfo.ba_screenSize.height)) @\(Int(BADeviceInfo.ba_screenScale))x"),
            ("Notched",     BADeviceInfo.ba_isNotched ? "是" : "否")
        ]
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        for r in rows {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 8
            row.distribution = .equalSpacing
            let l = UILabel.ba_make(text: r.0,
                                    font: .systemFont(ofSize: 13, weight: .medium),
                                    color: BAAppTheme.textSecondary)
            let v = UILabel.ba_make(text: r.1,
                                    font: .monospacedSystemFont(ofSize: 13, weight: .regular),
                                    color: BAAppTheme.textPrimary,
                                    alignment: .right)
            row.addArrangedSubview(l)
            row.addArrangedSubview(v)
            stack.addArrangedSubview(row)
        }
        deviceCard.contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: deviceCard.contentView.topAnchor, constant: 16),
            stack.bottomAnchor.constraint(equalTo: deviceCard.contentView.bottomAnchor, constant: -16),
            stack.leadingAnchor.constraint(equalTo: deviceCard.contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: deviceCard.contentView.trailingAnchor, constant: -16)
        ])
    }
}
