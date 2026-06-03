//
//  BASocketDemoViewModel.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/28.
//

import UIKit
import BASwiftKit

final class BASocketDemoViewModel {

    struct MessageItem {
        let id = UUID()
        let content: String
        let type: String
        let isOutgoing: Bool
        let timestamp: String
    }

    let messages: BAObservable<[MessageItem]> = BAObservable([])
    let connectionState: BAObservable<BASocketState> = BAObservable(.idle)
    let url: URL

    private let client: BASocketClient
    private let disposeBag = BADisposeBag()
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    init(url: URL = URL(string: "wss://ws.postman-echo.com/raw")!) {
        self.url = url
        let config = BASocketConfiguration(url: url, heartbeatInterval: 30, maxReconnectAttempts: 3)
        client = BASocketClient(configuration: config)

        client.state.bind(on: .main) { [weak self] s in
            self?.connectionState.update(s)
        }.disposed(by: disposeBag)

        client.onEvent = { [weak self] event in
            self?.handleEvent(event)
        }
    }

    func connect() {
        client.connect()
    }

    func disconnect() {
        client.disconnect()
    }

    func send(text: String) {
        guard !text.isEmpty else { return }
        appendMessage(content: text, type: "TEXT", isOutgoing: true)
        client.send(text: text)
    }

    func sendJSON(_ dict: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let text = String(data: data, encoding: .utf8) else { return }
        appendMessage(content: text, type: "JSON", isOutgoing: true)
        client.send(text: text)
    }

    private func appendMessage(content: String, type: String, isOutgoing: Bool) {
        let item = MessageItem(
            content: content,
            type: type,
            isOutgoing: isOutgoing,
            timestamp: dateFormatter.string(from: Date())
        )
        messages.update(messages.value + [item])
    }

    private func handleEvent(_ event: BASocketEvent) {
        switch event {
        case .message(let msg):
            let content = msg.text ?? msg.rawData.base64EncodedString()
            let type: String
            switch msg.type {
            case .json:  type = "JSON"
            case .binary: type = "BINARY"
            default:     type = "TEXT"
            }
            DispatchQueue.main.async { [weak self] in
                self?.appendMessage(content: content, type: type, isOutgoing: false)
            }
        default:
            break
        }
    }
}
