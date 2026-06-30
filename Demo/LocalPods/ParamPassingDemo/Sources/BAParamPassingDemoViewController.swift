//
//  BAParamPassingDemoViewController.swift
//  ParamPassingDemo
//
//  Created by boai on 2026/06/03.
//

import UIKit
import BASwiftKit
import SnapKit
import DemoCommon

// MARK: - Demo ViewController

/// 路由传参 + 回调 Demo。
///
/// 演示三种场景：
/// 1. **接收路由参数** — 通过 `BARoutable` 协议注入参数
/// 2. **URL Query 传参** — 解析 URL 中的 query 参数
/// 3. **回调结果** — 处理完后通过 `BARouter.sendCallback` 回传结果
///
/// 路由注册示例：
/// ```swift
/// BARouter.shared.register(demoRoute(pattern: BADemoRoutes.Foundation.paramPassing) {
///     BAParamPassingDemoViewController(routeToken: token)
/// })
/// ```
public final class BAParamPassingDemoViewController: BABaseViewController, BARoutable {

    // MARK: - Properties

    /// 接收到的路由参数。
    private var routeParams: [String: Any] = [:]

    /// 回调令牌（由发起方传递，用于回传结果）。
    private var routeToken: BARouteCallbackToken?

    /// 页面标题（路由参数注入）。
    private var pageTitle: String?

    /// 展示用的数据模型。
    private var displayItems: [DisplayItem] = []

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView.ba_make(axis: .vertical, spacing: 16)

    // 输入控件
    private let nameTextField = UITextField()
    private let ageTextField = UITextField()
    private let messageTextField = UITextField()
    private let submitButton = UIButton.ba_make(title: "回传结果 →",
                                                 titleColor: .white,
                                                 backgroundColor: BAAppTheme.accent,
                                                 font: .ba_semibold(16),
                                                 cornerRadius: BAAppTheme.smallCornerRadius)

    // MARK: - Init

    public init(routeToken: BARouteCallbackToken? = nil) {
        self.routeToken = routeToken
        super.init(nibName: nil, bundle: nil)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - BARoutable

    /// 接收路由参数注入。
    ///
    /// 当通过 `.viewController` 类型注册且 VC 遵循 `BARoutable` 时，
    /// BARouter 会自动调用该方法注入 URL 解析后的参数。
    public func receiveRouteParams(_ params: [String: Any]) {
        self.routeParams = params

        // 提取参数字段
        if let name = params["name"] as? String {
            nameTextField.text = name
        }
        if let age = params["age"] as? Int {
            ageTextField.text = "\(age)"
        } else if let ageStr = params["age"] as? String {
            ageTextField.text = ageStr
        }
        if let msg = params["message"] as? String {
            messageTextField.text = msg
        }
        // routeToken 已在 init(routeToken:) 中注入，此处不重复提取
    }

    // MARK: - Life Cycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = pageTitle ?? "参数传递 & 回调"

        setupUI()
        populateReceivedParams()
    }

    // MARK: - UI Setup

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

        // 标题
        let titleLabel = UILabel.ba_make(
            text: "路由参数接收",
            font: BAAppTheme.largeTitleFont,
            color: BAAppTheme.textPrimary
        )
        contentStack.addArrangedSubview(titleLabel)

        // 参数展示区域
        let paramsCard = makeCard(title: "📋 接收到的参数", contentView: makeParamsLabel())
        contentStack.addArrangedSubview(paramsCard)

        // 输入区域
        let inputHeader = UILabel.ba_make(
            text: "📝 编辑并回传",
            font: BAAppTheme.titleFont,
            color: BAAppTheme.textPrimary
        )
        contentStack.addArrangedSubview(inputHeader)

        nameTextField.placeholder = "姓名"
        nameTextField.ba_leftPadding(12)
        nameTextField.backgroundColor = BAAppTheme.card
        nameTextField.layer.cornerRadius = BAAppTheme.smallCornerRadius
        nameTextField.ba_setBorder(width: 1, color: BAAppTheme.separator)
        nameTextField.snp.makeConstraints { make in make.height.equalTo(BAAppTheme.controlHeight) }
        contentStack.addArrangedSubview(nameTextField)

        ageTextField.placeholder = "年龄"
        ageTextField.ba_leftPadding(12)
        ageTextField.keyboardType = .numberPad
        ageTextField.backgroundColor = BAAppTheme.card
        ageTextField.layer.cornerRadius = BAAppTheme.smallCornerRadius
        ageTextField.ba_setBorder(width: 1, color: BAAppTheme.separator)
        ageTextField.snp.makeConstraints { make in make.height.equalTo(BAAppTheme.controlHeight) }
        contentStack.addArrangedSubview(ageTextField)

