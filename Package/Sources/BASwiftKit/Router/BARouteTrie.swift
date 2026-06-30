//
//  BARouteTrie.swift
//  BASwiftKit
//
//  Created by boai on 2026/06/30.
//

import Foundation

// MARK: - Route Trie

/// 路由匹配前缀树（Trie）。
///
/// 取代「字典精确匹配 + 动态 Pattern 数组逐条跑正则」的旧方案，把按路径分段组织的路由
/// 存入一棵树。匹配时只需沿路径段逐层下探，复杂度从 **O(路由总数)** 降到
/// **O(路径段数)**，与已注册路由的数量无关 —— 这是适配「上千条路由」大型工程的关键。
///
/// ## 支持的 Pattern 语法
///
/// | 段类型 | 写法 | 说明 |
/// |--------|------|------|
/// | 静态段 | `user` | 精确匹配（大小写不敏感，与旧实现一致） |
/// | 参数段 | `:userId` | 匹配任意单段，并以 `userId` 为键提取值 |
/// | 通配段 | `*` | 匹配其后的所有剩余段（贪婪，需置于 Pattern 末尾） |
///
/// ## 匹配优先级（最具体者优先）
///
/// 同一层级若同时存在多种分支，按 **静态段 > 参数段 > 通配段** 的顺序选择，
/// 保证 `/user/profile` 在同时注册了 `/user/:name` 时仍命中更精确的静态路由。
///
/// - Note: 本类型非线程安全，由调用方（`BARouter`）持锁保护。
final class BARouteTrie {

    // MARK: - Node

    /// Trie 节点。
    private final class Node {
        /// 静态子节点（键为小写化后的段）。
        var staticChildren: [String: Node] = [:]
        /// 参数子节点（`:name`）。同层级仅保留一个，重复注册以最后一次为准。
        var paramChild: (name: String, node: Node)?
        /// 该节点处注册的通配路由（`*`），命中后吞掉剩余全部段。
        var wildcardConfig: BARouteConfig?
        /// 该节点作为终点时对应的路由配置。
        var terminalConfig: BARouteConfig?
    }

    // MARK: - State

    private let root = Node()

    /// 通配 `*` 命中时，被通配的剩余路径在参数字典中的键。
    /// 例：注册 `/web/*`，打开 `/web/a/b` → 参数 `["*": "a/b"]`。
    static let wildcardKey = "*"

    // MARK: - Insert

    /// 插入 / 覆盖一条路由。
    ///
    /// - Parameters:
    ///   - pattern: 路由 Pattern，如 `/user/detail/:userId`、`/web/*`。
    ///   - config: 对应的路由配置。
    func insert(_ pattern: String, config: BARouteConfig) {
        let segments = Self.segments(of: pattern)
        var node = root

        for segment in segments {
            if segment == "*" {
                // 通配段：直接挂在当前节点，匹配阶段会吞掉剩余所有段。
                node.wildcardConfig = config
                return
            } else if segment.hasPrefix(":") {
                let name = String(segment.dropFirst())
                if let existing = node.paramChild {
                    // 同层已有参数段：复用节点，但参数名以最后一次注册为准。
                    node.paramChild = (name, existing.node)
                    node = existing.node
                } else {
                    let child = Node()
                    node.paramChild = (name, child)
                    node = child
                }
            } else {
                let key = segment.lowercased()
                if let existing = node.staticChildren[key] {
                    node = existing
                } else {
                    let child = Node()
                    node.staticChildren[key] = child
                    node = child
                }
            }
        }
        node.terminalConfig = config
    }

    // MARK: - Search

    /// 查找匹配 `path` 的路由配置，并提取路径参数。
    ///
    /// - Parameter path: 已归一化的路径（如 `/user/detail/123`）。
    /// - Returns: 命中的配置及解析出的路径参数；未命中返回 `nil`。
    func search(_ path: String) -> (config: BARouteConfig, pathParams: [String: String])? {
        let segments = Self.segments(of: path)
        var params: [String: String] = [:]
        guard let config = match(node: root, segments: segments, index: 0, params: &params) else {
            return nil
        }
        return (config, params)
    }

    /// 递归匹配，按 静态 > 参数 > 通配 的优先级回溯。
    private func match(node: Node, segments: [String], index: Int, params: inout [String: String]) -> BARouteConfig? {
        // 已消费完所有路径段：命中当前节点的终点配置。
        if index == segments.count {
            return node.terminalConfig
        }

        let segment = segments[index]

        // 1. 静态段（最高优先级）
        if let child = node.staticChildren[segment.lowercased()],
           let hit = match(node: child, segments: segments, index: index + 1, params: &params) {
            return hit
        }

        // 2. 参数段
        if let (name, child) = node.paramChild {
            let saved = params[name]
            params[name] = segment
            if let hit = match(node: child, segments: segments, index: index + 1, params: &params) {
                return hit
            }
            params[name] = saved // 回溯：当前分支失败，撤销本段的参数写入
        }

        // 3. 通配段（吞掉剩余全部段），并把被通配的剩余路径以 "*" 为键写入参数，
        //    使 Handler（如 WebView 接管子路径）能拿到完整尾部路径。
        if let wildcard = node.wildcardConfig {
            params[BARouteTrie.wildcardKey] = segments[index...].joined(separator: "/")
            return wildcard
        }

        return nil
    }

    // MARK: - Remove / Reset

    /// 重置整棵树（用于 `unregister` 后由调用方按主表重建）。
    func removeAll() {
        root.staticChildren.removeAll()
        root.paramChild = nil
        root.wildcardConfig = nil
        root.terminalConfig = nil
    }

    // MARK: - Helpers

    /// 将路径 / Pattern 切分为段数组，忽略空段。
    ///
    /// 例：`/user/detail/123` → `["user", "detail", "123"]`；`/` → `[]`。
    private static func segments(of path: String) -> [String] {
        path.split(separator: "/", omittingEmptySubsequences: true).map(String.init)
    }
}
