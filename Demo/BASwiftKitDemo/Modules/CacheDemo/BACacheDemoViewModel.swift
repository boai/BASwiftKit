//
//  BACacheDemoViewModel.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/26.
//

import UIKit
import BASwiftKit

final class BACacheDemoViewModel {

    struct Row {
        let title: String
        let subtitle: String
        let action: () -> Void
    }

    let rows = BAObservable<[Row]>([])
    let logText = BAObservable<String>("")

    private let memoryCache = BAMemoryCache(costLimit: 5 * 1024 * 1024, countLimit: 100)
    private let diskCache = BADiskCache(name: "com.baswiftkit.demo.disk", sizeLimit: 10 * 1024 * 1024)
    private lazy var hybridCache = BAHybridCache(memoryCache: memoryCache, diskCache: diskCache)
    private var logs: [String] = []

    init() {
        refreshRows()
    }

    private func refreshRows() {
        rows.update([
            Row(title: "📝 写入模型缓存", subtitle: "Codable 对象 → HybridCache", action: { [weak self] in self?.writeModel() }),
            Row(title: "📖 读取模型缓存", subtitle: "HybridCache → Codable 对象", action: { [weak self] in self?.readModel() }),
            Row(title: "📝 写入字符串缓存", subtitle: "String → HybridCache", action: { [weak self] in self?.writeString() }),
            Row(title: "📖 读取字符串缓存", subtitle: "HybridCache → String", action: { [weak self] in self?.readString() }),
            Row(title: "⏱ 写入过期缓存", subtitle: "3 秒后过期", action: { [weak self] in self?.writeExpiringCache() }),
            Row(title: "🧹 清理过期缓存", subtitle: "手动清理所有过期条目", action: { [weak self] in self?.cleanExpired() }),
            Row(title: "📊 查看缓存大小", subtitle: "当前磁盘缓存总大小", action: { [weak self] in self?.showSize() }),
            Row(title: "🗑 清空全部缓存", subtitle: "Memory + Disk 全部清空", action: { [weak self] in self?.clearAll() })
        ])
    }

    // MARK: - Actions

    private func writeModel() {
        let user = BACacheDemoUser(id: Int.random(in: 1...9999), name: "博爱\(Int.random(in: 1...100))", age: Int.random(in: 18...60))
        hybridCache.ba_setObject(user, forKey: "demo_user")
        appendLog("✅ 写入模型: \(user)")
    }

    private func readModel() {
        if let user = hybridCache.ba_object(forKey: "demo_user", type: BACacheDemoUser.self) {
            appendLog("📖 读取模型: id=\(user.id), name=\(user.name), age=\(user.age)")
        } else {
            appendLog("❌ 未找到模型缓存或已过期")
        }
    }

    private func writeString() {
        let token = "demo_token_\(UUID().uuidString.prefix(8))"
        hybridCache.ba_setString(token, forKey: "demo_token")
        appendLog("✅ 写入字符串: \(token)")
    }

    private func readString() {
        if let token = hybridCache.ba_string(forKey: "demo_token") {
            appendLog("📖 读取字符串: \(token)")
        } else {
            appendLog("❌ 未找到字符串缓存或已过期")
        }
    }

    private func writeExpiringCache() {
        let value = "这条缓存将在 3 秒后过期"
        let expiry = Date().addingTimeInterval(3)
        hybridCache.ba_setString(value, forKey: "expiring_key", expiry: expiry)
        appendLog("⏱ 写入过期缓存（3秒后过期）")
    }

    private func cleanExpired() {
        hybridCache.ba_cleanExpired { [weak self] in
            self?.appendLog("🧹 过期缓存清理完成")
        }
    }

    private func showSize() {
        let size = hybridCache.ba_totalDiskSize()
        let formatted = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
        appendLog("📊 磁盘缓存大小: \(formatted)")
    }

    private func clearAll() {
        hybridCache.ba_clear()
        appendLog("🗑 全部缓存已清空")
    }

    private func appendLog(_ text: String) {
        let time = Date().ba_string(format: "HH:mm:ss")
        logs.append("[\(time)] \(text)")
        if logs.count > 50 { logs.removeFirst() }
        logText.update(logs.joined(separator: "\n"))
    }
}

struct BACacheDemoUser: Codable {
    let id: Int
    let name: String
    let age: Int
}