        messageTextField.placeholder = "返回消息"
        messageTextField.ba_leftPadding(12)
        messageTextField.backgroundColor = BAAppTheme.card
        messageTextField.layer.cornerRadius = BAAppTheme.smallCornerRadius
        messageTextField.ba_setBorder(width: 1, color: BAAppTheme.separator)
        messageTextField.snp.makeConstraints { make in make.height.equalTo(BAAppTheme.controlHeight) }
        contentStack.addArrangedSubview(messageTextField)

        submitButton.snp.makeConstraints { make in make.height.equalTo(BAAppTheme.controlHeight) }
        submitButton.ba_onTap { [weak self] _ in
            self?.submitCallback()
        }
        contentStack.addArrangedSubview(submitButton)

        // 使用说明
        let usageCard = makeCard(title: "💡 使用说明", contentView: makeUsageLabel())
        contentStack.addArrangedSubview(usageCard)
    }

    private func populateReceivedParams() {
        // 过滤内部 key（如 _ba_callback_token），避免路由机制细节暴露到 UI
        let internalKeys: Set<String> = ["_ba_callback_token"]
        let userParams = routeParams.filter { !internalKeys.contains($0.key) }
        guard !userParams.isEmpty else { return }

        displayItems = userParams.map { key, value in
            DisplayItem(key: key, value: "\(value)")
        }.sorted { $0.key < $1.key }
    }

    // MARK: - Card Helper

    private func makeCard(title: String, contentView: UIView) -> UIView {
        let card = UIView()
        card.backgroundColor = BAAppTheme.card
        card.layer.cornerRadius = BAAppTheme.cornerRadius
        card.ba_setShadow(color: .black, opacity: 0.06, radius: 8, offset: CGSize(width: 0, height: 2))

        let titleLabel = UILabel.ba_make(text: title, font: BAAppTheme.titleFont, color: BAAppTheme.textPrimary)
        card.addSubview(titleLabel)
        card.addSubview(contentView)

        titleLabel.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview().inset(16)
        }
        contentView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.left.right.bottom.equalToSuperview().inset(16)
        }
        return card
    }

    private func makeParamsLabel() -> UIView {
        if routeParams.isEmpty {
            let label = UILabel.ba_make(
                text: "（未接收到参数，可通过路由 URL 传入）",
                font: BAAppTheme.bodyFont,
                color: BAAppTheme.textSecondary
            )
            return label
        }

        let stack = UIStackView.ba_make(axis: .vertical, spacing: 6)
        for item in displayItems {
            let row = UIStackView.ba_make(axis: .horizontal, spacing: 8)
            let keyLabel = UILabel.ba_make(
                text: "\(item.key):",
                font: .ba_mono(13, weight: .medium),
                color: BAAppTheme.accent
            )
            keyLabel.setContentHuggingPriority(.required, for: .horizontal)
            let valLabel = UILabel.ba_make(
                text: item.value,
                font: BAAppTheme.bodyFont,
                color: BAAppTheme.textPrimary,
                numberOfLines: 0
            )
            row.addArrangedSubview(keyLabel)
            row.addArrangedSubview(valLabel)
            stack.addArrangedSubview(row)
        }
        return stack
    }

    private func makeUsageLabel() -> UIView {
        let text = """
        【传参方式】
        1️⃣ URL Query：/demo/foundation/param-passing?name=张三&age=28
        2️⃣ BARouteRequest：通过 params 字典传递
        3️⃣ BARoutable 协议：自动注入参数到 VC

        【回调方式】
        目标页填写表单后点击"回传结果"，
        发起方在 open() 的回调闭包中接收。

        【外部调用示例】
        let req = BARouteRequest(
            urlString: "ba://demo/foundation/param-passing?name=张三",
            path: BADemoRoutes.Foundation.paramPassing,
            params: ["name": "张三", "age": 28],
            source: .externalApp
        )
        BARouter.shared.open(req) { result in
            print("回调结果: \\(result ?? "nil")")
        }
        """

        let label = UILabel.ba_make(
            text: text,
            font: .ba_mono(12, weight: .regular),
            color: BAAppTheme.textSecondary,
            numberOfLines: 0
        )
        return label
    }

    // MARK: - Callback

    private func submitCallback() {
        guard let token = routeToken else {
            let alert = UIAlertController(
                title: "无回调令牌",
                message: "当前页面未携带回调令牌，无法回传结果。\n\n请通过带 callback 的 open() 方式进入。",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "知道了", style: .default))
            present(alert, animated: true)
            return
        }

        let result: [String: Any] = [
            "name": nameTextField.text ?? "",
            "age": ageTextField.text ?? "",
            "message": messageTextField.text ?? "",
            "timestamp": Date().timeIntervalSince1970
        ]

        BARouter.shared.sendCallback(result, for: token)

        // 回传后返回上一页
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - DisplayItem

private struct DisplayItem {
    let key: String
    let value: String
}
