//
//  BAComponentsDemoViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit
import SnapKit
import DemoCommon

public final class BAComponentsDemoViewController: BABaseViewController {

    private let viewModel: BAComponentsDemoViewModel
    private let disposeBag = BADisposeBag()
    private let scroll = UIScrollView()
    private let content = UIStackView()

    private let gradientsStack = UIStackView()
    private let badgesWrap = UIView()
    private let cardSample = BACardView()
    private let deviceCard = BACardView()
    private var badgesWrapHeight: Constraint?

    public init(viewModel: BAComponentsDemoViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        bindViewModel()
        viewModel.loadData()
        renderDeviceCard()
    }

    private func setupLayout() {
        scroll.alwaysBounceVertical = true
        view.addSubview(scroll)

        content.axis = .vertical
        content.spacing = 22
        content.alignment = .fill
        scroll.addSubview(content)

        scroll.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.bottom.equalToSuperview()
        }
        content.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.bottom.equalToSuperview().offset(-24)
            make.left.right.equalToSuperview().inset(16)
            make.width.equalTo(scroll).offset(-32)
        }

        // BAGradientView 区
        content.addArrangedSubview(sectionTitle("BAGradientView"))
        gradientsStack.axis = .vertical
        gradientsStack.spacing = 10
        content.addArrangedSubview(gradientsStack)

        // BABadgeView 区
        content.addArrangedSubview(sectionTitle("BABadgeView"))
        content.addArrangedSubview(badgesWrap)
        badgesWrap.snp.makeConstraints { make in
            badgesWrapHeight = make.height.equalTo(0).constraint
        }

        // BACardView 区
        content.addArrangedSubview(sectionTitle("BACardView"))
        cardSample.ba_cardColor = BAAppTheme.cardHighlight
        cardSample.ba_cornerRadius = BAAppTheme.cornerRadius
        cardSample.snp.makeConstraints { make in
            make.height.equalTo(110)
        }

        let title = UILabel.ba_make(text: "卡片容器",
                                    font: .systemFont(ofSize: 16, weight: .semibold),
                                    color: BAAppTheme.textPrimary)
        let body = UILabel.ba_make(text: "BACardView 自带圆角和柔和阴影，挂内容到 contentView 即可。",
                                   font: .systemFont(ofSize: 13),
                                   color: BAAppTheme.textSecondary,
                                   numberOfLines: 0)
        cardSample.contentView.ba_addSubviews(title, body)
        title.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.left.right.equalToSuperview().inset(16)
        }
        body.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(6)
            make.left.right.equalTo(title)
        }
        content.addArrangedSubview(cardSample)

        // BADeviceInfo 区
        content.addArrangedSubview(sectionTitle("BADeviceInfo"))
        deviceCard.ba_cardColor = BAAppTheme.cardHighlight
        deviceCard.ba_cornerRadius = BAAppTheme.cornerRadius
        content.addArrangedSubview(deviceCard)
    }

    private func sectionTitle(_ text: String) -> UILabel {
        UILabel.ba_make(text: text,
                        font: .systemFont(ofSize: 14, weight: .semibold),
                        color: BAAppTheme.textSecondary)
    }

    private func bindViewModel() {
        viewModel.gradients.bind { [weak self] list in self?.renderGradients(list) }.disposed(by: disposeBag)
        viewModel.badges.bind { [weak self] list in self?.renderBadges(list) }.disposed(by: disposeBag)
    }

    private func renderGradients(_ list: [BAComponentsDemoViewModel.GradientSample]) {
        gradientsStack.ba_removeAllSubviews()
        for sample in list {
            let g = BAGradientView()
            g.ba_colors = sample.colors
            g.ba_direction = sample.direction
            g.layer.cornerRadius = BAAppTheme.cornerRadius
            g.layer.cornerCurve = .continuous
            g.layer.masksToBounds = true
            g.ba_setShadow(color: sample.colors.first ?? BAAppTheme.accent, opacity: 0.16, radius: 14, offset: CGSize(width: 0, height: 6))
            g.snp.makeConstraints { make in
                make.height.equalTo(78)
            }

            let label = UILabel.ba_make(text: sample.name,
                                        font: .systemFont(ofSize: 16, weight: .semibold),
                                        color: .white)
            g.addSubview(label)
            label.snp.makeConstraints { make in
                make.left.equalToSuperview().offset(18)
                make.centerY.equalToSuperview()
            }
            gradientsStack.addArrangedSubview(g)
        }
    }

    private func renderBadges(_ list: [BAComponentsDemoViewModel.BadgeSample]) {
        badgesWrap.ba_removeAllSubviews()
        // 简易换行 flow 布局（frame 算法换行 + SnapKit 更新容器高度）
        var x: CGFloat = 0
        var y: CGFloat = 0
        let spacing: CGFloat = 8
        let maxWidth = view.bounds.width - 32

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

        badgesWrapHeight?.update(offset: y + 30)
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
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
    }
}
