//
//  BAWebViewDemoViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/26.
//

import UIKit
import BASwiftKit
import SnapKit

final class BAWebViewDemoViewController: BABaseViewController {

    private let viewModel = BAWebViewDemoViewModel()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "WebView 封装"
        setupLayout()
    }

    private func setupLayout() {
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 64
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension BAWebViewDemoViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        let row = viewModel.rows[indexPath.row]
        cell.textLabel?.text = row.title
        cell.textLabel?.font = .ba_medium(15)
        cell.detailTextLabel?.text = row.subtitle
        cell.detailTextLabel?.font = .ba_regular(12)
        cell.detailTextLabel?.textColor = BAAppTheme.textSecondary
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = BAAppTheme.card
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = viewModel.rows[indexPath.row].action()
        navigationController?.pushViewController(vc, animated: true)
    }
}
