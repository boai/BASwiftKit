//
//  BADisposable.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/26.
//

import Foundation

/// 可释放的订阅句柄。
///
/// `BAObservable.bind` / `observe` 返回一个 `BADisposable`，调用 `dispose()`
/// 即可手动取消订阅；也可通过 `disposed(by:)` 扔进 `BADisposeBag`
/// 让宿主销毁时自动清理。
///
/// 实现类需保证 `dispose()` 多次调用安全（幂等）且线程安全，
/// 同一份订阅不会因为重复 dispose 触发多次清理逻辑。
public protocol BADisposable: AnyObject {

    /// 取消该订阅。多次调用安全。
    func dispose()
}

public extension BADisposable {

    /// 把订阅托管给指定的 `BADisposeBag`，
    /// 宿主释放（bag 被 deinit）时自动 `dispose()`。
    ///
    /// 典型用法：
    /// ```swift
    /// viewModel.items
    ///     .bind { [weak self] _ in self?.tableView.reloadData() }
    ///     .disposed(by: disposeBag)
    /// ```
    func disposed(by bag: BADisposeBag) {
        bag.ba_add(self)
    }
}

/// `BADisposable` 的通用实现：在第一次 `dispose()` 时执行注册的清理闭包，
/// 后续调用直接忽略。
///
/// 一般不需要业务代码直接构造，由 `BAObservable` 内部生成并返回。
public final class BAAnyDisposable: BADisposable {

    private let lock = NSLock()
    private var action: (() -> Void)?

    /// - Parameter action: 第一次 `dispose()` 时执行的清理闭包。
    public init(_ action: @escaping () -> Void) {
        self.action = action
    }

    /// 执行清理闭包并取消订阅；多次调用只会执行一次清理逻辑。
    public func dispose() {
        lock.lock()
        let toRun = action
        action = nil
        lock.unlock()
        toRun?()
    }

    deinit {
        // 句柄被释放时若仍未被显式 dispose（例如未放入 bag、调用方丢掉了引用），
        // 也要清理订阅，避免 observable 持有的闭包成为"野订阅"。
        dispose()
    }
}

/// 订阅生命周期容器。
///
/// 把若干 `BADisposable` 塞进 bag，bag 自身被销毁时会自动 `dispose()` 所有成员。
/// 通常作为 `ViewController` / `View` / `Coordinator` 的属性，使订阅生命周期
/// 与宿主一致。
///
/// 线程安全：内部使用 `NSLock` 保护，可在任意线程添加 / 销毁。
///
/// ```swift
/// final class MyVC: UIViewController {
///     private let disposeBag = BADisposeBag()
///
///     func bindViewModel() {
///         viewModel.items
///             .bind { [weak self] in self?.render($0) }
///             .disposed(by: disposeBag)
///     }
/// }
/// ```
public final class BADisposeBag {

    private let lock = NSLock()
    private var disposables: [BADisposable] = []
    private var isDisposed = false

    /// 创建空订阅容器。
    public init() {}

    /// 加入一个 disposable。若 bag 已 dispose（一般是销毁过程中），传入的
    /// disposable 立即被 `dispose()`，不会积压。
    public func ba_add(_ disposable: BADisposable) {
        lock.lock()
        if isDisposed {
            lock.unlock()
            disposable.dispose()
            return
        }
        disposables.append(disposable)
        lock.unlock()
    }

    /// 立即销毁所有订阅并清空容器。多次调用安全。
    /// 业务上一般不需要主动调用，bag 被释放时会自动触发。
    public func ba_dispose() {
        lock.lock()
        guard !isDisposed else {
            lock.unlock()
            return
        }
        let toDispose = disposables
        disposables.removeAll()
        isDisposed = true
        lock.unlock()
        for d in toDispose { d.dispose() }
    }

    deinit {
        ba_dispose()
    }
}
