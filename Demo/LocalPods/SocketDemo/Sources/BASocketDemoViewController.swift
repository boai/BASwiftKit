//
//  BASocketDemoViewController.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/28.
//

import UIKit
import BASwiftKit
import SnapKit
import DemoCommon

final class BASocketDemoViewController: BABaseViewController {

    private let viewModel: BASocketDemoViewModel
    private let disposeBag = BADisposeBag()

    private let statusCard = BACardView()
    private let statusDot = UIView()
    private let statusLabel = UILabel()
    private let urlTextField = UITextField()
    private let connectButton = UIButton(type: .system)

    private let tableView = UITableView()
    private let inputContainer = UIView()
    private let messageTextField = UITextField()
    private let sendButton = UIButton(type: .system)

    init(viewModel: BASocketDemoViewModel = BASocketDemoViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Socket / WebSocket"
        setupLayout()
        bindViewModel()
    }

    private func setupLayout() {
        statusCard.backgroundColor = BAAppTheme.card
        view.addSubview(statusCard)

        statusDot.layer.cornerRadius = 6
        statusDot.layer.masksToBounds = true
        statusCard.addSubview(statusDot)

        statusLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        statusCard.addSubview(statusLabel)

        urlTextField.borderStyle = .roundedRect
        urlTextField.font = .systemFont(ofSize: 13)
        urlTextField.text = viewModel.url.absoluteString
        urlTextField.placeholder = "wss://..."
        urlTextField.clearButtonMode = .whileEditing
        statusCard.addSubview(urlTextField)

        connectButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        connectButton.layer.cornerRadius = 10
        connectButton.layer.masksToBounds = true
        statusCard.addSubview(connectButton)

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(BASocketMessageCell.self, forCellReuseIdentifier: BASocketMessageCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        view.addSubview(tableView)

        inputContainer.backgroundColor = BAAppTheme.card
        inputContainer.layer.cornerRadius = 16
        inputContainer.layer.masksToBounds = true
        view.addSubview(inputContainer)

        messageTextField.borderStyle = .roundedRect
        messageTextField.font = .systemFont(ofSize: 15)
        messageTextField.placeholder = "输入消息..."
        messageTextField.returnKeyType = .send
        messageTextField.delegate = self
        inputContainer.addSubview(messageTextField)

        sendButton.setTitle("发送", for: .normal)
        sendButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        sendButton.backgroundColor = BAAppTheme.accent
        sendButton.setTitleColor(.white, for: .normal)
        sendButton.layer.cornerRadius = 10
        sendButton.layer.masksToBounds = true
        inputContainer.addSubview(sendButton)

        statusCard.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(12)
            make.left.right.equalToSuperview().inset(16)
        }

        statusDot.snp.makeConstraints { make in
            make.left.top.equalToSuperview().inset(16)
            make.size.equalTo(12)
        }

        statusLabel.snp.makeConstraints { make in
            make.left.equalTo(statusDot.snp.right).offset(8)
            make.centerY.equalTo(statusDot)
        }

        urlTextField.snp.makeConstraints { make in
            make.top.equalTo(statusDot.snp.bottom).offset(12)
            make.left.equalToSuperview().inset(16)
            make.right.equalTo(connectButton.snp.left).offset(-12)
            make.height.equalTo(36)
        }

        connectButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(16)
            make.centerY.equalTo(urlTextField)
            make.width.equalTo(72)
            make.height.equalTo(36)
        }

        statusCard.snp.makeConstraints { make in
            make.bottom.equalTo(urlTextField.snp.bottom).offset(16)
        }

        inputContainer.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-12)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(56)
        }

        messageTextField.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview().inset(8)
            make.right.equalTo(sendButton.snp.left).offset(-8)
        }

        sendButton.snp.makeConstraints { make in
            make.right.top.bottom.equalToSuperview().inset(8)
            make.width.equalTo(64)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(statusCard.snp.bottom).offset(12)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(inputContainer.snp.top).offset(-12)
        }
    }

    private func bindViewModel() {
        viewModel.connectionState.bind(on: .main) { [weak self] state in
            self?.updateUI(for: state)
        }.disposed(by: disposeBag)

        viewModel.messages.bind(on: .main) { [weak self] _ in
            self?.tableView.reloadData()
            self?.scrollToBottom()
        }.disposed(by: disposeBag)

        connectButton.addTarget(self, action: #selector(onConnectTap), for: .touchUpInside)
        sendButton.addTarget(self, action: #selector(onSendTap), for: .touchUpInside)
    }

    private func updateUI(for state: BASocketState) {
        switch state {
        case .idle, .disconnected:
            statusDot.backgroundColor = BAAppTheme.textSecondary.withAlphaComponent(0.4)
            statusLabel.text = "未连接"
            statusLabel.textColor = BAAppTheme.textSecondary
            connectButton.setTitle("连接", for: .normal)
            connectButton.backgroundColor = BAAppTheme.accent
            connectButton.setTitleColor(.white, for: .normal)
            stopDotAnimation()
        case .connecting:
            statusDot.backgroundColor = BAAppTheme.warning
            statusLabel.text = "连接中..."
            statusLabel.textColor = BAAppTheme.warning
            connectButton.setTitle("取消", for: .normal)
            connectButton.backgroundColor = BAAppTheme.textSecondary.withAlphaComponent(0.15)
            connectButton.setTitleColor(BAAppTheme.textSecondary, for: .normal)
            startDotAnimation()
        case .connected:
            statusDot.backgroundColor = BAAppTheme.success
            statusLabel.text = "已连接"
            statusLabel.textColor = BAAppTheme.success
            connectButton.setTitle("断开", for: .normal)
            connectButton.backgroundColor = BAAppTheme.danger.withAlphaComponent(0.12)
            connectButton.setTitleColor(BAAppTheme.danger, for: .normal)
            stopDotAnimation()
        case .disconnecting:
            statusLabel.text = "断开中..."
            statusLabel.textColor = BAAppTheme.textSecondary
            stopDotAnimation()
        }
    }

    private func startDotAnimation() {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1.0
        animation.toValue = 0.3
        animation.duration = 0.6
        animation.autoreverses = true
        animation.repeatCount = .infinity
        statusDot.layer.add(animation, forKey: "pulse")
    }

    private func stopDotAnimation() {
        statusDot.layer.removeAnimation(forKey: "pulse")
    }

    private func scrollToBottom() {
        let row = viewModel.messages.value.count - 1
        guard row >= 0 else { return }
        tableView.scrollToRow(at: IndexPath(row: row, section: 0), at: .bottom, animated: true)
    }

    @objc private func onConnectTap() {
        switch viewModel.connectionState.value {
        case .idle, .disconnected:
            viewModel.connect()
        case .connecting, .connected:
            viewModel.disconnect()
        case .disconnecting:
            break
        }
    }

    @objc private func onSendTap() {
        guard let text = messageTextField.text, !text.isEmpty else { return }
        messageTextField.text = ""
        viewModel.send(text: text)
    }
}

extension BASocketDemoViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.messages.value.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BASocketMessageCell.reuseIdentifier, for: indexPath) as! BASocketMessageCell
        let item = viewModel.messages.value[indexPath.row]
        cell.configure(content: item.content, type: item.type, isOutgoing: item.isOutgoing, timestamp: item.timestamp)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        60
    }
}

extension BASocketDemoViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onSendTap()
        return true
    }
}
