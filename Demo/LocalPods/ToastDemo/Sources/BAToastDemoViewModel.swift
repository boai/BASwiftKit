//
//  BAToastDemoViewModel.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit
import DemoCommon

public struct BAToastDemoOption {

    let title: String
    let message: String
    let style: BAToast.Style
    let color: UIColor
}

public final class BAToastDemoViewModel {

    public init() {}

    let options: BAObservable<[BAToastDemoOption]> = BAObservable([])

    func loadData() {
        options.update([
            BAToastDemoOption(title: "默认",
                            message: "这是一条默认 Toast",
                            style: .default,
                            color: UIColor(white: 0, alpha: 0.78)),
            BAToastDemoOption(title: "成功",
                            message: "保存成功 🎉",
                            style: .success,
                            color: BAAppTheme.success),
            BAToastDemoOption(title: "警告",
                            message: "网络较差，请稍后重试",
                            style: .warning,
                            color: BAAppTheme.warning),
            BAToastDemoOption(title: "错误",
                            message: "操作失败，请检查参数",
                            style: .error,
                            color: BAAppTheme.danger)
        ])
    }

    func show(_ option: BAToastDemoOption) {
        BAToast.ba_show(option.message, style: option.style)
    }
}
