//
//  BACountdownDemoViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/06/02.
//

import UIKit
import BASwiftKit
import SnapKit
import DemoCommon

/// 限时抢购列表 Demo。
///
/// 顶部 Banner 展示全局倒计时（最近到期商品），下方列表展示每个商品的独立倒计时。
/// 所有 Cell 共享 `BACountdownManager` 的同一个底层 Timer，
/// 刷新列表后截止时间重新随机生成，倒计时依然准确同步。
final class BACountdownDemoViewController: BABaseViewController {

    private let viewModel = BACountdownDemoViewModel()
    private let disposeBag = BADisposeBag()

    // MARK: - Banner

    private let bannerView = BAGradientView()
    private let bannerIcon = UIImageView()
    private let bannerTitle = UILabel()
    private let bannerTimeLabel = UILabel()
    private var bannerCountdownId: String?

    // MARK: - TableView

    private let tableView = UITableView()
    private let refreshControl = UIRefreshControl()

    // MARK: - Init

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "限时抢购"
        setupLayout()
        bindViewModel()
        viewModel.loadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        BACountdownManager.shared.resume()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        BACountdownManager.shared.pause()
    }

    // MARK: - Setup

    private func setupLayout() {
        view.backgroundColor = BAAppTheme.background

        // Banner
        bannerView.ba_direction = .trailingDiagonal
        bannerView.ba_colors = [
            UIColor(ba_hex: "#FF4D4F")!,
            UIColor(ba_hex: "#FF7A45")!,
        ]
        view.addSubview(bannerView)

        bannerIcon.image = UIImage(systemName: "clock.badge.exclamationmark.fill")
        bannerIcon.tintColor = .white
        bannerIcon.contentMode = .scaleAspectFit
        bannerView.addSubview(bannerIcon)

        bannerTitle.text = "⏱ 限时抢购"
        bannerTitle.font = .systemFont(ofSize: 20, weight: .bold)
        bannerTitle.textColor = .white
        bannerView.addSubview(bannerTitle)

        bannerTimeLabel.font = .monospacedDigitSystemFont(ofSize: 38, weight: .bold)
        bannerTimeLabel.textColor = .white
        bannerTimeLabel.textAlignment = .center
        bannerTimeLabel.text = "--:--:--"
        bannerView.addSubview(bannerTimeLabel)

        // TableView
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 16, right: 0)
        tableView.register(BACountdownDemoCell.self, forCellReuseIdentifier: BACountdownDemoCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)

        refreshControl.tintColor = BAAppTheme.accent
        refreshControl.addTarget(self, action: #selector(onRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl

        // Layout
        bannerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
            make.height.equalTo(160)
        }

        bannerIcon.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(20)
            make.size.equalTo(28)
        }

        bannerTitle.snp.makeConstraints { make in
            make.left.equalTo(bannerIcon.snp.right).offset(8)
            make.centerY.equalTo(bannerIcon)
        }

        bannerTimeLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(bannerTitle.snp.bottom).offset(16)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(bannerView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
    }

    private func bindViewModel() {
        viewModel.products.bind(on: .main) { [weak self] _ in
            self?.tableView.reloadData()
            self?.refreshControl.endRefreshing()
        }.disposed(by: disposeBag)

        // Banner 绑定到最近到期商品
        viewModel.nearestProduct.bind(on: .main) { [weak self] product in
            guard let self, let product, !product.isExpired else { return }
            // 为 banner 注册独立倒计时（与 Cell 无关）
            if let oldId = self.bannerCountdownId {
                BACountdownManager.shared.unregister(id: oldId)
            }
            self.bannerCountdownId = BACountdownManager.shared.register(
                endDate: product.endDate
            ) { [weak self] status in
                DispatchQueue.main.async {
                    self?.bannerTimeLabel.text = status.formatted
                    if status.isExpired {
                        self?.bannerTimeLabel.text = "已结束"
                    }
                }
            }
        }.disposed(by: disposeBag)
    }

    // MARK: - Actions

    @objc private func onRefresh() {
        viewModel.refreshProducts()
    }
}

// MARK: - UITableViewDataSource & Delegate

extension BACountdownDemoViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.products.value.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: BACountdownDemoCell.reuseIdentifier,
            for: indexPath
        ) as! BACountdownDemoCell
        let product = viewModel.products.value[indexPath.row]
        cell.configure(with: product)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        90
    }

    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let cell = cell as? BACountdownDemoCell, let id = cell.countdownId else { return }
        BACountdownManager.shared.unregister(id: id)
        cell.countdownId = nil
    }
}
