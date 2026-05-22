//
//  BANavBarScrollGradientViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit

/// 演示：进入时导航栏透明，向下滚动时背景逐渐变为实色，标题也跟着从白色淡入到深色。
/// 这里没有继承 BABaseViewController：基类的 per-VC 外观会盖掉 ba_apply 设置的导航栏样式。
final class BANavBarScrollGradientViewController: UIViewController, UIScrollViewDelegate {

    private let restoreStyle: BANavigationBarStyle
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView.ba_make(axis: .vertical, spacing: 16)
    private let headerGradient = BAGradientView()
    private let topBackdrop = UIView()
    private let titleLabel = UILabel.ba_make(text: "滑动渐变",
                                             font: .systemFont(ofSize: 17, weight: .semibold),
                                             color: .white,
                                             alignment: .center)

    /// nav + 状态栏整体「实色化」的滚动阈值
    private let fadeDistance: CGFloat = 120

    init(restoreStyle: BANavigationBarStyle) {
        self.restoreStyle = restoreStyle
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = BAAppTheme.background
        // 自己掌管导航栏标题，UINavigationItem 的 title 留空免得跟头图标题打架
        navigationItem.title = ""

        setupScrollView()
        setupHeader()
        setupBodyContent()
        setupTopBackdrop()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 进入时：透明导航栏，浅色 tint，方便和深色头图对比
        navigationController?.ba_apply(style: BANavigationBarStyle(
            background: .transparent,
            tintColor: .white,
            titleColor: .white
        ))
        updateForScroll(scrollView.contentOffset.y)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.ba_apply(style: restoreStyle)
    }

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.alignment = .fill
        scrollView.addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    private func setupHeader() {
        let header = UIView()
        header.translatesAutoresizingMaskIntoConstraints = false

        headerGradient.translatesAutoresizingMaskIntoConstraints = false
        headerGradient.ba_colors = [
            UIColor(ba_hex: "#F2A22C") ?? .systemOrange,
            UIColor(ba_hex: "#EF4F4F") ?? .systemRed
        ]
        headerGradient.ba_direction = .leadingDiagonal
        header.addSubview(headerGradient)

        let bigTitle = UILabel.ba_make(text: "向下滑动看导航栏渐变",
                                       font: .systemFont(ofSize: 24, weight: .bold),
                                       color: .white,
                                       numberOfLines: 0)
        let subtitle = UILabel.ba_make(text: "Nav 背景透明 → 实色 · 标题白 → 深色",
                                       font: .systemFont(ofSize: 13, weight: .medium),
                                       color: UIColor.white.withAlphaComponent(0.85),
                                       numberOfLines: 0)
        bigTitle.translatesAutoresizingMaskIntoConstraints = false
        subtitle.translatesAutoresizingMaskIntoConstraints = false
        headerGradient.addSubview(bigTitle)
        headerGradient.addSubview(subtitle)

        NSLayoutConstraint.activate([
            headerGradient.topAnchor.constraint(equalTo: header.topAnchor),
            headerGradient.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            headerGradient.trailingAnchor.constraint(equalTo: header.trailingAnchor),
            headerGradient.bottomAnchor.constraint(equalTo: header.bottomAnchor),
            header.heightAnchor.constraint(equalToConstant: 320),

            bigTitle.leadingAnchor.constraint(equalTo: headerGradient.leadingAnchor, constant: 24),
            bigTitle.trailingAnchor.constraint(equalTo: headerGradient.trailingAnchor, constant: -24),
            bigTitle.bottomAnchor.constraint(equalTo: subtitle.topAnchor, constant: -8),

            subtitle.leadingAnchor.constraint(equalTo: bigTitle.leadingAnchor),
            subtitle.trailingAnchor.constraint(equalTo: bigTitle.trailingAnchor),
            subtitle.bottomAnchor.constraint(equalTo: headerGradient.bottomAnchor, constant: -28)
        ])
        contentStack.addArrangedSubview(header)
    }

    private func setupBodyContent() {
        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        let inner = UIStackView.ba_make(axis: .vertical, spacing: 12)
        inner.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(inner)
        NSLayoutConstraint.activate([
            inner.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 16),
            inner.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 20),
            inner.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -20),
            inner.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -32)
        ])

        for i in 1...12 {
            let card = UIView()
            card.backgroundColor = BAAppTheme.card
            card.layer.cornerRadius = 14
            card.translatesAutoresizingMaskIntoConstraints = false
            card.heightAnchor.constraint(equalToConstant: 72).isActive = true

            let label = UILabel.ba_make(text: "示例内容 #\(i) · 用来让页面足够长以触发滚动",
                                        font: .ba_medium(14),
                                        color: BAAppTheme.textPrimary,
                                        numberOfLines: 2)
            label.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(label)
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
                label.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
                label.centerYAnchor.constraint(equalTo: card.centerYAnchor)
            ])
            inner.addArrangedSubview(card)
        }
        contentStack.addArrangedSubview(wrapper)
    }

    private func setupTopBackdrop() {
        topBackdrop.translatesAutoresizingMaskIntoConstraints = false
        topBackdrop.backgroundColor = BAAppTheme.background
        topBackdrop.alpha = 0
        view.addSubview(topBackdrop)
        NSLayoutConstraint.activate([
            topBackdrop.topAnchor.constraint(equalTo: view.topAnchor),
            topBackdrop.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBackdrop.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBackdrop.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ])

        // 自己画一个 nav 标题（随渐变淡入），用 BAAppTheme.textPrimary 颜色
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = BAAppTheme.textPrimary
        titleLabel.alpha = 0
        topBackdrop.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: topBackdrop.centerXAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: topBackdrop.bottomAnchor, constant: -10)
        ])
    }

    // MARK: - UIScrollViewDelegate

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateForScroll(scrollView.contentOffset.y)
    }

    private func updateForScroll(_ offsetY: CGFloat) {
        let progress = max(0, min(1, offsetY / fadeDistance))
        topBackdrop.alpha = progress
        titleLabel.alpha = progress
        // 滚到底部时 tint 也要变深，否则白色返回箭头在浅底上看不见
        navigationController?.navigationBar.tintColor = blend(.white, BAAppTheme.accent, ratio: progress)
    }

    private func blend(_ from: UIColor, _ to: UIColor, ratio: CGFloat) -> UIColor {
        var fr: CGFloat = 0, fg: CGFloat = 0, fb: CGFloat = 0, fa: CGFloat = 0
        var tr: CGFloat = 0, tg: CGFloat = 0, tb: CGFloat = 0, ta: CGFloat = 0
        from.getRed(&fr, green: &fg, blue: &fb, alpha: &fa)
        to.getRed(&tr, green: &tg, blue: &tb, alpha: &ta)
        return UIColor(red:   fr + (tr - fr) * ratio,
                       green: fg + (tg - fg) * ratio,
                       blue:  fb + (tb - fb) * ratio,
                       alpha: fa + (ta - fa) * ratio)
    }
}
