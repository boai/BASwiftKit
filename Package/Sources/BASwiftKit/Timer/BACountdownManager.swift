//
//  BACountdownManager.swift
//  BASwiftKit
//
//  Created by boai on 2026/06/02.
//

import Foundation

/// 倒计时状态，封装剩余时间与格式化输出。
public struct BACountdownStatus: Equatable {

    /// 剩余总秒数（最小为 0，不会出现负数）。
    public let remainingSeconds: Int

    /// 是否已到期。
    public var isExpired: Bool { remainingSeconds <= 0 }

    /// 小时部分。
    public var hours: Int { remainingSeconds / 3600 }
    /// 分钟部分（0~59）。
    public var minutes: Int { (remainingSeconds % 3600) / 60 }
    /// 秒部分（0~59）。
    public var seconds: Int { remainingSeconds % 60 }

    /// 格式化字符串。
    ///
    /// - 大于等于 1 小时：`"01:23:45"`
    /// - 不足 1 小时：`"23:45"`
    /// - 已到期：`"00:00"`
    public var formatted: String {
        guard !isExpired else { return "00:00" }
        if remainingSeconds >= 3600 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - BACountdownManager

/// 列表倒计时管理器。
///
/// 为每个 Cell / ViewModel 提供一个共享的倒计时驱动，仅维护单个底层 `Timer`，
/// 自动在有观察者时启动、无观察者时停止，避免列表中大量独立 Timer 导致的性能问题。
///
/// ## 设计要点
///
/// - **基于截止时间计算**：每个观察者只需提供一个 `endDate`，
///   每次 tick 计算 `endDate.timeIntervalSinceNow`，
///   因此列表刷新后倒计时依然准确，不依赖累减计数。
/// - **共享 Timer**：所有观察者共用一个 Timer，定时器添加到 `.common` RunLoop mode，
///   避免 `UIScrollView` 滚动时倒计时停摆。
/// - **自动生命周期**：首个 `register` 自动启动 Timer，最后一个 `unregister` 自动停止。
/// - **线程安全**：内部使用 `NSLock` 保护观察者字典。
///
/// ## 典型用法
///
/// ```swift
/// // Cell 出现时注册
/// let id = BACountdownManager.shared.register(endDate: item.endDate) { [weak cell] status in
///     cell?.countdownLabel.text = status.formatted
///     if status.isExpired { cell?.showExpiredState() }
/// }
/// cell.countdownId = id
///
/// // Cell 消失/复用时取消注册
/// BACountdownManager.shared.unregister(id: cell.countdownId)
/// ```
///
/// ## App 生命周期
///
/// 建议在 `AppDelegate` 或 `SceneDelegate` 中监听前后台切换，
/// 进入后台时调用 `pause()` 节省电量，回到前台时调用 `resume()` 恢复。
public final class BACountdownManager {

    /// 全局共享实例，tick 间隔默认 0.5 秒。
    public static let shared = BACountdownManager()

    /// Timer 是否正在运行中。
    public private(set) var isRunning: Bool = false

    /// 每次 tick 的时间间隔。
    public let tickInterval: TimeInterval

    private var timer: Timer?
    private let lock = NSLock()
    private var observers: [String: (endDate: Date, callback: (BACountdownStatus) -> Void)] = [:]
    private var isPaused: Bool = false

    // MARK: - Init

    /// 创建倒计时管理器。
    ///
    /// - Parameter tickInterval: Timer 触发间隔，默认 0.5 秒。
    ///   过短会浪费 CPU，过长会导致倒计时跳秒不流畅。
    public init(tickInterval: TimeInterval = 0.5) {
        self.tickInterval = tickInterval
    }

    // MARK: - Register / Unregister

    /// 注册一个倒计时观察者。
    ///
    /// 注册后会立即用当前剩余时间回调一次，之后每次 tick 都会回调，直到 `unregister`。
    /// 当 `endDate` 已过期时，回调中的 `status.isExpired` 为 `true`，
    /// 并在下一次 tick 时自动移除该观察者。
    ///
    /// - Parameters:
    ///   - endDate: 倒计时截止时间。基于设备当前时间计算剩余。
    ///   - onTick: 每次 tick 的回调闭包。**注意：回调线程不固定**，
    ///     如需更新 UI 请在闭包内显式调度到主线程。
    /// - Returns: 观察者标识符，用于后续 `unregister(id:)`。
    @discardableResult
    public func register(endDate: Date,
                         onTick: @escaping (BACountdownStatus) -> Void) -> String {
        let id = UUID().uuidString
        lock.lock()
        observers[id] = (endDate, onTick)
        if observers.count == 1, !isPaused {
            startTimer()
        }
        lock.unlock()

        // 立即通知一次当前状态
        onTick(Self.status(for: endDate))

        return id
    }

    /// 取消注册观察者。
    ///
    /// 当所有观察者都被移除后，内部 Timer 自动停止。
    ///
    /// - Parameter id: `register(endDate:onTick:)` 返回的标识符。
    public func unregister(id: String) {
        lock.lock()
        observers.removeValue(forKey: id)
        if observers.isEmpty {
            stopTimer()
        }
        lock.unlock()
    }

    // MARK: - Pause / Resume

    /// 暂停内部 Timer。
    ///
    /// 推荐在 `UIApplication.didEnterBackgroundNotification` 中调用，
    /// 避免后台无意义消耗。
    public func pause() {
        lock.lock()
        isPaused = true
        stopTimer()
        lock.unlock()
    }

    /// 恢复内部 Timer。
    ///
    /// 推荐在 `UIApplication.willEnterForegroundNotification` 中调用。
    /// 恢复后会基于 `endDate.timeIntervalSinceNow` 重新计算，
    /// 因此暂停期间的倒计时依然是准确的。
    public func resume() {
        lock.lock()
        isPaused = false
        if !observers.isEmpty {
            startTimer()
        }
        lock.unlock()
    }

    // MARK: - Private

    private func startTimer() {
        guard timer == nil else { return }
        let t = Timer(timeInterval: tickInterval, repeats: true) { [weak self] _ in
            self?.tick()
        }
        // 添加到 .common mode，确保滚动时也能正常刷新
        RunLoop.main.add(t, forMode: .common)
        timer = t
        isRunning = true
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }

    private func tick() {
        // 快照 + 清空再分发，减少锁持有时间
        lock.lock()
        let snapshot = observers
        lock.unlock()

        guard !snapshot.isEmpty else { return }

        var expiredIDs: [String] = []
        for (id, observer) in snapshot {
            let status = Self.status(for: observer.endDate)
            observer.callback(status)
            if status.isExpired {
                expiredIDs.append(id)
            }
        }

        // 清理已过期的观察者
        if !expiredIDs.isEmpty {
            lock.lock()
            for id in expiredIDs {
                observers.removeValue(forKey: id)
            }
            if observers.isEmpty {
                stopTimer()
            }
            lock.unlock()
        }
    }

    private static func status(for endDate: Date) -> BACountdownStatus {
        let remaining = max(0, Int(endDate.timeIntervalSinceNow))
        return BACountdownStatus(remainingSeconds: remaining)
    }
}
