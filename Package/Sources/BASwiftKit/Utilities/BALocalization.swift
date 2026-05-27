//
//  BALocalization.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

import Foundation

/// 运行时切换语言的 i18n 工具。
///
/// 两种供数方式（可叠加，运行时字典优先）：
/// 1. **运行时字典**：`BALocalization.register(["greeting": "Hello"], for: "en")`
/// 2. **.lproj/.strings 文件**：和 Apple 标准一致，从 `Bundle.main` 的 `<lang>.lproj/Localizable.strings` 读取
///
/// 用法：
/// ```swift
/// BALocalization.shared.setLanguage("zh-Hans")
/// label.text = "greeting".ba_localized
/// ```
public final class BALocalization {

    /// 全局共享本地化管理器。
    public static let shared = BALocalization()

    /// 语言切换通知
    public static let languageDidChangeNotification = Notification.Name("BALocalization.languageDidChange")

    private let storageKey = "BALocalization.currentLanguage"
    private var runtimeTables: [String: [String: String]] = [:]
    /// 当前语言标识，例如 `zh-Hans`、`en`。
    public private(set) var currentLanguage: String

    private init() {
        let saved = UserDefaults.standard.string(forKey: storageKey)
        self.currentLanguage = saved
            ?? Locale.preferredLanguages.first
            ?? "en"
    }

    /// 切换语言并发通知
    public func setLanguage(_ language: String) {
        guard language != currentLanguage else { return }
        currentLanguage = language
        UserDefaults.standard.set(language, forKey: storageKey)
        NotificationCenter.default.post(name: Self.languageDidChangeNotification, object: language)
    }

    /// 注册某种语言的翻译字典（会合并到已有字典）
    public func register(_ table: [String: String], for language: String) {
        var existing = runtimeTables[language] ?? [:]
        existing.merge(table) { _, new in new }
        runtimeTables[language] = existing
    }

    /// 查询某 key 在当前语言下的翻译
    public func localized(_ key: String,
                          fallback: String? = nil,
                          bundle: Bundle = .main,
                          table: String = "Localizable") -> String {
        // 1. 优先运行时字典
        if let value = runtimeTables[currentLanguage]?[key] {
            return value
        }
        // 2. 其次 .lproj 资源
        if let path = bundle.path(forResource: currentLanguage, ofType: "lproj"),
           let langBundle = Bundle(path: path) {
            let value = langBundle.localizedString(forKey: key, value: fallback ?? key, table: table)
            if value != key { return value }
        }
        // 3. 兜底
        return fallback ?? key
    }
}

public extension String {
    /// 取当前语言下对该 key 的翻译，若没注册则原样返回
    var ba_localized: String {
        BALocalization.shared.localized(self)
    }

    /// 带参数的翻译（按 `%@` / `%d` 占位顺序填充）
    func ba_localized(_ args: CVarArg...) -> String {
        String(format: BALocalization.shared.localized(self), arguments: args)
    }
}
