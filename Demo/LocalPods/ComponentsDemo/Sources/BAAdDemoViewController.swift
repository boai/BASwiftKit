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
    private let noticeSingle = BANoticeView()
    private let noticeDouble = BANoticeView()

    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        configureMarquee()
        configureCarousel()
        configureNotice()
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

        content.addArrangedSubview(sectionTitle("垂直公告 / Notice（单行 · 每次滚 1 行）"))
        noticeSingle.backgroundColor = UIColor.black.withAlphaComponent(0.04)
        noticeSingle.layer.cornerRadius = 8
        noticeSingle.clipsToBounds = true
        content.addArrangedSubview(noticeSingle)

        content.addArrangedSubview(sectionTitle("垂直公告 / Notice（双行 · 每次滚 1 行）"))
        noticeDouble.backgroundColor = UIColor.black.withAlphaComponent(0.04)
        noticeDouble.layer.cornerRadius = 8
        noticeDouble.clipsToBounds = true
        content.addArrangedSubview(noticeDouble)
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
        marquee.onTap = { index, text in BAToast.ba_show("点击了第 \(index + 1) 条：\(text)") }
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

    // MARK: - Notice

    private func configureNotice() {
        let notices = ["🎉 恭喜张同学获得 100 元红包",
                       "📦 您的订单已发货，请注意查收",
                       "🔔 限时秒杀进行中，手慢无",
                       "💎 会员日专属福利已到账",
                       "🚀 新版本上线，体验更流畅"]
        let font = UIFont.systemFont(ofSize: 14, weight: .medium)
        let tap: (Int, String) -> Void = { index, text in
            BAToast.ba_show("点击了第 \(index + 1) 条：\(text)")
        }

        // 单行：显示 1 行，每次滚 1 行（经典公告轮播）。
        noticeSingle.texts = notices
        noticeSingle.font = font
        noticeSingle.textColor = BAAppTheme.accent
        noticeSingle.visibleLines = 1
        noticeSingle.stepLines = 1
        noticeSingle.autoScrollInterval = 2.5
        noticeSingle.lineSpacing = 8
        noticeSingle.onTap = tap

        // 双行：显示 2 行，每次滚 1 行（错位上移，同屏显两条）。
        noticeDouble.texts = notices
        noticeDouble.font = font
        noticeDouble.textColor = BAAppTheme.accent
        noticeDouble.visibleLines = 2
        noticeDouble.stepLines = 1
        noticeDouble.autoScrollInterval = 2.5
        noticeDouble.lineSpacing = 8
        noticeDouble.onTap = tap
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
