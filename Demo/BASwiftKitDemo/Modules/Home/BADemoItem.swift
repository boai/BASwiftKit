//
//  BADemoItem.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit

/// Home 列表中的一个 Demo 卡片数据模型。
///
/// 每个 Demo 对应一条 BARouter 路由，点击卡片时通过
/// `BARouter.shared.open(route)` 触发跳转，由各 demo pod
/// 提供的 VC 响应。
struct BADemoItem {
    /// 展示标题
    let title: String
    /// 展示副标题
    let subtitle: String
    /// SF Symbol 图标名称
    let iconSystemName: String
    /// 渐变背景色数组
    let gradient: [UIColor]
    /// BARouter 路由路径，如 "/demo/animation"
    let route: String
}
