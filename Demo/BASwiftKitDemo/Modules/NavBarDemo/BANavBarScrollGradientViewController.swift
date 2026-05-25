//
//  BANavBarScrollGradientViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit

/// 演示：进入时导航栏透明，向下滚动时背景与标题渐变到实色。
///
/// 关键设计：保留系统 navigationBar，只换它的 appearance。
/// - scrollEdgeAppearance = 透明：滚动到顶时 nav 完全透明，露出底下的橙色渐变。
/// - standardAppearance   = 实色：滚动离顶后 nav 切回 App 主背景色，显示标题。
/// iOS 会根据 scrollView.contentOffset 自动在两套 appearance 之间切换；
/// push/pop 时也会自动在「源页 appearance」和「目标页 appearance」之间做插值动画，
/// 所以页面和导航条会作为一个整体一起滑动，不会出现"nav 透明 + 下面是页面内容"
/// 的割裂感。tintColor 不走 appearance，所以这里跟着滚动手动插值一下。
final class BANavBarScrollGradientViewController: UIViewController, UIScrollViewDelegate {

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView.ba_make(axis: .vertical, spacing: 16)
    private let headerGradient = BAGradientView()

    /// 由透明到实色所需的滚动距离
    private let fadeDistance: CGFloat = 120

    /// 进入本页前 nav 的 tintColor，离开时还原回去
    private var savedTintColor: UIColor?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = BAAppTheme.background
        title = "滑动渐变"

        configureNavBarAppearance()
        setupScrollView()
        setupHeader()
        setupPushRow()
        setupBodyContent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // 进入本页：把当前 nav 的 tintColor 切到白色（覆盖在橙色渐变上才看得见返回箭头）。
        // 用 transitionCoordinator 跟着 push 动画一起插值，避免瞬切。
        savedTintColor = navigationController?.navigationBar.tintColor
        animateTint(to: .white, alongside: transitionCoordinator)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 离开本页：还原 tintColor，同样跟着 pop/push 动画一起做。
        let target = savedTintColor ?? BAAppTheme.accent
        animateTint(to: target, alongside: transitionCoordinator)
    }

    private func animateTint(to color: UIColor, alongside coordinator: UIViewControllerTransitionCoordinator?) {
        guard let bar = navigationController?.navigationBar else { return }
        if let coordinator {
            coordinator.animate(alongsideTransition: { _ in
                bar.tintColor = color
            }, completion: nil)
        } else {
            bar.tintColor = color
        }
    }

    // MARK: - Nav appearance

    private func configureNavBarAppearance() {
        let titleFont = UIFont.systemFont(ofSize: 17, weight: .semibold)

        // 顶端：完全透明，标题也是透明，露出橙色渐变
        let transparent = UINavigationBarAppearance()
        transparent.configureWithTransparentBackground()
        transparent.backgroundColor = .clear
        transparent.shadowColor = .clear
        transparent.titleTextAttributes = [
            .foregroundColor: UIColor.clear,
            .font: titleFont
        ]

        // 滚动后：App 主背景实色，标题用主文字色
        let solid = UINavigationBarAppearance()
        solid.configureWithOpaqueBackground()
        solid.backgroundColor = BAAppTheme.background
        solid.shadowColor = .clear
        solid.titleTextAttributes = [
            .foregroundColor: BAAppTheme.textPrimary,
            .font: titleFont
        ]

        navigationItem.scrollEdgeAppearance = transparent
        navigationItem.standardAppearance = solid
        navigationItem.compactAppearance = solid
    }

    // MARK: - 布局

    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        // 让内容从屏幕最顶端开始，橙色渐变才能延伸到 nav 后面
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
        let subtitle = UILabel.ba_make(text: "iOS 自动在透明 / 实色两套 nav appearance 之间过渡",
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

    private func setupPushRow() {
        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false

        let btn = UIButton.ba_make(title: "进入三级页面（普通 push）",
                                   titleColor: .white,
                                   backgroundColor: BAAppTheme.accent,
                                   font: .ba_semibold(15),
                                   cornerRadius: 12)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.heightAnchor.constraint(equalToConstant: 48).isActive = true
        btn.ba_onTap { [weak self] _ in
            let next = BANavBarLevel3ViewController()
            self?.navigationController?.pushViewController(next, animated: true)
        }
        wrapper.addSubview(btn)
        NSLayoutConstraint.activate([
            btn.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 16),
            btn.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 20),
            btn.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -20),
            btn.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor)
        ])
        contentStack.addArrangedSubview(wrapper)
    }

    private func setupBodyContent() {
        let wrapper = UIView()
        wrapper.translatesAutoresizingMaskIntoConstraints = false
        let inner = UIStackView.ba_make(axis: .vertical, spacing: 12)
        inner.translatesAutoresizingMaskIntoConstraints = false
        wrapper.addSubview(inner)
        NSLayoutConstraint.activate([
            inner.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 8),
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

    // MARK: - 滚动 → 返回箭头 tint 插值
    // 背景 / 标题颜色靠 iOS 在两套 appearance 之间自动切，这里只补一下 tintColor。

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let progress = max(0, min(1, scrollView.contentOffset.y / fadeDistance))
        navigationController?.navigationBar.tintColor =
            blend(.white, BAAppTheme.accent, ratio: progress)
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

// MARK: - 三级页面

/// 普通的三级页面：完全交给 BABaseViewController 的默认外观，
/// 用来演示「滑动渐变 → 普通 push」时 nav 样式如何自然过渡。
final class BANavBarLevel3ViewController: BABaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "三级页面"

        let label = UILabel.ba_make(
            text: "这是一个普通 push 出来的三级页面。\n返回上一页（滑动渐变）时 nav appearance 会和页面一起插值动画。",
            font: .ba_medium(15),
            color: BAAppTheme.textSecondary,
            alignment: .center,
            numberOfLines: 0
        )
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])
    }
}
