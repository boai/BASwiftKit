//
//  BAHomeViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit

final class BAHomeViewController: BABaseViewController {

    private let viewModel: BAHomeViewModel
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

    // MARK: - Setup

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(BAHomeItemCell.self, forCellReuseIdentifier: BAHomeItemCell.reuseId)
        tableView.tableHeaderView = makeHeader()

        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func makeHeader() -> UIView {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 160))

        let gradient = BAGradientView()
        gradient.translatesAutoresizingMaskIntoConstraints = false
        gradient.ba_colors = BAAppTheme.brandGradient
        gradient.ba_direction = .leadingDiagonal
        gradient.layer.cornerRadius = 18
        gradient.layer.masksToBounds = true

        let title = UILabel.ba_make(text: viewModel.title,
                                    font: .systemFont(ofSize: 26, weight: .bold),
                                    color: .white)
        title.translatesAutoresizingMaskIntoConstraints = false

        let subtitle = UILabel.ba_make(text: viewModel.subtitle,
                                       font: .systemFont(ofSize: 13, weight: .medium),
                                       color: UIColor.white.withAlphaComponent(0.85),
                                       numberOfLines: 2)
        subtitle.translatesAutoresizingMaskIntoConstraints = false

        let versionBadge = BABadgeView()
        versionBadge.ba_text = "v\(BASwiftKit.version)"
        versionBadge.ba_badgeColor = UIColor.white.withAlphaComponent(0.22)
        versionBadge.ba_textColor = .white
        versionBadge.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(gradient)
        gradient.addSubview(title)
        gradient.addSubview(subtitle)
        gradient.addSubview(versionBadge)

        NSLayoutConstraint.activate([
            gradient.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            gradient.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            gradient.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            gradient.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),

            title.leadingAnchor.constraint(equalTo: gradient.leadingAnchor, constant: 20),
            title.topAnchor.constraint(equalTo: gradient.topAnchor, constant: 24),
            title.trailingAnchor.constraint(lessThanOrEqualTo: versionBadge.leadingAnchor, constant: -8),

            versionBadge.centerYAnchor.constraint(equalTo: title.centerYAnchor),
            versionBadge.trailingAnchor.constraint(equalTo: gradient.trailingAnchor, constant: -20),

            subtitle.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            subtitle.trailingAnchor.constraint(equalTo: gradient.trailingAnchor, constant: -20),
            subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 8),
            subtitle.bottomAnchor.constraint(lessThanOrEqualTo: gradient.bottomAnchor, constant: -20)
        ])

        return container
    }

    private func bindViewModel() {
        viewModel.items.bind { [weak self] items in
            self?.items = items
            self?.tableView.reloadData()
        }
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
        let vc = items[indexPath.row].builder()
        vc.title = items[indexPath.row].title
        navigationController?.pushViewController(vc, animated: true)
    }
}
