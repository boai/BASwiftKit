//
//  UIView+Gesture.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

#if canImport(UIKit)
import UIKit
import ObjectiveC.runtime

private var kBATapKey: UInt8 = 0
private var kBALongPressKey: UInt8 = 0
private var kBATapRecognizerKey: UInt8 = 0
private var kBALongPressRecognizerKey: UInt8 = 0

public extension UIView {

    /// 给任意 UIView 加点击事件（闭包式）。
    /// 会自动把 `isUserInteractionEnabled` 置为 true。
    ///
    /// 重复调用时会先移除上一次本方法添加的点击手势，确保只有最新一个生效，
    /// 避免旧 recognizer 因 target（wrapper）被释放而悬空堆积在 view 上。
    @discardableResult
    func ba_onTap(numberOfTaps: Int = 1,
                  handler: @escaping (UIView) -> Void) -> UITapGestureRecognizer {
        isUserInteractionEnabled = true

        // 先移除上一次本扩展添加的点击手势，防止 recognizer 堆积、旧 target 悬空。
        if let old = objc_getAssociatedObject(self, &kBATapRecognizerKey) as? UITapGestureRecognizer {
            removeGestureRecognizer(old)
        }

        let wrapper = BAGestureWrapper(handler)
        objc_setAssociatedObject(self, &kBATapKey, wrapper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        let tap = UITapGestureRecognizer(target: wrapper, action: #selector(BAGestureWrapper.invoke(_:)))
        tap.numberOfTapsRequired = numberOfTaps
        addGestureRecognizer(tap)
        objc_setAssociatedObject(self, &kBATapRecognizerKey, tap, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return tap
    }

    /// 给任意 UIView 加长按事件（闭包式）。
    /// 回调会在 `.began` 阶段触发一次。
    ///
    /// 重复调用时会先移除上一次本方法添加的长按手势，确保只有最新一个生效，
    /// 避免旧 recognizer 因 target（wrapper）被释放而悬空堆积在 view 上。
    @discardableResult
    func ba_onLongPress(minimumDuration: TimeInterval = 0.5,
                        handler: @escaping (UIView) -> Void) -> UILongPressGestureRecognizer {
        isUserInteractionEnabled = true

        // 先移除上一次本扩展添加的长按手势，防止 recognizer 堆积、旧 target 悬空。
        if let old = objc_getAssociatedObject(self, &kBALongPressRecognizerKey) as? UILongPressGestureRecognizer {
            removeGestureRecognizer(old)
        }

        let wrapper = BAGestureWrapper { v in handler(v) }
        objc_setAssociatedObject(self, &kBALongPressKey, wrapper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        let press = UILongPressGestureRecognizer(target: wrapper, action: #selector(BAGestureWrapper.invokeOnBegan(_:)))
        press.minimumPressDuration = minimumDuration
        addGestureRecognizer(press)
        objc_setAssociatedObject(self, &kBALongPressRecognizerKey, press, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return press
    }
}

private final class BAGestureWrapper {
    private let handler: (UIView) -> Void
    init(_ handler: @escaping (UIView) -> Void) { self.handler = handler }

    @objc func invoke(_ gesture: UIGestureRecognizer) {
        if let view = gesture.view { handler(view) }
    }

    @objc func invokeOnBegan(_ gesture: UIGestureRecognizer) {
        guard gesture.state == .began, let view = gesture.view else { return }
        handler(view)
    }
}
#endif
