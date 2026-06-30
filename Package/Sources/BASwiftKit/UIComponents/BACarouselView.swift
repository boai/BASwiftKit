//
//  BACarouselView.swift
//  BASwiftKit
//
//  Created by boai on 2026/06/30.
//

#if canImport(UIKit)
import UIKit

// MARK: - Item

/// 轮播单元数据。
public struct BACarouselItem {

    /// 图片来源：本地图片或网络 URL。
    public enum Source {
        case image(UIImage)
        case url(URL)
    }

    /// 图片来源。
    public let source: Source
    /// 文案（可选）。非空时在底部叠加显示。
    public let caption: String?

    /// 用本地图片创建。
    public init(image: UIImage, caption: String? = nil) {
        self.source = .image(image)
        self.caption = caption
    }

    /// 用网络图片 URL 创建。
    public init(url: URL, caption: String? = nil) {
        self.source = .url(url)
        self.caption = caption
    }
}

// MARK: - Carousel View

/// 图片轮播广告组件。
///
/// 基于 `UICollectionView`（cell 复用，**高性能**），支持无限循环、自动滚动、网络图片 + 占位图、
/// 底部文案与可自定义指示器。离屏自动暂停定时器，省电。
///
/// ## 接入（简单）
///
/// ```swift
/// let banner = BACarouselView()
/// banner.placeholder = UIImage(named: "placeholder")
/// banner.autoScrollInterval = 3        // 时间设置；0 表示不自动滚动
/// banner.isLoopEnabled = true          // 自动重复
/// banner.onSelect = { index in print("点击第 \(index) 个") }
/// banner.setItems([
///     BACarouselItem(url: URL(string: "https://.../1.jpg")!, caption: "夏日大促"),
///     BACarouselItem(image: localImage, caption: "新品上市")
/// ])
/// ```
///
/// ## 自定义
/// - 网络图片加载：默认 ``BADefaultImageLoader``，可设 `imageLoader` 接入 Kingfisher 等。
/// - 指示器：默认 ``BACarouselPageControl``，可设 `indicator` 替换为任意 ``BACarouselIndicator``。
/// - 文案样式：`captionFont` / `captionTextColor` / `captionBackgroundColor`。
public final class BACarouselView: UIView {

    // MARK: Public Configuration

    /// 自动滚动间隔（秒）。`<= 0` 表示不自动滚动。默认 3。
    public var autoScrollInterval: TimeInterval = 3 { didSet { restartAutoScrollIfNeeded() } }

    /// 是否无限循环（同时决定自动滚动到尾页后是否回到首页）。默认 `true`。
    public var isLoopEnabled: Bool = true { didSet { reload() } }

    /// 占位图，网络图片加载完成前展示。
    public var placeholder: UIImage?

    /// 图片填充模式，默认 `.scaleAspectFill`。
    public var imageContentMode: UIView.ContentMode = .scaleAspectFill

    /// 网络图片加载器（解耦点），默认内置 ``BADefaultImageLoader``。
    public var imageLoader: BARemoteImageLoading = BADefaultImageLoader.shared

    /// 点击某一项的回调，参数为**真实索引**（`0..<items.count`）。
    public var onSelect: ((Int) -> Void)?

    /// 是否显示指示器，默认 `true`。
    public var showsIndicator: Bool = true { didSet { indicatorView?.isHidden = !showsIndicator } }

    /// 文案字体。
    public var captionFont: UIFont = .systemFont(ofSize: 13, weight: .medium)
    /// 文案颜色。
    public var captionTextColor: UIColor = .white
    /// 文案背景色（默认半透明黑，提升可读性）。
    public var captionBackgroundColor: UIColor = UIColor.black.withAlphaComponent(0.3)

    /// 指示器（可自定义）。默认惰性创建 ``BACarouselPageControl``。设置后替换。
    public var indicator: BACarouselIndicator? {
        didSet { swapIndicator(old: oldValue) }
    }

    // MARK: Private State

    private var items: [BACarouselItem] = []
    /// 循环倍数：真实数据被放大若干倍以模拟无限滚动，中部起步、临界回中。
    private let loopMultiplier = 400
    private var autoScrollTimer: Timer?
    /// 是否已完成首次「归位中部」。用于区分首次有效布局与后续尺寸变化。
    private var didPerformInitialScroll = false

