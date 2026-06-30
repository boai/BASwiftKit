//
//  BARouterCallerViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/06/03.
//

import UIKit
import BASwiftKit
import SnapKit
import DemoCommon

/// 跨模块路由传参 + 回调 Caller 页面（A 组件的 B 页面）。
///
/// 演示通过 BARouter 框架，从当前页面传参跳转到 **另一个 pod 模块的页面**，
/// 并在目标页完成操作后，通过回调回传数据。
///
/// ## 解耦设计
///
/// - 本页面（Caller）不直接 import 目标页面所在的 pod
/// - 参数传递通过 `BARouteRequest.params`
/// - 结果回传通过 `BARouter.sendCallback(_:for:)`
/// - 页面跳转完全由 BARouter 中介
public final class BARouterCallerViewController: BABaseViewController {

    // MARK: - UI

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView.ba_make(axis: .vertical, spacing: 16)

    private let titleLabel = UILabel.ba_make(
        text: "跨模块路由传参 + 回调",
        font: .systemFont(ofSize: 26, weight: .bold),
        color: BAAppTheme.textPrimary,
        numberOfLines: 0
    )

    private let descLabel: UILabel = {
        let text = """
        本页面（InfraDemo pod）与目标页面（ParamPassingDemo pod）
        位于两个不同的 CocoaPods 模块中，二者没有任何直接 import 关系。

        所有通信完全通过 BARouter 路由框架完成：
        · 传参 → BARouteRequest.params
        · 回调 → BARouter.sendCallback(_:for:)
        """
        return UILabel.ba_make(text: text, font: .systemFont(ofSize: 13), color: BAAppTheme.textSecondary, numberOfLines: 0)
    }()

    // 输入区
    private let nameField = UITextField()
    private let ageField = UITextField()
    private let messageField = UITextField()

    private let callButton = UIButton.ba_make(
        title: "→ 跳转到 ParamPassingDemo（跨模块）",
        titleColor: .white,
        backgroundColor: BAAppTheme.accent,
        font: .ba_semibold(16),
        cornerRadius: BAAppTheme.smallCornerRadius
    )

    // 结果显示区
    private let resultCard = UIView()
    private let resultTitle = UILabel.ba_make(text: "📨 回调结果", font: BAAppTheme.titleFont, color: BAAppTheme.textPrimary)
    private let resultLabel = UILabel.ba_make(
        text: "（等待回调...）",
        font: .ba_mono(13, weight: .regular),
        color: BAAppTheme.textSecondary,
        numberOfLines: 0
    )

    // MARK: - Life Cycle

    public init() { super.init(nibName: nil, bundle: nil) }
    public required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "路由传参 & 回调"

        setupUI()
    }

    // MARK: - UI

    private func setupUI() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        scrollView.showsVerticalScrollIndicator = false

        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        contentStack.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(20)
            make.left.right.equalToSuperview().inset(20)
            make.width.equalTo(scrollView.snp.width).offset(-40)
        }

        contentStack.addArrangedSubview(titleLabel)
        contentStack.addArrangedSubview(descLabel)

        // 输入区
        let inputHeader = UILabel.ba_make(text: "📝 传递参数", font: BAAppTheme.titleFont, color: BAAppTheme.textPrimary)
        contentStack.addArrangedSubview(inputHeader)

        nameField.placeholder = "姓名"
        nameField.text = "张三"
        nameField.ba_leftPadding(12)
        nameField.backgroundColor = BAAppTheme.card
        nameField.layer.cornerRadius = BAAppTheme.smallCornerRadius
        nameField.ba_setBorder(width: 1, color: BAAppTheme.separator)
        nameField.snp.makeConstraints { make in make.height.equalTo(BAAppTheme.controlHeight) }
        contentStack.addArrangedSubview(nameField)

        ageField.placeholder = "年龄"
        ageField.text = "28"
        ageField.keyboardType = .numberPad
        ageField.ba_leftPadding(12)
        ageField.backgroundColor = BAAppTheme.card
        ageField.layer.cornerRadius = BAAppTheme.smallCornerRadius
        ageField.ba_setBorder(width: 1, color: BAAppTheme.separator)
        ageField.snp.makeConstraints { make in make.height.equalTo(BAAppTheme.controlHeight) }
        contentStack.addArrangedSubview(ageField)

        messageField.placeholder = "附加消息"
        messageField.text = "Hello from Caller"
        messageField.ba_leftPadding(12)
        messageField.backgroundColor = BAAppTheme.card
        messageField.layer.cornerRadius = BAAppTheme.smallCornerRadius
        messageField.ba_setBorder(width: 1, color: BAAppTheme.separator)
        messageField.snp.makeConstraints { make in make.height.equalTo(BAAppTheme.controlHeight) }
        contentStack.addArrangedSubview(messageField)

        callButton.snp.makeConstraints { make in make.height.equalTo(BAAppTheme.controlHeight) }
        callButton.ba_onTap { [weak self] _ in self?.openCrossModuleRoute() }
        contentStack.addArrangedSubview(callButton)

        // 结果区
        resultCard.backgroundColor = BAAppTheme.card
        resultCard.layer.cornerRadius = BAAppTheme.cornerRadius
        resultCard.ba_setShadow(color: .black, opacity: 0.06, radius: 8, offset: CGSize(width: 0, height: 2))
        resultCard.addSubview(resultTitle)
        resultCard.addSubview(resultLabel)
        resultTitle.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview().inset(16)
        }
        resultLabel.snp.makeConstraints { make in
            make.top.equalTo(resultTitle.snp.bottom).offset(10)
            make.left.right.bottom.equalToSuperview().inset(16)
        }
        contentStack.addArrangedSubview(resultCard)
    }

    // MARK: - Cross-Module Routing

    private func openCrossModuleRoute() {
        let params: [String: Any] = [
            "name": nameField.text ?? "",
            "age": ageField.text ?? "",
            "message": messageField.text ?? "",
            "source_module": "RouterCallerDemo"
        ]

        let routePath = BADemoRoute.Foundation.paramPassing
        let request = BARouteRequest(
            urlString: BADemoRoute.fullURL(routePath),
            path: routePath.pattern,
            params: params,
            source: .internal
        )

        // 打开跨模块路由，注册回调
        BARouter.shared.open(request) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let dict = result as? [String: Any] {
                    let lines = dict.map { "  \($0.key): \($0.value)" }.sorted().joined(separator: "\n")
                    self.resultLabel.text = lines
                    self.resultLabel.textColor = BAAppTheme.success

                    // success toast
                    BAToast.ba_show("收到回调: \(dict["name"] ?? "") (来自 ParamPassingDemo)", style: .success)
                } else if let str = result as? String {
                    self.resultLabel.text = str
                } else {
                    self.resultLabel.text = "回调结果: \(result ?? "nil")"
                }
                self.resultLabel.textColor = BAAppTheme.textPrimary
            }
        }

        resultLabel.text = "（已发起路由跳转，等待 ParamPassingDemo 回调...）"
        resultLabel.textColor = BAAppTheme.warning
    }
}
