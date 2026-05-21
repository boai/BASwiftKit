//
//  BACardView.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

#if canImport(UIKit)
import UIKit

/// 带圆角、阴影的卡片容器。内部有一个 `contentView` 用于挂子视图。
public final class BACardView: UIView {

    public let contentView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    /// 卡片背景色
    public var ba_cardColor: UIColor = .secondarySystemBackground {
        didSet { backgroundColor = ba_cardColor }
    }

    /// 圆角
    public var ba_cornerRadius: CGFloat = 14 {
        didSet { shadowContainer.layer.cornerRadius = ba_cornerRadius; layer.cornerRadius = ba_cornerRadius }
    }

    /// 阴影内容容器：单独承担 shadow，避免和 masksToBounds 冲突
    private let shadowContainer: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .clear
        return v
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = ba_cardColor
        layer.cornerRadius = ba_cornerRadius
        layer.masksToBounds = true

        addSubview(contentView)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        // 把 shadow 加在父视图层级，避免被 masksToBounds 截断
        guard let parent = superview, shadowContainer.superview == nil else { return }
        parent.insertSubview(shadowContainer, belowSubview: self)
        shadowContainer.layer.cornerRadius = ba_cornerRadius
        shadowContainer.layer.shadowColor = UIColor.black.cgColor
        shadowContainer.layer.shadowOpacity = 0.10
        shadowContainer.layer.shadowRadius = 12
        shadowContainer.layer.shadowOffset = CGSize(width: 0, height: 6)
        shadowContainer.backgroundColor = ba_cardColor

        NSLayoutConstraint.activate([
            shadowContainer.topAnchor.constraint(equalTo: topAnchor),
            shadowContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            shadowContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            shadowContainer.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
}
#endif
