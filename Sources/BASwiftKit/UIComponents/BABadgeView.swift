//
//  BABadgeView.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

#if canImport(UIKit)
import UIKit

/// 自适应宽度的小角标。可用作分类标签 / 状态 chip。
public final class BABadgeView: UIView {

    private let label = UILabel()

    public var ba_text: String? {
        didSet { label.text = ba_text; invalidateIntrinsicContentSize() }
    }

    public var ba_textColor: UIColor = .white {
        didSet { label.textColor = ba_textColor }
    }

    public var ba_badgeColor: UIColor = .systemRed {
        didSet { backgroundColor = ba_badgeColor }
    }

    public var ba_font: UIFont = .systemFont(ofSize: 11, weight: .semibold) {
        didSet { label.font = ba_font; invalidateIntrinsicContentSize() }
    }

    public var ba_horizontalPadding: CGFloat = 8 {
        didSet { invalidateIntrinsicContentSize() }
    }

    public var ba_verticalPadding: CGFloat = 4 {
        didSet { invalidateIntrinsicContentSize() }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = ba_badgeColor
        layer.masksToBounds = true
        label.font = ba_font
        label.textColor = ba_textColor
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: ba_verticalPadding),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -ba_verticalPadding),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: ba_horizontalPadding),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -ba_horizontalPadding)
        ])
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        // 自动变为胶囊
        layer.cornerRadius = bounds.height / 2
    }
}
#endif
