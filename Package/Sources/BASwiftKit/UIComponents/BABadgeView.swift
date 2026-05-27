//
//  BABadgeView.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

#if canImport(UIKit)
import UIKit
import SnapKit

/// 自适应宽度的小角标。可用作分类标签 / 状态 chip。
public final class BABadgeView: UIView {

    private let label = UILabel()

    /// 角标显示文本。
    public var ba_text: String? {
        didSet { label.text = ba_text; invalidateIntrinsicContentSize() }
    }

    /// 角标文本颜色。
    public var ba_textColor: UIColor = .white {
        didSet { label.textColor = ba_textColor }
    }

    /// 角标背景色。
    public var ba_badgeColor: UIColor = .systemRed {
        didSet { backgroundColor = ba_badgeColor }
    }

    /// 角标文本字体。
    public var ba_font: UIFont = .systemFont(ofSize: 11, weight: .semibold) {
        didSet { label.font = ba_font; invalidateIntrinsicContentSize() }
    }

    /// 文本左右内边距。
    public var ba_horizontalPadding: CGFloat = 8 {
        didSet { updateInsets() }
    }

    /// 文本上下内边距。
    public var ba_verticalPadding: CGFloat = 4 {
        didSet { updateInsets() }
    }

    /// 代码创建角标视图。
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
        addSubview(label)

        updateInsets()
    }

    private func updateInsets() {
        label.snp.remakeConstraints { make in
            make.top.bottom.equalToSuperview().inset(ba_verticalPadding)
            make.left.right.equalToSuperview().inset(ba_horizontalPadding)
        }
        invalidateIntrinsicContentSize()
    }

    /// 更新胶囊圆角，使高度变化后仍保持圆角角标外观。
    public override func layoutSubviews() {
        super.layoutSubviews()
        // 自动变为胶囊
        layer.cornerRadius = bounds.height / 2
    }
}
#endif
