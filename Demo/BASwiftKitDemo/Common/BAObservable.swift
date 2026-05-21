//
//  BAObservable.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import Foundation

/// 轻量绑定容器，用于 MVVM 中 ViewModel → View 的单向数据通知。
/// 无第三方依赖，开箱即用。
public final class BAObservable<Value> {

    public typealias Listener = (Value) -> Void

    private var listener: Listener?

    public private(set) var value: Value {
        didSet { listener?(value) }
    }

    public init(_ value: Value) {
        self.value = value
    }

    /// 监听变化，订阅时立即回调一次当前值
    public func bind(_ listener: @escaping Listener) {
        self.listener = listener
        listener(value)
    }

    /// 仅订阅后续变更，不触发立即回调
    public func observe(_ listener: @escaping Listener) {
        self.listener = listener
    }

    /// 主动更新
    public func update(_ newValue: Value) {
        self.value = newValue
    }
}
