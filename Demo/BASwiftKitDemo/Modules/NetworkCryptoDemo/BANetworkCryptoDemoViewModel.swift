//
//  BANetworkCryptoDemoViewModel.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/27.
//

import Foundation
import BASwiftKit

struct BANetworkCryptoDemoRow {
    let title: String
    let subtitle: String
    let action: () -> String
}

final class BANetworkCryptoDemoViewModel {

    let rows = BAObservable<[BANetworkCryptoDemoRow]>([])
    let logText = BAObservable<String>("")
    private var logs: [String] = []

    init() {
        rows.update([
            BANetworkCryptoDemoRow(title: "构建 GET 请求", subtitle: "BANetworkClient + BANetworkRequest", action: buildGETRequest),
            BANetworkCryptoDemoRow(title: "Endpoint 枚举", subtitle: "BANetworkEndpoint 统一接口定义", action: buildEndpointRequest),
            BANetworkCryptoDemoRow(title: "SHA 摘要", subtitle: "MD5 / SHA256 / SHA512", action: hashText),
            BANetworkCryptoDemoRow(title: "HMAC 签名", subtitle: "推荐接口签名使用 HMAC-SHA256", action: hmacText),
            BANetworkCryptoDemoRow(title: "AES 加解密", subtitle: "AES-CBC + PKCS7Padding", action: aesRoundtrip)
        ])
    }

    func run(row: BANetworkCryptoDemoRow) {
        appendLog(row.action())
    }

    private func buildGETRequest() -> String {
        let client = BANetworkClient(configuration: BANetworkConfiguration(
            baseURL: URL(string: "https://api.example.com"),
            defaultHeaders: ["Accept": "application/json"]
        ))
        let request = BANetworkRequest(path: "users", parameters: ["page": 1, "size": 20])
        do {
            let urlRequest = try client.makeURLRequest(request)
            return "GET URL：\(urlRequest.url?.absoluteString ?? "-")"
        } catch {
            return "构建失败：\(error.localizedDescription)"
        }
    }

    private func buildEndpointRequest() -> String {
        let endpoint = DemoAPI.user(id: 1001)
        let request = endpoint.ba_request
        return "Endpoint：\(request.method.rawValue) \(request.path)，headers=\(request.headers)"
    }

    private func hashText() -> String {
        let text = "BASwiftKit"
        return "text=\(text)\nMD5=\(text.ba_md5)\nSHA256=\(text.ba_sha256)\nSHA512=\(text.ba_sha512.prefix(32))..."
    }

    private func hmacText() -> String {
        let message = "page=1&size=20"
        let signature = message.ba_hmac(key: "demo-secret", algorithm: .sha256)
        return "message=\(message)\nHMAC-SHA256=\(signature)"
    }

    private func aesRoundtrip() -> String {
        let text = "接口缓存内容"
        let key = "1234567890abcdef"
        let iv = "abcdef1234567890"
        do {
            let encrypted = try text.ba_aesCBCEncryptedBase64(key: key, iv: iv)
            let decrypted = try encrypted.ba_aesCBCDecryptedFromBase64(key: key, iv: iv)
            return "明文：\(text)\n密文：\(encrypted)\n解密：\(decrypted)"
        } catch {
            return "AES 失败：\(error.localizedDescription)"
        }
    }

    private func appendLog(_ text: String) {
        let time = Date().ba_string(format: "HH:mm:ss")
        logs.append("[\(time)] \(text)")
        if logs.count > 40 { logs.removeFirst() }
        logText.update(logs.joined(separator: "\n\n"))
    }
}

private enum DemoAPI: BANetworkEndpoint {
    case user(id: Int)

    var path: String {
        switch self {
        case .user(let id):
            return "users/\(id)"
        }
    }

    var headers: [String: String] {
        ["X-Demo-Sign": "enabled"]
    }
}
