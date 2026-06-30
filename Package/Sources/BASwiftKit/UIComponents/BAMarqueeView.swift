//
//  BAMarqueeView.swift
//  BASwiftKit
//
//  Created by boai on 2026/06/30.
//

#if canImport(UIKit)
import UIKit

/// 跑马灯（横向滚动文字广告）组件。
///
/// 用 `CABasicAnimation` 驱动（GPU 合成，**高性能**），双副本实现无缝循环；离屏自动暂停、回屏恢复，省电。
/// 自包含、仅依赖 UIKit，**低耦合**。
///
/// ## 接入（简单）
///
/// ```swift
/// let marquee = BAMarqueeView()
/// marquee.texts = ["限时 5 折", "新人专享券", "包邮到家"]   // 多条用分隔符串接
/// marquee.scrollSpeed = 60        // 点/秒，时间设置
/// marquee.isRepeatEnabled = true  // 自动重复
/// marquee.onTap = { index, text in print("点击第 \(index + 1) 条：\(text)") }
/// // 加入视图层级、设好 frame 后自动开始；也可手动 start/stop。
/// ```
public final class BAMarqueeView: UIView {

    // MARK: Public Configuration

    /// 滚动文案（单条）。设置后等价于 `texts = [text]`。
    public var text: String? {
        get { texts.first }
        set { texts = newValue.map { [$0] } ?? [] }
    }

    /// 滚动文案（多条，按 `separator` 串接为一条连续内容）。
    public var texts: [String] = [] { didSet { rebuild() } }

    /// 多条文案之间的分隔串。默认若干空格 + 圆点。
    public var separator: String = "        •        " { didSet { rebuild() } }

    /// 字体。
    public var font: UIFont = .systemFont(ofSize: 14) { didSet { rebuild() } }

    /// 文字颜色。
    public var textColor: UIColor = .label { didSet { applyTextAttributes() } }

    /// 滚动速度（点/秒）。默认 60。值越大越快。
    public var scrollSpeed: CGFloat = 60 { didSet { restart() } }

    /// 是否自动重复（无缝循环）。`false` 时仅滚动一遍后停止。默认 `true`。
    public var isRepeatEnabled: Bool = true { didSet { restart() } }

    /// 循环时两段内容之间的间隔（点）。默认 40。
    public var loopSpacing: CGFloat = 40 { didSet { rebuild() } }

    /// 点击回调，回传当前命中的文案索引与文本。
    ///
    /// 连续滚动下，若点击落在两条文案之间的分隔区域，回传距离最近的一条。
    public var onTap: ((_ index: Int, _ text: String) -> Void)?

    // MARK: Private

    private let trackLayer = CALayer()
    private let label = UILabel()
    private let labelCopy = UILabel()   // 仅循环模式使用
    private var contentWidth: CGFloat = 0
    /// 各条文案在串接内容中的横向区间，用于点击命中判定（与过滤空串后的 texts 一一对应）。
    private var itemRanges: [(start: CGFloat, end: CGFloat)] = []
    private var isAnimating = false
    /// 上次实际布局所依据的尺寸与内容宽度，用于跳过无几何变化的 layout，避免动画被反复重启而抖动。
    private var lastLaidOutSize: CGSize = .zero
    private var lastLaidOutContentWidth: CGFloat = -1

    private static let animationKey = "ba_marquee_scroll"

    // MARK: Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        clipsToBounds = true
        layer.addSublayer(trackLayer)
        [label, labelCopy].forEach {
            $0.font = font
            $0.textColor = textColor
            trackLayer.addSublayer($0.layer)
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
    }

    // MARK: Public Control

    /// 开始滚动。
    public func startScrolling() {
        startAnimationIfPossible()
    }

    /// 停止滚动。
    public func stopScrolling() {
        isAnimating = false
        trackLayer.removeAnimation(forKey: Self.animationKey)
    }

    // MARK: Build & Layout

    private var composedText: String {
        texts.filter { !$0.isEmpty }.joined(separator: separator)
    }

    private func rebuild() {
        let content = composedText
        label.text = content
        labelCopy.text = content
        applyTextAttributes()

        // 单段内容宽度（文字 + 循环间隔）。
        let textWidth = (content as NSString).size(withAttributes: [.font: font]).width
        contentWidth = ceil(textWidth) + loopSpacing

        // 记录各条文案的横向区间，供点击命中判定。
        itemRanges = buildItemRanges()

        // 仅标记需要重新布局；真正的重排与动画重启交给 layoutSubviews（按几何变化判定），
        // 避免这里直接 restart 与随后的 layout 重复重启。
        setNeedsLayout()
    }

    /// 计算各条文案（过滤空串）在串接内容中的横向 [start, end) 区间。
    private func buildItemRanges() -> [(start: CGFloat, end: CGFloat)] {
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        let sepWidth = (separator as NSString).size(withAttributes: attrs).width
        var ranges: [(start: CGFloat, end: CGFloat)] = []
        var x: CGFloat = 0
        for text in texts where !text.isEmpty {
            let w = (text as NSString).size(withAttributes: attrs).width
            ranges.append((x, x + w))
            x += w + sepWidth
        }
        return ranges
    }