    private lazy var flowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        return layout
    }()

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.backgroundColor = .clear
        cv.dataSource = self
        cv.delegate = self
        cv.register(BACarouselCell.self, forCellWithReuseIdentifier: BACarouselCell.reuseID)
        if #available(iOS 11.0, *) { cv.contentInsetAdjustmentBehavior = .never }
        return cv
    }()

    private var indicatorView: UIView?

    // MARK: Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    deinit {
        autoScrollTimer?.invalidate()
    }

    private func setup() {
        addSubview(collectionView)
        // 默认指示器。
        let pageControl = BACarouselPageControl()
        indicator = pageControl
    }

    // MARK: Public API

    /// 设置轮播数据并刷新。
    public func setItems(_ items: [BACarouselItem]) {
        self.items = items
        reload()
    }

    /// 刷新当前数据、重置到首页并按需重启自动滚动。
    public func reload() {
        collectionView.reloadData()
        indicator?.ba_updateNumberOfPages(items.count)
        indicator?.ba_updateCurrentPage(0)
        didPerformInitialScroll = false
        setNeedsLayout()
        layoutIfNeeded()
        scrollToInitialPositionIfNeeded()
        restartAutoScrollIfNeeded()
    }

    // MARK: Layout

    public override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.frame = bounds

        guard bounds.width > 0, bounds.height > 0 else { layoutIndicator(); return }

        // 每页等于自身尺寸；尺寸变化时同步并保持当前页。
        if flowLayout.itemSize != bounds.size {
            let page = currentRawIndex
            flowLayout.itemSize = bounds.size
            flowLayout.invalidateLayout()
            collectionView.layoutIfNeeded()
            if didPerformInitialScroll {
                scrollToRawIndex(page, animated: false)
            }
        }
        // 首次获得有效尺寸时归位到中部（修复 setItems 在布局前调用导致起始停在 raw 0、无法左滑）。
        if !didPerformInitialScroll {
            scrollToInitialPositionIfNeeded()
        }

        layoutIndicator()
    }

    private func layoutIndicator() {
        guard let indicatorView = indicatorView else { return }
        let height: CGFloat = 20
        indicatorView.frame = CGRect(x: 0, y: bounds.height - height - 8, width: bounds.width, height: height)
    }

    // MARK: Window lifecycle（离屏自动暂停，省电）

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            stopAutoScroll()
        } else {
            restartAutoScrollIfNeeded()
        }
    }
}

// MARK: - Infinite Loop Helpers

private extension BACarouselView {

    /// 集合视图实际 item 数（循环时放大）。
    var numberOfRawItems: Int {
        guard items.count > 1, isLoopEnabled else { return items.count }
        return items.count * loopMultiplier
    }

    /// 循环时的中部起始索引。
    var middleRawIndex: Int {
        guard items.count > 1, isLoopEnabled else { return 0 }
        return items.count * (loopMultiplier / 2)
    }

    /// 当前所处的「原始」item 索引（基于 contentOffset 计算）。
    var currentRawIndex: Int {
        let width = collectionView.bounds.width
        guard width > 0 else { return middleRawIndex }
        return Int(round(collectionView.contentOffset.x / width))
    }

    /// 当前真实页（`0..<items.count`）。
    var currentRealPage: Int {
        guard items.count > 0 else { return 0 }
        return ((currentRawIndex % items.count) + items.count) % items.count
    }

    func scrollToInitialPositionIfNeeded() {
        guard numberOfRawItems > 0, collectionView.bounds.width > 0 else { return }
        scrollToRawIndex(middleRawIndex, animated: false)
        didPerformInitialScroll = true
    }

    func scrollToRawIndex(_ index: Int, animated: Bool) {
        guard index >= 0, index < numberOfRawItems, collectionView.bounds.width > 0 else { return }
        collectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: animated)
    }

    /// 滚动停止后：把临界位置（接近两端）悄悄回中，维持无限滚动且索引有界。
    func recenterIfNeeded() {
        guard items.count > 1, isLoopEnabled else { return }
        let index = currentRawIndex
        if index < items.count || index >= items.count * (loopMultiplier - 1) {
            let recentered = currentRealPage + middleRawIndex
            scrollToRawIndex(recentered, animated: false)
        }
    }
}

// MARK: - Auto Scroll

private extension BACarouselView {

