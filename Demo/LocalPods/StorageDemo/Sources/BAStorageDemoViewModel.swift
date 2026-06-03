//
//  BAStorageDemoViewModel.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/27.
//

import Foundation
import BASwiftKit

public struct BAStorageDemoRow {
    let title: String
    let subtitle: String
    let action: () -> String
}

public final class BAStorageDemoViewModel {

    struct Profile: Codable {
        let name: String
        let level: Int
    }

    @BAUserDefault(key: "demo_storage_launch_count", defaultValue: 0)
    private var launchCount: Int

    @BAUserDefaultCodable(key: "demo_storage_profile", defaultValue: Profile(name: "未设置", level: 0))
    private var profile: Profile

    let rows = BAObservable<[BAStorageDemoRow]>([])
    let logText = BAObservable<String>("")
    private var logs: [String] = []

    public init() {
        rows.update([
            BAStorageDemoRow(title: "写入文本文件", subtitle: "BAFileManager 相对路径自动创建目录", action: writeTextFile),
            BAStorageDemoRow(title: "读取文本文件", subtitle: "从 Documents/demo/storage-note.txt 读取", action: readTextFile),
            BAStorageDemoRow(title: "写入 JSON 文件", subtitle: "Codable → Documents/demo/profile.json", action: writeJSONFile),
            BAStorageDemoRow(title: "读取 JSON 文件", subtitle: "Documents JSON → Codable", action: readJSONFile),
            BAStorageDemoRow(title: "UserDefaults 计数", subtitle: "property wrapper + 静态便捷方法", action: updateUserDefaults),
            BAStorageDemoRow(title: "查看缓存大小", subtitle: "Caches + tmp 格式化大小", action: showCacheSize),
            BAStorageDemoRow(title: "清理缓存目录", subtitle: "异步清理并返回剩余大小", action: clearCache)
        ])
    }

    func run(row: BAStorageDemoRow) {
        appendLog(row.action())
    }

    private func writeTextFile() -> String {
        let text = "BASwiftKit 文件写入示例：\(Date().ba_string(format: "HH:mm:ss"))"
        do {
            try BAFileManager.ba_write(text, to: "demo/storage-note.txt")
            return "写入成功：demo/storage-note.txt"
        } catch {
            return "写入失败：\(error.localizedDescription)"
        }
    }

    private func readTextFile() -> String {
        do {
            let text = try BAFileManager.ba_readString(from: "demo/storage-note.txt")
            return "读取成功：\(text)"
        } catch {
            return "读取失败：\(error.localizedDescription)"
        }
    }

    private func writeJSONFile() -> String {
        let value = Profile(name: "博爱", level: Int.random(in: 1...99))
        do {
            try BAFileManager.ba_writeJSON(value, to: "demo/profile.json")
            return "JSON 写入成功：\(value.name) Lv.\(value.level)"
        } catch {
            return "JSON 写入失败：\(error.localizedDescription)"
        }
    }

    private func readJSONFile() -> String {
        do {
            let value = try BAFileManager.ba_readJSON(from: "demo/profile.json", type: Profile.self)
            return "JSON 读取成功：\(value.name) Lv.\(value.level)"
        } catch {
            return "JSON 读取失败：\(error.localizedDescription)"
        }
    }

    private func updateUserDefaults() -> String {
        launchCount += 1
        profile = Profile(name: "开发者", level: launchCount)
        BAUserDefaults.ba_set("已写入", forKey: "demo_storage_status")
        let status: String = BAUserDefaults.ba_value(forKey: "demo_storage_status", default: "未写入")
        return "UserDefaults：count=\(launchCount), profile=\(profile.name) Lv.\(profile.level), status=\(status)"
    }

    private func showCacheSize() -> String {
        "当前缓存大小：\(BACache.ba_formattedSize)"
    }

    private func clearCache() -> String {
        BACache.ba_clearAsync { [weak self] success, remainingBytes in
            self?.appendLog("异步清理完成：\(success ? "成功" : "部分失败")，剩余 \(BAFileManager.ba_formattedSize(remainingBytes))")
        }
        return "已开始异步清理缓存目录"
    }

    private func appendLog(_ text: String) {
        let time = Date().ba_string(format: "HH:mm:ss")
        logs.append("[\(time)] \(text)")
        if logs.count > 40 { logs.removeFirst() }
        logText.update(logs.joined(separator: "\n"))
    }
}
