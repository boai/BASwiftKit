//
//  BAHomeViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit
import SnapKit

final class BAHomeViewController: BABaseViewController {

    private let viewModel: BAHomeViewModel
    private let disposeBag = BADisposeBag()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var items: [BADemoItem] = []

    // MARK: - Init

    init(viewModel: BAHomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = viewModel.title

        setupTable()
        bindViewModel()
        viewModel.loadData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // tableHeaderView 必须在 tableView 真正拿到宽度后再装配。
        // 若在 viewDidLoad 阶段就赋值，UITableView 会立即对 header
        // 跑一次布局 pass，那时它自己的 bounds.width 还是 0，会强加
        // 'UIView-Encapsulated-Layout-Width == 0' 与 gradient 的
        // left+16/right-16（要求 width >= 32）直接冲突，刷出一长串
        // 'Unable to simultaneously satisfy constraints'。
        // 这里在首次拿到宽度时才创建 header，后续宽度变化（旋转）
        // 则只重设 frame 触发重排，两侧都靠 frame.width 守门避免回环。
        let width = tableView.bounds.width
        guard width > 0 else { return }
        if tableView.tableHeaderView == nil {
            tableView.tableHeaderView = makeHeader(width: width)
        } else if let header = tableView.tableHeaderView, header.frame.width != width {
            header.frame.size.width = width
            tableView.tableHeaderView = header
        }
    }

    // MARK: - Setup

    private func setupTable() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(BAHomeItemCell.self, forCellReuseIdentifier: BAHomeItemCell.reuseId)
        // 注意：tableHeaderView 延迟到 viewDidLayoutSubviews 拿到真实宽度后再装配，
        // 避免 width=0 触发约束冲突。

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.bottom.equalToSuperview()
        }
    }

    private func makeHeader(width: CGFloat) -> UIView {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: width, height: 188))

        let gradient = BAGradientView()
        gradient.ba_colors = BAAppTheme.brandGradient
        gradient.ba_direction = .leadingDiagonal
        gradient.layer.cornerRadius = 28
        gradient.layer.cornerCurve = .continuous
        gradient.ba_setShadow(color: BAAppTheme.accent, opacity: 0.26, radius: 24, offset: CGSize(width: 0, height: 14))

        let title = UILabel.ba_make(text: viewModel.title,
                                    font: .systemFont(ofSize: 30, weight: .heavy),
                                    color: .white)

        let subtitle = UILabel.ba_make(text: viewModel.subtitle,
                                       font: .systemFont(ofSize: 14, weight: .medium),
                                       color: UIColor.white.withAlphaComponent(0.88),
                                       numberOfLines: 2)

        let versionBadge = BABadgeView()
        versionBadge.ba_text = "v\(BASwiftKit.version)"
        versionBadge.ba_badgeColor = UIColor.white.withAlphaComponent(0.24)
        versionBadge.ba_textColor = .white
        versionBadge.ba_font = .systemFont(ofSize: 12, weight: .bold)
        versionBadge.ba_horizontalPadding = 10
        versionBadge.ba_verticalPadding = 5

        container.addSubview(gradient)
        gradient.addSubview(title)
        gradient.addSubview(subtitle)
        gradient.addSubview(versionBadge)

        gradient.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.left.right.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-20)
        }
        title.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(22)
            make.top.equalToSuperview().offset(28)
            make.right.lessThanOrEqualTo(versionBadge.snp.left).offset(-8)
        }
        versionBadge.snp.makeConstraints { make in
            make.centerY.equalTo(title)
            make.right.equalToSuperview().offset(-20)
        }
        subtitle.snp.makeConstraints { make in
            make.left.equalTo(title)
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(title.snp.bottom).offset(8)
            make.bottom.lessThanOrEqualToSuperview().offset(-20)
        }

        return container
    }

    private func bindViewModel() {
        viewModel.items.bind { [weak self] items in
            self?.items = items
            self?.tableView.reloadData()
        }.disposed(by: disposeBag)
    }
}

extension BAHomeViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BAHomeItemCell.reuseId, for: indexPath) as! BAHomeItemCell
        cell.configure(with: items[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        94
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = items[indexPath.row].builder()
        vc.title = items[indexPath.row].title
        // 二级页面隐藏底部 TabBar，给详情更多垂直空间。
        // 这里只在第一次 push 时设置即可，后续从二级 push 到三级会自动保持。
        vc.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(vc, animated: true)
    }
}
