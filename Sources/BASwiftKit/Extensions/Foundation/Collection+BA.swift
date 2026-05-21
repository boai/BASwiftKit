//
//  Collection+BA.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

import Foundation

public extension Collection {
    /// 安全下标：越界返回 nil
    func ba_safe(_ index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

public extension Array where Element: Hashable {
    /// 去重，保持原顺序
    func ba_unique() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}

public extension Array {
    /// 按指定大小分块
    func ba_chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

public extension Dictionary {
    /// 合并另一个字典（other 优先）
    func ba_merged(with other: [Key: Value]) -> [Key: Value] {
        merging(other) { _, new in new }
    }
}
