//
//  BANavBarPreviewViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit
import SnapKit

/// 用来「裸」展示一份 BANavigationBarStyle 的预览页。
/// 故意不继承 BABaseViewController：基类会写入 navigationItem.standardAppearance，
/// 那是 per-VC 外观，优先级高于 ba_apply 设置的 navigationBar 外观，会盖掉效果。
final class BANavBarPreviewViewController: UIViewController {

    private let presetTitle: String
    private let style: BANavigationBarStyle
    private let restoreStyle: BANavigationBarStyle

    init(presetTitle: String,
         style: BANavigationBarStyle,
         restoreStyle: BANavigationBarStyle) {
        self.presetTitle = presetTitle
        self.style = style
        self.restoreStyle = restoreStyle
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = presetTitle
        view.backgroundColor = BAAppTheme.background

        let label = UILabel.ba_make(
            text: "当前展示：「\(presetTitle)」\n返回上一页可继续切换其他样式。",
            font: .ba_medium(15),
            color: BAAppTheme.textSecondary,
            alignment: .center,
            numberOfLines: 0
        )
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(24)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.ba_apply(style: style)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.ba_apply(style: restoreStyle)
    }
}
