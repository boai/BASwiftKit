//
//  BANoticeView.swift
//  BASwiftKit
//
//  Created by boai on 2026/06/30.
//

#if canImport(UIKit)
import UIKit

// MARK: - Notice View

/// 垂直滚动公告组件（电商首页公告轮播样式）。
///
/// 基于 `UICollectionView`（cell 复用，**高性能**），支持无限循环、自动向上滚动、
/// 「显示 N 行 / 每次滚动 M 行」可配置，点击精确回传命中的那条文案。离屏自动暂停定时器，省电。
///
/// 与横向的 ``BAMarqueeView``（连续滚动整条文本）不同，本组件是**逐条步进**——
/// 每条文案独占一行（超长截断），每隔 `autoScrollInterval` 秒向上滚动 `stepLines` 行，
/// 因此「点击哪条」可由 cell 自带的索引精确给出，无需反推。
///
/// ## 接入（简单）
///
/// ```swift
/// let notice = BANoticeView()
/// notice.texts = ["🎉 恭喜张同学获得 100 元红包", "📦 您的订单已发货", "🔔 限时秒杀进行中"]
/// notice.visibleLines = 1        // 显示 1 行（设 2 则同屏显示 2 行）
/// notice.stepLines = 1           // 每次上滚 1 行
/// notice.autoScrollInterval = 3  // 3 秒滚动一次；<=0 不自动滚动
/// notice.onTap = { index, text in print("点击第 \(index + 1) 条：\(text)") }
/// // 加入视图层级即可；组件高度由 visibleLines 自动决定（intrinsicContentSize）。
/// ```
public final class BANoticeView: UIView {

    // MARK: Public Configuration

    /// 公告文案（每条独占一行，超长尾部截断）。设置后刷新。
    public var texts: [String] = [] { didSet { reload() } }

    /// 字体。默认 14pt 系统。
    public var font: UIFont = .systemFont(ofSize: 14) {
        didSet {
            invalidateIntrinsicContentSize()
            reload()
        }
    }

    /// 文字颜色。
    public var textColor: UIColor = .label { didSet { collectionView.reloadData() } }

    /// 可视行数：1 或 2（决定组件高度）。默认 1。小于 1 按 1 处理。
    public var visibleLines: Int = 1 {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    /// 每次自动上滚的行数：1 或 2。默认 1。小于 1 按 1 处理。
    public var stepLines: Int = 1

    /// 行高额外间距（点），叠加在字体行高之上。默认 0。
    public var lineSpacing: CGFloat = 0 {
        didSet {
            invalidateIntrinsicContentSize()
            setNeedsLayout()
        }
    }

    /// 自动滚动间隔（秒）。`<= 0` 表示不自动滚动。默认 3。
    public var autoScrollInterval: TimeInterval = 3 { didSet { restartAutoScrollIfNeeded() } }

    /// 是否无限循环（决定滚到末尾后是否回到中部循环）。默认 `true`。
    public var isLoopEnabled: Bool = true { didSet { reload() } }

    /// 点击某一条的回调，参数为**真实索引**（`0..<texts.count`）与对应文案。
    public var onTap: ((_ index: Int, _ text: String) -> Void)?

    // MARK: Private State

    /// 循环倍数：真实数据被放大若干倍以模拟无限滚动，中部起步、临界回中。
    private let loopMultiplier = 400
    private var autoScrollTimer: Timer?
    /// 是否已完成首次「归位中部」。
    private var didPerformInitialScroll = false

    /// 单行 cell 高度 = 字体行高 + 行间距。
    private var cellHeight: CGFloat { ceil(font.lineHeight) + lineSpacing }

    private lazy var flowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        return layout
    }()

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        cv.isPagingEnabled = false
        cv.showsVerticalScrollIndicator = false
        cv.backgroundColor = .clear
        cv.dataSource = self
        cv.delegate = self
        cv.register(BANoticeCell.self, forCellWithReuseIdentifier: BANoticeCell.reuseID)
        if #available(iOS 11.0, *) { cv.contentInsetAdjustmentBehavior = .never }
        return cv
    }()

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
    }

    // MARK: Public API

    /// 刷新数据、重置到首条并按需重启自动滚动。
    public func reload() {
        collectionView.reloadData()
        didPerformInitialScroll = false
        setNeedsLayout()
        layoutIfNeeded()
        scrollToInitialPositionIfNeeded()
        restartAutoScrollIfNeeded()
    }

    // MARK: Layout

    public override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: CGFloat(max(1, visibleLines)) * cellHeight)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.frame = bounds

        guard bounds.width > 0, cellHeight > 0 else { return }

        // 每个 cell 宽度等于自身宽度、高度等于单行高度；尺寸变化时同步并保持当前行。
        let targetSize = CGSize(width: bounds.width, height: cellHeight)
        if flowLayout.itemSize != targetSize {
            let line = currentRawLine
            flowLayout.itemSize = targetSize
            flowLayout.invalidateLayout()
            collectionView.layoutIfNeeded()
            if didPerformInitialScroll {
                scrollToRawLine(line, animated: false)
            }
        }
        if !didPerformInitialScroll {
            scrollToInitialPositionIfNeeded()
        }
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

