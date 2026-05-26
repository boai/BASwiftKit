//
//  BAInfraDemoViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit
import SnapKit

final class BAInfraDemoViewController: BABaseViewController {

    private let viewModel: BAInfraDemoViewModel
    private let disposeBag = BADisposeBag()
    private let scroll = UIScrollView()
    private let stack = UIStackView.ba_make(axis: .vertical, spacing: 16)
    private let rowsStack = UIStackView.ba_make(axis: .vertical, spacing: 8)
    private let tablePreview = UITableView(frame: .zero, style: .plain)
    private let collectionPreview: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 10
        layout.itemSize = CGSize(width: 112, height: 76)
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()
    private let listItems = [
        BAInfraListItem(title: "Alert", subtitle: "自定义弹窗", color: BAAppTheme.accent),
        BAInfraListItem(title: "Form", subtitle: "输入封装", color: BAAppTheme.success),
        BAInfraListItem(title: "Codable", subtitle: "模型转换", color: BAAppTheme.accentSecondary)
    ]

    init(viewModel: BAInfraDemoViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        bindViewModel()
        viewModel.refresh()
    }

    private func setupLayout() {
        scroll.alwaysBounceVertical = true
        view.addSubview(scroll)
        scroll.addSubview(stack)

        scroll.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.bottom.equalToSuperview()
        }
        stack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.bottom.equalToSuperview().offset(-24)
            make.left.right.equalToSuperview().inset(16)
            make.width.equalTo(scroll).offset(-32)
        }

        stack.ba_addArrangedSubviews(
            sectionTitle("UIView.ba_onTap / ba_onLongPress"),
            makeTapCard(),
            sectionTitle("自定义 Alert / 表单 / Codable"),
            makeFeatureGrid(),
            sectionTitle("TableView / CollectionView 订阅者"),
            makeListPreview(),
            sectionTitle("Bundle / Window / Top VC"),
            rowsStack,
            makeRefreshButton()
        )
    }

    private func sectionTitle(_ text: String) -> UILabel {
        UILabel.ba_make(text: text,
                        font: .ba_semibold(14),
                        color: BAAppTheme.textSecondary)
    }

    private func makeTapCard() -> UIView {
        let card = BACardView()
        card.ba_cardColor = BAAppTheme.cardHighlight
        card.ba_cornerRadius = BAAppTheme.cornerRadius

        let title = UILabel.ba_make(text: "👇 单击我 · 长按我",
                                    font: .ba_semibold(16),
                                    color: BAAppTheme.textPrimary,
                                    alignment: .center)
        let hint = UILabel.ba_make(text: "Tap → Toast；LongPress → Alert",
                                   font: .ba_regular(13),
                                   color: BAAppTheme.textSecondary,
                                   alignment: .center)
        let s = UIStackView.ba_make(axis: .vertical, spacing: 4, alignment: .center)
        s.ba_addArrangedSubviews(title, hint)
        card.contentView.addSubview(s)
        s.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(24)
            make.left.right.equalToSuperview().inset(16)
        }

        card.ba_onTap { _ in
            BAToast.ba_show("ba_onTap 触发", style: .success)
        }
        card.ba_onLongPress { [weak self] _ in
            self?.ba_alert(title: "长按事件",
                           message: "ba_onLongPress 触发，回调发生在 .began 阶段。",
                           confirmTitle: "好的")
        }
        return card
    }

    private func makeRefreshButton() -> UIButton {
        let btn = UIButton.ba_make(title: "刷新 Top VC / Window 信息",
                                   titleColor: .white,
                                   backgroundColor: BAAppTheme.accent,
                                   font: .ba_semibold(15),
                                   cornerRadius: BAAppTheme.smallCornerRadius)
        btn.snp.makeConstraints { make in
            make.height.equalTo(BAAppTheme.controlHeight)
        }
        btn.ba_onTap { [weak self] _ in
            self?.viewModel.refresh()
            BAToast.ba_show("已刷新")
        }
        return btn
    }

    private func makeFeatureGrid() -> UIView {
        let card = BACardView()
        card.ba_cardColor = BAAppTheme.cardHighlight
        card.ba_cornerRadius = BAAppTheme.cornerRadius

        let grid = UIStackView.ba_make(axis: .vertical, spacing: 10)
        let row1 = UIStackView.ba_make(axis: .horizontal, spacing: 10, distribution: .fillEqually)
        let row2 = UIStackView.ba_make(axis: .horizontal, spacing: 10, distribution: .fillEqually)
        let row3 = UIStackView.ba_make(axis: .horizontal, spacing: 10, distribution: .fillEqually)
        row1.ba_addArrangedSubviews(
            makeFeatureButton(title: "Custom Alert", color: BAAppTheme.accent) { [weak self] in self?.showCustomAlert() },
            makeFeatureButton(title: "Text Controls", color: BAAppTheme.success) { [weak self] in self?.showFormAlert() }
        )
        row2.ba_addArrangedSubviews(
            makeFeatureButton(title: "Codable", color: BAAppTheme.accentSecondary) { [weak self] in self?.showCodableDemo() },
            makeFeatureButton(title: "DatePicker", color: BAAppTheme.warning) { [weak self] in self?.showDatePickerAlert() }
        )
        row3.ba_addArrangedSubviews(
            makeFeatureButton(title: "EmptyView", color: BAAppTheme.danger) { [weak self] in self?.showEmptyDemo() },
            makeFeatureButton(title: "Network", color: UIColor(ba_hex: "#2F80ED") ?? BAAppTheme.accent) { [weak self] in self?.showNetworkDemo() }
        )
        grid.ba_addArrangedSubviews(row1, row2, row3)
        card.contentView.addSubview(grid)
        grid.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(14)
        }
        return card
    }

    private func makeFeatureButton(title: String, color: UIColor, action: @escaping () -> Void) -> UIButton {
        let button = UIButton.ba_make(title: title,
                                      titleColor: .white,
                                      backgroundColor: color,
                                      font: .ba_semibold(13),
                                      cornerRadius: BAAppTheme.smallCornerRadius)
        button.snp.makeConstraints { make in make.height.equalTo(46) }
        button.ba_onTap { _ in action() }
        return button
    }

    private func makeListPreview() -> UIView {
        let card = BACardView()
        card.ba_cardColor = BAAppTheme.cardHighlight
        card.ba_cornerRadius = BAAppTheme.cornerRadius

        tablePreview.backgroundColor = .clear
        tablePreview.separatorStyle = .none
        tablePreview.isScrollEnabled = false
        tablePreview.ba_subscribe(listItems,
                                  cellType: BAInfraTableCell.self,
                                  rowHeight: 58,
                                  configure: { cell, item, _ in cell.configure(item) },
                                  didSelect: { item, _ in BAToast.ba_show("Table 选中：\(item.title)") })

        collectionPreview.backgroundColor = .clear
        collectionPreview.showsHorizontalScrollIndicator = false
        collectionPreview.ba_subscribe(listItems,
                                       cellType: BAInfraCollectionCell.self,
                                       configure: { cell, item, _ in cell.configure(item) },
                                       didSelect: { item, _ in BAToast.ba_show("Collection 选中：\(item.title)") })

        card.contentView.ba_addSubviews(tablePreview, collectionPreview)
        tablePreview.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview().inset(14)
            make.height.equalTo(174)
        }
        collectionPreview.snp.makeConstraints { make in
            make.top.equalTo(tablePreview.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(14)
            make.height.equalTo(82)
            make.bottom.equalToSuperview().offset(-14)
        }
        return card
    }

    private func showCustomAlert() {
        ba_customAlert(title: "自定义 Alert",
                       message: "支持自定义内容、按钮样式、遮罩关闭和暗黑模式。",
                       actions: [
                           BAAlertAction(title: "取消", style: .cancel),
                           BAAlertAction(title: "确认", style: .normal) { BAToast.ba_show("点击确认", style: .success) }
                       ])
    }

    private func showFormAlert() {
        let field = UITextField()
            .ba_placeholder("请输入昵称")
            .ba_font(.ba_medium(14))
            .ba_textColor(BAAppTheme.textPrimary)
            .ba_maxLength(12)
        field.ba_leftPadding(12)
        field.backgroundColor = BAAppTheme.backgroundElevated
        field.layer.cornerRadius = BAAppTheme.smallCornerRadius

        let textView = UITextView()
        textView.font = .ba_regular(14)
        textView.textColor = BAAppTheme.textPrimary
        textView.backgroundColor = BAAppTheme.backgroundElevated
        textView.layer.cornerRadius = BAAppTheme.smallCornerRadius
        textView.ba_placeholder = "请输入备注，最多 40 字"
        textView.ba_maxLength = 40
        textView.ba_setTextPadding(UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8))

        let content = UIStackView.ba_make(axis: .vertical, spacing: 10)
        content.ba_addArrangedSubviews(field, textView)
        field.snp.makeConstraints { make in make.height.equalTo(44) }
        textView.snp.makeConstraints { make in make.height.equalTo(92) }

        ba_customAlert(title: "输入控件封装",
                       message: "UITextField + UITextView 支持链式配置、placeholder、maxLength。",
                       contentView: content,
                       actions: [BAAlertAction(title: "完成")])
    }

    private func showDatePickerAlert() {
        let label = UILabel.ba_make(text: Date().ba_string(format: "yyyy-MM-dd"),
                                    font: .ba_semibold(15),
                                    color: BAAppTheme.accent,
                                    alignment: .center)
        let picker = UIDatePicker.ba_make(mode: .date)
        if #available(iOS 13.4, *) {
            picker.preferredDatePickerStyle = .wheels
        }
        picker.ba_onChange { _, date in
            label.text = date.ba_string(format: "yyyy-MM-dd")
        }
        let content = UIStackView.ba_make(axis: .vertical, spacing: 8)
        content.ba_addArrangedSubviews(label, picker)
        ba_customAlert(title: "UIDatePicker.ba_make",
                       message: "闭包订阅 valueChanged，直接拿到 Date。",
                       contentView: content,
                       actions: [BAAlertAction(title: "好的")])
    }

    private func showCodableDemo() {
        let user = BAInfraCodableUser(id: 7, name: "Boai", joinedAt: Date(timeIntervalSince1970: 1_700_000_000))
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let json = (try? BACodable.jsonString(from: user, encoder: encoder)) ?? "{}"
        let decoded = try? BAInfraCodableUser.ba_decode(jsonString: json, decoder: decoder)
        let dict = (try? user.ba_dictionary(encoder: encoder)) ?? [:]
        ba_customAlert(title: "Codable 互转",
                       message: "JSON → Model：\(decoded?.name ?? "-")\nModel → Dict：\(dict.keys.sorted().joined(separator: ", "))\n\n\(json)",
                       actions: [BAAlertAction(title: "完成", style: .normal)])
    }

    private func showEmptyDemo() {
        let preview = UIView()
        preview.backgroundColor = BAAppTheme.backgroundElevated
        preview.layer.cornerRadius = 18
        preview.snp.makeConstraints { make in make.height.equalTo(260) }
        preview.ba_showEmptyView(
            BAEmptyViewConfiguration(image: UIImage(systemName: "tray"),
                                     title: "暂无数据",
                                     message: "图片、标题、内容、按钮都可以自由选择，间距也能调整。",
                                     buttonTitle: "重新加载",
                                     imageSize: CGSize(width: 58, height: 58),
                                     verticalSpacing: 10,
                                     buttonBackgroundColor: BAAppTheme.accent)
        ) {
            BAProgressHUD.showSuccess("已重新加载")
        }
        ba_customAlert(title: "BAEmptyView",
                       message: "全局空状态组件，可直接挂到任意 UIView。",
                       contentView: preview,
                       actions: [BAAlertAction(title: "好的")])
    }

    private func showNetworkDemo() {
        let client = BANetworkClient(configuration: BANetworkConfiguration(
            baseURL: URL(string: "https://jsonplaceholder.typicode.com"),
            timeout: 12,
            defaultHeaders: ["Accept": "application/json"]
        ))
        let request = BANetworkRequest(path: "todos/1")
        BAProgressHUD.show("请求中…")
        client.request(request, responseType: BAInfraTodo.self) { result in
            switch result {
            case .success(let todo):
                BAProgressHUD.showSuccess("请求成功")
                self.ba_customAlert(title: "网络请求封装",
                                    message: "#\(todo.id) \(todo.title)\ncompleted: \(todo.completed)",
                                    actions: [BAAlertAction(title: "完成")])
            case .failure(let error):
                BAProgressHUD.showError("请求失败")
                self.ba_alert(title: "网络请求失败", message: error.localizedDescription)
            }
        }
    }

    private func bindViewModel() {
        viewModel.rows.bind { [weak self] rows in
            self?.renderRows(rows)
        }.disposed(by: disposeBag)
    }

    private func renderRows(_ rows: [BAInfraRow]) {
        rowsStack.ba_removeAllArrangedSubviews()
        for r in rows {
            let card = BACardView()
            card.ba_cardColor = BAAppTheme.cardHighlight
            card.ba_cornerRadius = BAAppTheme.smallCornerRadius

            let key = UILabel.ba_make(text: r.label,
                                      font: .ba_medium(13),
                                      color: BAAppTheme.textSecondary)
            let val = UILabel.ba_make(text: r.value,
                                      font: .ba_mono(12, weight: .regular),
                                      color: BAAppTheme.textPrimary,
                                      numberOfLines: 0)

            card.contentView.ba_addSubviews(key, val)
            key.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(10)
                make.left.right.equalToSuperview().inset(12)
            }
            val.snp.makeConstraints { make in
                make.top.equalTo(key.snp.bottom).offset(4)
                make.left.right.equalTo(key)
                make.bottom.equalToSuperview().offset(-12)
            }
            rowsStack.addArrangedSubview(card)
        }
    }
}

