//
//  BALoggerDemoViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/06/02.
//

import UIKit
import BASwiftKit
import SnapKit

/// 日志埋点系统 Demo。
///
/// 演示手动打点、查看日志列表、按日导出加密 TXT、自定义密码。
final class BALoggerDemoViewController: BABaseViewController {

    private let disposeBag = BADisposeBag()
    private var currentDate: String = BALoggerDemoViewController.todayString()
    private var logs: [BALogEntry] = []

    // MARK: - UI

    private let dateLabel = UILabel()
    private let countLabel = UILabel()
    private let tableView = UITableView()
    private let actionStack = UIStackView()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "日志埋点"
        setupLayout()
        reloadLogs()
    }

    // MARK: - Setup

    private func setupLayout() {
        view.backgroundColor = BAAppTheme.background

        dateLabel.font = .systemFont(ofSize: 16, weight: .bold)
        dateLabel.textColor = BAAppTheme.textPrimary
        dateLabel.text = currentDate
        view.addSubview(dateLabel)

        countLabel.font = .systemFont(ofSize: 13)
        countLabel.textColor = BAAppTheme.textSecondary
        view.addSubview(countLabel)

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = BAAppTheme.textSecondary.withAlphaComponent(0.15)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "logCell")
        tableView.dataSource = self
        tableView.estimatedRowHeight = 44
        view.addSubview(tableView)

        actionStack.axis = .vertical
        actionStack.spacing = 10
        view.addSubview(actionStack)

        addActionButton("记录 Debug 日志", color: .systemGray) { [weak self] in
            BALogManager.shared.log(.debug, "这是一条 Debug 日志")
            self?.reloadLogs()
        }
        addActionButton("记录 Info 日志", color: .systemBlue) { [weak self] in
            BALogManager.shared.log(.info, "用户登录成功，UID: 12345")
            self?.reloadLogs()
        }
        addActionButton("记录 Warning 日志", color: .systemOrange) { [weak self] in
            BALogManager.shared.log(.warning, "网络请求耗时较长: 3.2s")
            self?.reloadLogs()
        }
        addActionButton("记录 Error 日志", color: .systemRed) { [weak self] in
            BALogManager.shared.log(.error, "接口返回 500: Internal Server Error")
            self?.reloadLogs()
        }
        addActionButton("模拟页面浏览", color: BAAppTheme.accent) { [weak self] in
            BALogManager.shared.logPageView(page: "ProductDetailPage", title: "商品详情")
            self?.reloadLogs()
        }
        addActionButton("模拟按钮点击", color: BAAppTheme.accent) { [weak self] in
            BALogManager.shared.logButtonClick(buttonTitle: "立即购买", page: "ProductDetailPage")
            self?.reloadLogs()
        }

        let exportBtn = UIButton(type: .system)
        exportBtn.setTitle("📤 导出今日日志（加密 TXT）", for: .normal)
        exportBtn.titleLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        exportBtn.backgroundColor = BAAppTheme.accent
        exportBtn.setTitleColor(.white, for: .normal)
        exportBtn.layer.cornerRadius = 12
        exportBtn.addTarget(self, action: #selector(onExportTap), for: .touchUpInside)
        actionStack.addArrangedSubview(exportBtn)
        exportBtn.snp.makeConstraints { $0.height.equalTo(48) }

        // Layout
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(12)
            make.left.equalToSuperview().offset(20)
        }
        countLabel.snp.makeConstraints { make in
            make.centerY.equalTo(dateLabel)
            make.right.equalToSuperview().offset(-20)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(8)
            make.left.right.equalToSuperview()
            make.height.equalTo(250)
        }
        actionStack.snp.makeConstraints { make in
            make.top.equalTo(tableView.snp.bottom).offset(12)
            make.left.right.equalToSuperview().inset(20)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide.snp.bottom).offset(-16)
        }
    }

    private func addActionButton(_ title: String, color: UIColor, action: @escaping () -> Void) {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        btn.backgroundColor = color.withAlphaComponent(0.12)
        btn.setTitleColor(color, for: .normal)
        btn.layer.cornerRadius = 8
        btn.ba_onTap { _ in action() }
        actionStack.addArrangedSubview(btn)
        btn.snp.makeConstraints { $0.height.equalTo(40) }
    }

    // MARK: - Actions

    private func reloadLogs() {
        logs = BALogSQLiteStore.shared.fetch(dateString: currentDate)
        countLabel.text = "共 \(logs.count) 条"
        tableView.reloadData()
    }

    @objc private func onExportTap() {
        let alert = UIAlertController(title: "导出加密日志", message: "请输入加密密码（至少 4 位）", preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "加密密码"
            tf.isSecureTextEntry = true
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "导出", style: .default) { [weak self] _ in
            guard let password = alert.textFields?.first?.text, !password.isEmpty else { return }
            self?.doExport(password: password)
        })
        present(alert, animated: true)
    }

    private func doExport(password: String) {
        do {
            let exporter = BALogExporter()
            let url = try exporter.export(date: currentDate, password: password)
            let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            present(activity, animated: true)
        } catch {
            let alert = UIAlertController(title: "导出失败", message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "确定", style: .default))
            present(alert, animated: true)
        }
    }

    private static func todayString() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }
}

// MARK: - UITableViewDataSource

extension BALoggerDemoViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        logs.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "logCell", for: indexPath)
        let entry = logs[indexPath.row]
        var config = cell.defaultContentConfiguration()
        config.text = "[\(entry.timeString)] [\(entry.level.displayName)] \(entry.message)"
        config.textProperties.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        config.textProperties.numberOfLines = 0
        switch entry.level {
        case .error:   config.textProperties.color = BAAppTheme.danger
        case .warning: config.textProperties.color = .systemOrange
        default:       config.textProperties.color = BAAppTheme.textPrimary
        }
        cell.contentConfiguration = config
        cell.backgroundColor = .clear
        return cell
    }
}