    private func applyTextAttributes() {
        [label, labelCopy].forEach {
            $0.font = font
            $0.textColor = textColor
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        // 几何（尺寸或内容宽度）未变则跳过：避免父级高频 layout 导致动画被反复 stop/start 而跳回起点抖动。
        guard bounds.size != lastLaidOutSize || contentWidth != lastLaidOutContentWidth else { return }
        lastLaidOutSize = bounds.size
        lastLaidOutContentWidth = contentWidth

        let height = bounds.height
        // label 垂直居中，宽度为单段内容宽。
        label.frame = CGRect(x: 0, y: 0, width: contentWidth, height: height)
        labelCopy.frame = CGRect(x: contentWidth, y: 0, width: contentWidth, height: height)
        // 关闭隐式动画地复位 trackLayer 起点。
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        trackLayer.frame = CGRect(x: 0, y: 0, width: contentWidth * 2, height: height)
        trackLayer.position = CGPoint(x: contentWidth, y: height / 2)
        CATransaction.commit()
        restart()
    }

    // MARK: Animation

    private func restart() {
        // 条件不满足时 startAnimationIfPossible 内部会拦截，这里直接 stop+start 即可。
        stopScrolling()
        startAnimationIfPossible()
    }

    private func startAnimationIfPossible() {
        guard window != nil, bounds.width > 0, contentWidth > 0, !composedText.isEmpty, scrollSpeed > 0 else { return }

        labelCopy.isHidden = !isRepeatEnabled
        let startX = contentWidth                              // layoutSubviews 设定的初始 position.x
        let animation = CABasicAnimation(keyPath: "position.x")

        if isRepeatEnabled {
            // 无缝循环：整体左移一个「单段宽度」，第二副本顶上，循环往复。
            animation.fromValue = startX
            animation.toValue = startX - contentWidth
            animation.duration = CFTimeInterval(contentWidth / scrollSpeed)
            animation.repeatCount = .infinity
        } else {
            // 单次：从完全在右侧屏外滚到完全离开左侧屏外，结束后停住。
            let distance = bounds.width + contentWidth
            animation.fromValue = bounds.width + contentWidth / 2
            animation.toValue = bounds.width + contentWidth / 2 - distance
            animation.duration = CFTimeInterval(distance / scrollSpeed)
            animation.repeatCount = 1
            animation.isRemovedOnCompletion = false
            animation.fillMode = .forwards
        }
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        trackLayer.add(animation, forKey: Self.animationKey)
        isAnimating = true
    }

    // MARK: Lifecycle（离屏自动暂停）

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window == nil {
            stopScrolling()
        } else {
            startAnimationIfPossible()
        }
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let (index, text) = hitTestItem(at: gesture.location(in: self)) ?? (-1, "")
        onTap?(index, text)
    }

    /// 根据点击位置反推命中的文案。
    ///
    /// - 原理：label 静止于 trackLayer 内 `frame.x = 0`，trackLayer 随动画整体左移；
    ///   点击点在 label 内容坐标的 `x = point.x - trackLayer.origin.x`；循环模式下 label
    ///   为双副本、周期为 `contentWidth`，对该 x 取模；最后在 `itemRanges` 中查命中或最近条。
    private func hitTestItem(at point: CGPoint) -> (index: Int, text: String)? {
        let effective = texts.filter { !$0.isEmpty }
        guard !effective.isEmpty else { return nil }
        guard !itemRanges.isEmpty, itemRanges.count == effective.count else {
            return (0, effective[0])
        }

        // 取 trackLayer 当前显示位置（动画中用 presentation layer，否则 model layer）。
        let trackOriginX = (trackLayer.presentation()?.frame ?? trackLayer.frame).origin.x
        var rawX = point.x - trackOriginX

        // 循环模式按 contentWidth 取模；非循环模式下 rawX 可能超出内容范围，clamp 到最近条即可。
        if isRepeatEnabled, contentWidth > 0 {
            rawX = rawX.truncatingRemainder(dividingBy: contentWidth)
            if rawX < 0 { rawX += contentWidth }
        }

        // 命中区间优先；落在分隔/间隔区域则取最近一条。
        if let hit = itemRanges.firstIndex(where: { rawX >= $0.start && rawX < $0.end }) {
            return (hit, effective[hit])
        }
        let nearest = itemRanges.enumerated().min(by: { lhs, rhs in
            distance(rawX, to: lhs.element) < distance(rawX, to: rhs.element)
        })?.offset ?? 0
        return (nearest, effective[nearest])
    }

    /// 点到区间端点的最短距离（区间内为 0），用于「最近条」判定。
    private func distance(_ x: CGFloat, to range: (start: CGFloat, end: CGFloat)) -> CGFloat {
        if x < range.start { return range.start - x }
        if x > range.end { return x - range.end }
        return 0
    }
}
#endif
