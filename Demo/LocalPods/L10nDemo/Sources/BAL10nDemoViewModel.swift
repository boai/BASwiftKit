//
//  BAL10nDemoViewModel.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit

public final class BAL10nDemoViewModel {

    public init() {}


    /// 当前语言，跟随 BALocalization
    let currentLanguage: BAObservable<String> = BAObservable(BALocalization.shared.currentLanguage)

    /// 在 Demo 内注册一次双语字典；多次注册会自动合并覆盖
    func registerTables() {
        BALocalization.shared.register([
            "l10n.title":      "Localization Demo",
            "l10n.greeting":   "Hello, BASwiftKit!",
            "l10n.cta":        "Tap the button",
            "l10n.lang.label": "Current language",
            "l10n.switch.en":  "English",
            "l10n.switch.zh":  "中文"
        ], for: "en")

        BALocalization.shared.register([
            "l10n.title":      "多语言演示",
            "l10n.greeting":   "你好，BASwiftKit！",
            "l10n.cta":        "试试点击按钮",
            "l10n.lang.label": "当前语言",
            "l10n.switch.en":  "English",
            "l10n.switch.zh":  "中文"
        ], for: "zh-Hans")
    }

    func setLanguage(_ lang: String) {
        BALocalization.shared.setLanguage(lang)
        currentLanguage.update(lang)
    }
}
