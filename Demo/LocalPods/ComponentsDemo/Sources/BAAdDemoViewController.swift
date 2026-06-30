//
//  BAAdDemoViewController.swift
//  ComponentsDemo
//
//  Created by boai on 2026/06/30.
//

import UIKit
import BASwiftKit
import SnapKit
import DemoCommon

/// 广告组件 Demo：跑马灯（滚动文字）+ 图片轮播广告。
///
/// 演示：自定义网络图片 + 占位图 + 文案 + 时间设置 + 自动重复 + 自定义指示器 + 点击回调。
public final class BAAdDemoViewController: BABaseViewController {

    private let scroll = UIScrollView()
    private let content = UIStackView()

    private let marquee = BAMarqueeView()
    private let carousel = BACarouselView()

    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        configureMarquee()
        configureCarousel()
    }

    // MARK: - Layout

    private func setupLayout() {
        scroll.alwaysBounceVertical = true
        view.addSubview(scroll)
        scroll.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        content.axis = .vertical
        content.spacing = 16
        content.isLayoutMarginsRelativeArrangement = true
        content.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 24, right: 16)
        scroll.addSubview(content)
        content.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        content.addArrangedSubview(sectionTitle("跑马灯 / Marquee"))
        marquee.backgroundColor = UIColor.black.withAlphaComponent(0.04)
        marquee.layer.cornerRadius = 8
        content.addArrangedSubview(marquee)
        marquee.snp.makeConstraints { make in make.height.equalTo(36) }

        content.addArrangedSubview(sectionTitle("图片轮播广告 / Carousel"))
        content.addArrangedSubview(carousel)
        carousel.layer.cornerRadius = 12
        carousel.clipsToBounds = true
        carousel.snp.makeConstraints { make in make.height.equalTo(180) }
    }

    private func sectionTitle(_ text: String) -> UILabel {
        UILabel.ba_make(text: text,
                        font: .systemFont(ofSize: 16, weight: .semibold),
                        color: BAAppTheme.textPrimary)
    }

    // MARK: - Marquee

    private func configureMarquee() {
        marquee.texts = ["🔥 限时 5 折抢购", "🎁 新人专享 20 元券", "🚚 全场包邮到家", "⭐️ 好评返现进行中"]
        marquee.font = .systemFont(ofSize: 14, weight: .medium)
        marquee.textColor = BAAppTheme.accent
        marquee.scrollSpeed = 60          // 点/秒
        marquee.isRepeatEnabled = true    // 自动重复
        marquee.onTap = { BAToast.ba_show("点击了跑马灯广告") }
    }

    // MARK: - Carousel

    private func configureCarousel() {
        // 占位图（灰色）。
        carousel.placeholder = Self.placeholderImage(size: CGSize(width: 16, height: 9), color: UIColor(white: 0.92, alpha: 1))
        carousel.autoScrollInterval = 3   // 时间设置
        carousel.isLoopEnabled = true     // 自动重复
        carousel.imageContentMode = .scaleAspectFill

        // 自定义指示器：白色、当前页拉伸为胶囊。
        let pageControl = BACarouselPageControl()
        pageControl.pageColor = UIColor.white.withAlphaComponent(0.5)
        pageControl.currentPageColor = .white
        pageControl.dotSize = 6
        pageControl.currentDotWidth = 16
        pageControl.dotSpacing = 6
        carousel.indicator = pageControl

        carousel.onSelect = { index in BAToast.ba_show("点击了第 \(index + 1) 张广告") }

        // 自定义网络图片 + 文案。
        let seeds = ["baswiftkit1", "baswiftkit2", "baswiftkit3", "baswiftkit4"]
        let captions = ["夏日大促 全场 5 折", "新品首发 限量发售", "会员日 专属福利", "周末狂欢 满 300 减 50"]
        let items: [BACarouselItem] = zip(seeds, captions).compactMap { seed, caption in
            guard let url = URL(string: "https://picsum.photos/seed/\(seed)/900/400") else { return nil }
            return BACarouselItem(url: url, caption: caption)
        }
        carousel.setItems(items)
    }

    /// 生成纯色占位图。
    private static func placeholderImage(size: CGSize, color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }
}