private extension BANoticeView {

    /// 集合视图实际 item 数（循环时放大）。
    var numberOfRawItems: Int {
        guard texts.count > 1, isLoopEnabled else { return texts.count }
        return texts.count * loopMultiplier
    }

    /// 循环时的中部起始索引。
    var middleRawIndex: Int {
        guard texts.count > 1, isLoopEnabled else { return 0 }
        return texts.count * (loopMultiplier / 2)
    }

    /// 当前所处的「原始」行索引（基于 contentOffset.y 计算）。
    var currentRawLine: Int {
        guard cellHeight > 0 else { return middleRawIndex }
        return Int(round(collectionView.contentOffset.y / cellHeight))
    }

    /// 当前真实条目（`0..<texts.count`）。
    var currentRealIndex: Int {
        guard texts.count > 0 else { return 0 }
        return ((currentRawLine % texts.count) + texts.count) % texts.count
    }

    func scrollToInitialPositionIfNeeded() {
        guard numberOfRawItems > 0, cellHeight > 0, bounds.height > 0 else { return }
        scrollToRawLine(middleRawIndex, animated: false)
        didPerformInitialScroll = true
    }

    func scrollToRawLine(_ line: Int, animated: Bool) {
        guard line >= 0, line < numberOfRawItems, cellHeight > 0 else { return }
        collectionView.scrollToItem(at: IndexPath(item: line, section: 0), at: .top, animated: animated)
    }

    /// 滚动停止后：把临界位置（接近两端）悄悄回中，维持无限滚动且索引有界。
    func recenterIfNeeded() {
        guard texts.count > 1, isLoopEnabled else { return }
        let line = currentRawLine
        if line < texts.count || line >= texts.count * (loopMultiplier - 1) {
            let recentered = currentRealIndex + middleRawIndex
            scrollToRawLine(recentered, animated: false)
        }
    }
}

// MARK: - Auto Scroll

private extension BANoticeView {

    func restartAutoScrollIfNeeded() {
        stopAutoScroll()
        guard autoScrollInterval > 0, texts.count > 1, window != nil else { return }
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
        guard numberOfRawItems > 1, cellHeight > 0 else { return }
        let step = max(1, stepLines)
        let next = currentRawLine + step
        if next < numberOfRawItems {
            scrollToRawLine(next, animated: true)
        } else if isLoopEnabled {
            scrollToRawLine(middleRawIndex, animated: false)
        }
    }
}

// MARK: - DataSource & Delegate

extension BANoticeView: UICollectionViewDataSource, UICollectionViewDelegate {

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        numberOfRawItems
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BANoticeCell.reuseID, for: indexPath) as! BANoticeCell
        guard !texts.isEmpty else { return cell }
        cell.configure(text: texts[indexPath.item % texts.count], font: font, textColor: textColor)
        return cell
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !texts.isEmpty else { return }
        let index = indexPath.item % texts.count
        onTap?(index, texts[index])
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
        recenterIfNeeded()
        restartAutoScrollIfNeeded()
    }

    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        recenterIfNeeded()
    }
}

// MARK: - Cell

/// 公告单元格：单行文案（超长截断）。内部类型。
final class BANoticeCell: UICollectionViewCell {

    static let reuseID = "BANoticeCell"

    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        contentView.addSubview(label)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 文字垂直居中于 cell。
        let h = ceil(label.font.lineHeight)
        label.frame = CGRect(x: 0,
                             y: (contentView.bounds.height - h) / 2,
                             width: contentView.bounds.width,
                             height: h)
    }

    func configure(text: String, font: UIFont, textColor: UIColor) {
        label.text = text
        label.font = font
        label.textColor = textColor
        setNeedsLayout()
    }
}
#endif
