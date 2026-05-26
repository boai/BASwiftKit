//
//  BAObservableQueue.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/26.
//

import Foundation

/// 回调派发队列。
///
/// `BAObservable.bind(on:)` / `observe(on:)` 通过此枚举决定 listener 被调用的
/// 执行环境。组件化项目里 UI 绑定常用 `.main`，纯数据流通常用 `.current` 保持
/// 与调用方一致。
public enum BAObservableQueue {

    /// 在调用 `update(_:)` 的线程上同步回调。零开销，
    /// 由调用方负责保证已位于期望的线程。
    case current

    /// 主线程。若当前已是主线程则同步回调，否则 `DispatchQueue.main.async`。
    case main

    /// 全局默认优先级队列（`DispatchQueue.global()`）。
    /// 适合 listener 内部需要做计算密集型工作的场景。
    case global

    /// 自定义队列。会以 `async` 投递到该队列。
    case queue(DispatchQueue)

    /// 把回调闭包按当前枚举语义派发出去。
    @inlinable
    func ba_dispatch(_ work: @escaping () -> Void) {
        switch self {
        case .current:
            work()
        case .main:
            if Thread.isMainThread {
                work()
            } else {
                DispatchQueue.main.async(execute: work)
            }
        case .global:
            DispatchQueue.global().async(execute: work)
        case .queue(let q):
            q.async(execute: work)
        }
    }
}
