//
//  BACacheDemoViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/26.
//

import UIKit
import BASwiftKit
import SnapKit

final class BACacheDemoViewController: BABaseViewController {

    private let viewModel: BACacheDemoViewModel
    private let disposeBag = BADisposeBag()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let logTextView = UITextView()

    init(viewModel: BACacheDemoViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Cache 缓存框架"
        setupLayout()
        bindViewModel()
    }

    private func setupLayout() {
        view.addSubview(tableView)
        view.addSubview(logTextView)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 64

        logTextView.isEditable = false
        logTextView.font = .ba_mono(11, weight: .regular)
        logTextView.textColor = BAAppTheme.textPrimary
        logTextView.backgroundColor = BAAppTheme.backgroundElevated
        logTextView.layer.cornerRadius = BAAppTheme.smallCornerRadius
        logTextView.textContainerInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        tableView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.55)
        }
        logTextView.snp.makeConstraints { make in
            make.top.equalTo(tableView.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-12)
        }
    }

    private func bindViewModel() {
        viewModel.logText.bind { [weak self] text in
            self?.logTextView.text = text
            self?.logTextView.scrollRangeToVisible(NSRange(location: text.count, length: 0))
        }.disposed(by: disposeBag)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension BACacheDemoViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.rows.value.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        let row = viewModel.rows.value[indexPath.row]
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
        viewModel.rows.value[indexPath.row].action()
    }
}
