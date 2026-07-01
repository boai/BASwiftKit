//
//  BADiskSpace.swift
//  BASwiftKit
//
//  Created by boai on 2026/07/01.
//

import Foundation

/// 卷宗磁盘空间信息。
public struct BADiskSpaceInfo: Sendable {
    /// 总容量（字节）。
    public let total: Int64
    /// 可用容量（字节）。
    public let free: Int64

    /// 已用容量（字节）。
    public var used: Int64 { total - free }

    /// 已用百分比（0～100）。
    public var usedPercentage: Double {
        guard total > 0 else { return 0 }
        return Double(used) / Double(total) * 100.0
    }

    /// 可用百分比（0～100）。
    public var freePercentage: Double {
        guard total > 0 else { return 0 }
        return Double(free) / Double(total) * 100.0
    }

    public init(total: Int64, free: Int64) {
        self.total = total
        self.free = free
    }
}

/// 查询任意已挂载卷宗的磁盘空间信息。使用 URL resource values 以兼容沙盒环境。
public enum BADiskSpace {

    /// 获取指定 URL 所对应卷宗的磁盘空间信息（默认根卷宗 `/`）。
    /// - Parameter url: 卷宗上的任意路径，默认为根目录。
    /// - Throws: `BADiskSpaceError.unavailable` 当无法读取容量信息时。
    /// - Returns: 磁盘空间信息。
    public static func info(for url: URL = URL(fileURLWithPath: "/")) throws -> BADiskSpaceInfo {
        let values = try url.resourceValues(forKeys: [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityKey,
        ])
        guard let total = values.volumeTotalCapacity,
              let free = values.volumeAvailableCapacity else {
            throw BADiskSpaceError.unavailable
        }
        return BADiskSpaceInfo(total: Int64(total), free: Int64(free))
    }

    /// 磁盘空间查询错误。
    public enum BADiskSpaceError: Error, Sendable {
        /// 无法读取卷宗容量信息（卷宗可能未挂载或权限不足）。
        case unavailable
    }
}
