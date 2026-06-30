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
/// marquee.onTap = { print("点击跑马灯") }
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

    /// 点击回调。
    public var onTap: (() -> Void)?

    // MARK: Private

    private let trackLayer = CALayer()
    private let label = UILabel()
    private let labelCopy = UILabel()   // 仅循环模式使用
    private var contentWidth: CGFloat = 0
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
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
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
        // 仅标记需要重新布局；真正的重排与动画重启交给 layoutSubviews（按几何变化判定），
        // 避免这里直接 restart 与随后的 layout 重复重启。
        setNeedsLayout()
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

    @objc private func handleTap() {
        onTap?()
    }
}
#endif