private struct BAInfraListItem {
    let title: String
    let subtitle: String
    let color: UIColor
}

private struct BAInfraCodableUser: Codable {
    let id: Int
    let name: String
    let joinedAt: Date
}

private struct BAInfraTodo: Codable {
    let userId: Int
    let id: Int
    let title: String
    let completed: Bool
}

private final class BAInfraTableCell: UITableViewCell {

    private let dot = UIView()
    private let title = UILabel.ba_make(font: .ba_semibold(14), color: BAAppTheme.textPrimary)
    private let subtitle = UILabel.ba_make(font: .ba_regular(12), color: BAAppTheme.textSecondary)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        dot.layer.cornerRadius = 8
        let textStack = UIStackView.ba_make(axis: .vertical, spacing: 2)
        textStack.ba_addArrangedSubviews(title, subtitle)
        contentView.ba_addSubviews(dot, textStack)
        dot.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(4)
            make.centerY.equalToSuperview()
            make.size.equalTo(16)
        }
        textStack.snp.makeConstraints { make in
            make.left.equalTo(dot.snp.right).offset(12)
            make.right.equalToSuperview().offset(-4)
            make.centerY.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(_ item: BAInfraListItem) {
        dot.backgroundColor = item.color
        title.text = item.title
        subtitle.text = item.subtitle
    }
}

private final class BAInfraCollectionCell: UICollectionViewCell {

    private let title = UILabel.ba_make(font: .ba_semibold(13), color: .white, alignment: .center)
    private let subtitle = UILabel.ba_make(font: .ba_regular(11), color: UIColor.white.withAlphaComponent(0.82), alignment: .center)

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 16
        contentView.layer.cornerCurve = .continuous
        contentView.layer.masksToBounds = true
        let stack = UIStackView.ba_make(axis: .vertical, spacing: 3, alignment: .center)
        stack.ba_addArrangedSubviews(title, subtitle)
        contentView.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(8)
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(_ item: BAInfraListItem) {
        contentView.backgroundColor = item.color
        title.text = item.title
        subtitle.text = item.subtitle
    }
}
