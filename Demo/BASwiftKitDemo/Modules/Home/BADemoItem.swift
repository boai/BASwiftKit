//
//  BADemoItem.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit

/// Home 列表中的一个 Demo 卡片数据模型
struct BADemoItem {
    let title: String
    let subtitle: String
    let iconSystemName: String
    let gradient: [UIColor]
    let builder: () -> UIViewController
}
