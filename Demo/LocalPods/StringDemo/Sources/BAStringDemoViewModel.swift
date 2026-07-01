//
//  BAStringDemoViewModel.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import Foundation
import BASwiftKit

public struct BAStringDemoResult {

    let title: String
    let value: String
}

public final class BAStringDemoViewModel {

    public init() {}

    let input: BAObservable<String> = BAObservable("hello@example.com")
    let results: BAObservable<[BAStringDemoResult]> = BAObservable([])

    func update(_ text: String) {
        input.update(text)
        recompute()
    }

    func recompute() {
        let raw = input.value
        results.update([
            BAStringDemoResult(title: "去空白",   value: raw.ba_trimmed.isEmpty ? "—" : raw.ba_trimmed),
            BAStringDemoResult(title: "是否邮箱", value: raw.ba_isEmail ? "✅ 是" : "❌ 否"),
            BAStringDemoResult(title: "是否手机号", value: raw.ba_isChinaMobile ? "✅ 是" : "❌ 否"),
            BAStringDemoResult(title: "MD5",     value: raw.ba_md5),
            BAStringDemoResult(title: "Base64",  value: raw.ba_base64Encoded ?? "—")
        ])
    }
}