    func restartAutoScrollIfNeeded() {
        stopAutoScroll()
        guard autoScrollInterval > 0, items.count > 1, window != nil else { return }
        // 用 Timer 驱动，离屏/拖拽时暂停。
        let timer = Timer(timeInterval: autoScrollInterval, repeats: true) { [weak self] _ in
            self?.autoScrollNext()
        }
        RunLoop.main.add(timer, forMode: .common)
        autoScrollTimer = timer
    }

    func stopAutoScroll() {
        autoScrollTimer?.invalidate()
        autoScrollTimer = nil
    }

    func autoScrollNext() {
        guard numberOfRawItems > 1, collectionView.bounds.width > 0 else { return }
        let next = currentRawIndex + 1
        if next < numberOfRawItems {
            scrollToRawIndex(next, animated: true)
        } else if isLoopEnabled {
            // 理论上回中机制使此分支基本不触发；兜底回到中部首页。
            scrollToRawIndex(middleRawIndex, animated: false)
        }
        // 非循环且已到末页：保持不动（自动滚动到此自然停在最后一页）。
    }
}

// MARK: - DataSource & Delegate

extension BACarouselView: UICollectionViewDataSource, UICollectionViewDelegate {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        numberOfRawItems
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BACarouselCell.reuseID, for: indexPath) as! BACarouselCell
        guard !items.isEmpty else { return cell }
        let item = items[indexPath.item % items.count]
        cell.configure(item: item,
                       placeholder: placeholder,
                       contentMode: imageContentMode,
                       captionFont: captionFont,
                       captionTextColor: captionTextColor,
                       captionBackgroundColor: captionBackgroundColor,
                       imageLoader: imageLoader)
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !items.isEmpty else { return }
        onSelect?(indexPath.item % items.count)
    }

    // 拖拽时暂停自动滚动，松手后恢复。
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        stopAutoScroll()
    }

    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            scrollViewDidEndDecelerating(scrollView)
        }
    }

    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        indicator?.ba_updateCurrentPage(currentRealPage)
        recenterIfNeeded()
        restartAutoScrollIfNeeded()
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        indicator?.ba_updateCurrentPage(currentRealPage)
        recenterIfNeeded()
    }
}

// MARK: - Indicator Swap

private extension BACarouselView {
    func swapIndicator(old: BACarouselIndicator?) {
        old?.ba_view.removeFromSuperview()
        indicatorView = indicator?.ba_view
        if let indicatorView = indicatorView {
            indicatorView.isHidden = !showsIndicator
            addSubview(indicatorView)
            indicator?.ba_updateNumberOfPages(items.count)
            indicator?.ba_updateCurrentPage(currentRealPage)
            layoutIndicator()
        }
    }
}

// MARK: - Cell

/// 轮播单元格：图片 + 可选底部文案。内部类型。
final class BACarouselCell: UICollectionViewCell {

    static let reuseID = "BACarouselCell"

    private let imageView = UIImageView()
    private let captionLabel = UILabel()
    private let captionBar = UIView()
    private var imageLoader: BARemoteImageLoading?

    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)

        captionBar.isHidden = true
        contentView.addSubview(captionBar)

        captionLabel.numberOfLines = 1
        captionBar.addSubview(captionLabel)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = contentView.bounds
        let barHeight: CGFloat = 32
        captionBar.frame = CGRect(x: 0, y: contentView.bounds.height - barHeight,
                                  width: contentView.bounds.width, height: barHeight)
        captionLabel.frame = captionBar.bounds.insetBy(dx: 12, dy: 0)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        // 复用前取消在途网络加载，避免错图。
        imageLoader?.ba_cancelLoad(for: imageView)
        imageView.image = nil
        captionBar.isHidden = true
    }

    func configure(item: BACarouselItem,
                   placeholder: UIImage?,
                   contentMode: UIView.ContentMode,
                   captionFont: UIFont,
                   captionTextColor: UIColor,
                   captionBackgroundColor: UIColor,
                   imageLoader: BARemoteImageLoading) {
        self.imageLoader = imageLoader
        imageView.contentMode = contentMode

        switch item.source {
        case .image(let image):
            imageView.image = image
        case .url(let url):
            imageLoader.ba_loadImage(from: url, into: imageView, placeholder: placeholder)
        }

        if let caption = item.caption, !caption.isEmpty {
            captionBar.isHidden = false
            captionBar.backgroundColor = captionBackgroundColor
            captionLabel.text = caption
            captionLabel.font = captionFont
            captionLabel.textColor = captionTextColor
        } else {
            captionBar.isHidden = true
        }
    }
}
#endif
