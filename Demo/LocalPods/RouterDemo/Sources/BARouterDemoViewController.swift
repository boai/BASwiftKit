//
//  BARouterDemoViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/06/03.
//

import UIKit
import BASwiftKit

/// 路由组件 Demo。
public final class BARouterDemoViewController: UIViewController {

    public init() { super.init(nibName: nil, bundle: nil) }


    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    // MARK: - Data

    private let items: [(title: String, action: () -> Void)] = [
        ("路由 /demo/user/123", {
            BARouter.shared.open("/demo/user/123?from=router_demo")
        }),
        ("路由 /demo/settings", {
            BARouter.shared.open("/demo/settings")
        }),
        ("路由未注册路径（404）", {
            BARouter.shared.open("/demo/nonexistent") { error in
                let alert = UIAlertController(
                    title: "路由结果",
                    message: error?.localizedDescription ?? "成功",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "确定", style: .default))
                BAAppRouterHelper.topViewController()?.present(alert, animated: true)
            }
        }),
    ]

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "Router Demo"
        view.backgroundColor = .systemGroupedBackground

        setupTableView()
        BARouterDemoHelper.registerDemoRoutes()
    }

    // MARK: - Setup

    private func setupTableView() {
        tableView.frame = view.bounds
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        view.addSubview(tableView)
    }
}

// MARK: - UITableViewDataSource

extension BARouterDemoViewController: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = items[indexPath.row].title
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

// MARK: - UITableViewDelegate

extension BARouterDemoViewController: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        items[indexPath.row].action()
    }
}

// MARK: - Top VC helper

public enum BAAppRouterHelper {
    public static func topViewController() -> UIViewController? {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.keyWindow })
            .first,
            let root = window.rootViewController else { return nil }

        func findTop(from vc: UIViewController) -> UIViewController {
            if let presented = vc.presentedViewController {
                return findTop(from: presented)
            }
            if let nav = vc as? UINavigationController {
                return findTop(from: nav.visibleViewController ?? nav)
            }
            if let tab = vc as? UITabBarController, let selected = tab.selectedViewController {
                return findTop(from: selected)
            }
            return vc
        }
        return findTop(from: root)
    }
}
