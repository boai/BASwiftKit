//
//  BAObservable.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

import Foundation

/// 轻量响应式数据容器，MVVM / 组件化项目里 ViewModel → View 数据通知的基础设施。
///
/// 设计目标：
/// - **多监听者**：同一个 observable 可被任意数量的 View / Cell / Controller 并行订阅，
///   后来者不会覆盖前者。每次订阅返回一个 `BADisposable`，可手动 `dispose()`
///   或通过 `disposed(by: bag)` 托管给 `BADisposeBag`。
/// - **线程安全**：值的读写和订阅列表维护都受 `NSLock` 保护，可在任意线程
///   `update(_:)`、任意线程 `bind` / `observe`。
/// - **可指定回调队列**：通过 `bind(on:)` / `observe(on:)` 把 listener 派发到
///   主线程 / 自定义队列；默认 `.current` 沿用调用方线程，零开销。
/// - **支持去重**：`distinct()` 派生出一条只在值变化时才向下游传播的 observable
///   （要求 `Value: Equatable`）。
///
/// ```swift
/// // 声明
/// let count = BAObservable<Int>(0)
///
/// // 订阅（自动注入 disposeBag）
/// count.bind(on: .main) { [weak self] v in
///     self?.label.text = "\(v)"
/// }.disposed(by: disposeBag)
///
/// // 任意线程更新
/// DispatchQueue.global().async {
///     count.update(42)
/// }
/// ```
public class BAObservable<Value> {

    /// 观察者闭包类型，参数为最新值。
    public typealias Listener = (Value) -> Void

    // MARK: - Subscription

    /// 单条订阅记录。`id` 用于在 `dispose` 时定位并移除。
    fileprivate final class Subscription {
        let id: UUID
        let queue: BAObservableQueue
        let listener: Listener

        init(id: UUID, queue: BAObservableQueue, listener: @escaping Listener) {
            self.id = id
            self.queue = queue
            self.listener = listener
        }
    }

    // MARK: - State

    private let lock = NSLock()
    private var _value: Value
    private var subscriptions: [Subscription] = []

    // MARK: - Init

    /// 创建响应式数据容器。
    ///
    /// - Parameter value: 初始值，后续 `bind` 会立即收到该值。
    public init(_ value: Value) {
        self._value = value
    }

    // MARK: - Value

    /// 当前值。线程安全读。注意：返回的是值类型的快照，
    /// 不要在外部对引用类型做 mutation 后期望 observable 自动感知 ——
    /// 显式调用 `update(_:)` 才会通知订阅者。
    public var value: Value {
        lock.lock()
        defer { lock.unlock() }
        return _value
    }

    /// 主动更新值并通知所有订阅者。
    ///
    /// 调用线程不限。每个 listener 按各自注册时指定的 `BAObservableQueue`
    /// 派发；`.current` 表示在本次 `update(_:)` 的调用线程上同步执行。
    public func update(_ newValue: Value) {
        lock.lock()
        _value = newValue
        let toNotify = subscriptions
        lock.unlock()

        for sub in toNotify {
            sub.queue.ba_dispatch { sub.listener(newValue) }
        }
    }

    // MARK: - Subscribe

    /// 订阅变化，**订阅时立即用当前值回调一次**（典型的 UI 初始化绑定场景）。
    ///
    /// - Parameters:
    ///   - queue: listener 执行的队列。默认 `.current`，调用方自行保证线程；
    ///     UI 绑定建议传 `.main`。
    ///   - listener: 回调闭包。建议 `[weak self]` 捕获以避免 retain cycle。
    /// - Returns: 订阅句柄，调 `dispose()` 或 `disposed(by:)` 取消。
    @discardableResult
    public func bind(on queue: BAObservableQueue = .current,
                     _ listener: @escaping Listener) -> BADisposable {
        let sub = Subscription(id: UUID(), queue: queue, listener: listener)
        lock.lock()
        subscriptions.append(sub)
        let currentValue = _value
        lock.unlock()

        queue.ba_dispatch { listener(currentValue) }
        return makeDisposable(for: sub.id)
    }

    /// 订阅后续变化，**不会**立即回调当前值。
    ///
    /// - Parameters:
    ///   - queue: 同 `bind(on:_:)`。
    ///   - listener: 回调闭包。
    /// - Returns: 订阅句柄。
    @discardableResult
    public func observe(on queue: BAObservableQueue = .current,
                        _ listener: @escaping Listener) -> BADisposable {
        let sub = Subscription(id: UUID(), queue: queue, listener: listener)
        lock.lock()
        subscriptions.append(sub)
        lock.unlock()

        return makeDisposable(for: sub.id)
    }

    // MARK: - Private

    private func makeDisposable(for id: UUID) -> BADisposable {
        // 弱持有 self：disposable 自己被释放（或被 dispose）时移除订阅。
        // 即使外部丢掉 disposable 引用，AnyDisposable.deinit 会自动 dispose。
        return BAAnyDisposable { [weak self] in
            self?.removeSubscription(id: id)
        }
    }

    private func removeSubscription(id: UUID) {
        lock.lock()
        subscriptions.removeAll { $0.id == id }
        lock.unlock()
    }
}

// MARK: - distinct (Equatable)

public extension BAObservable where Value: Equatable {

    /// 派生一条只在值真正变化时才向下游传播的 observable。
    ///
    /// 派生 observable 内部订阅上游：上游每次 `update`，先与上次值比较，
    /// 不同才向下游传播。派生 observable 的初始值与调用时刻的上游值一致。
    ///
    /// 派生 observable 被释放时会自动取消上游订阅（无内存泄漏）。
    ///
    /// ```swift
    /// // 高频更新但 UI 只想刷"变化时"
    /// viewModel.scrollOffset.distinct()
    ///     .bind(on: .main) { [weak self] offset in
    ///         self?.updateHeader(offset)
    ///     }.disposed(by: disposeBag)
    /// ```
    func distinct() -> BAObservable<Value> {
        return BADistinctObservable(source: self)
    }
}

/// `distinct()` 的内部派生类型。负责持有上游订阅句柄并在 `deinit` 时清理。
private final class BADistinctObservable<Value: Equatable>: BAObservable<Value> {

    private var upstreamDisposable: BADisposable?

    init(source: BAObservable<Value>) {
        super.init(source.value)
        // 用 source.value 作为基线，比上游已经"发生过"的最后一次值。
        var last = source.value
        upstreamDisposable = source.observe(on: .current) { [weak self] newValue in
            guard let self = self else { return }
            if newValue != last {
                last = newValue
                self.update(newValue)
            }
        }
    }

    deinit {
        upstreamDisposable?.dispose()
    }
}
