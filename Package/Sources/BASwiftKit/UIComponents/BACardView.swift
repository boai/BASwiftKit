//
//  BACardView.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

#if canImport(UIKit)
import UIKit
import SnapKit

/// 带圆角、阴影的卡片容器。内部有一个 `contentView` 用于挂子视图。
public final class BACardView: UIView {

    /// 内容容器，业务子视图应添加到这里而不是直接添加到卡片本身。
    public let contentView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()

    /// 卡片背景色
    public var ba_cardColor: UIColor = .secondarySystemBackground {
        didSet {
            backgroundColor = ba_cardColor
            shadowContainer.backgroundColor = ba_cardColor
        }
    }

    /// 圆角
    public var ba_cornerRadius: CGFloat = 14 {
        didSet { shadowContainer.layer.cornerRadius = ba_cornerRadius; layer.cornerRadius = ba_cornerRadius }
    }

    /// 阴影内容容器：单独承担 shadow，避免和 masksToBounds 冲突
    private let shadowContainer: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }()

    /// 代码创建卡片容器。
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
        layer.cornerCurve = .continuous
        layer.masksToBounds = true

        addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    /// 加入父视图后同步创建阴影承载层。
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        // 把 shadow 加在父视图层级，避免被 masksToBounds 截断
        guard let parent = superview, shadowContainer.superview == nil else { return }
        parent.insertSubview(shadowContainer, belowSubview: self)
        shadowContainer.layer.cornerRadius = ba_cornerRadius
        shadowContainer.layer.cornerCurve = .continuous
        shadowContainer.layer.shadowColor = UIColor.black.cgColor
        shadowContainer.layer.shadowOpacity = 0.08
        shadowContainer.layer.shadowRadius = 18
        shadowContainer.layer.shadowOffset = CGSize(width: 0, height: 10)
        shadowContainer.backgroundColor = ba_cardColor

        shadowContainer.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }
}
#endif
