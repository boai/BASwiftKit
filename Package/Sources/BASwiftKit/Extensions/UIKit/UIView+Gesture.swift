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

public extension UIView {

    /// 给任意 UIView 加点击事件（闭包式）。
    /// 会自动把 `isUserInteractionEnabled` 置为 true。
    @discardableResult
    func ba_onTap(numberOfTaps: Int = 1,
                  handler: @escaping (UIView) -> Void) -> UITapGestureRecognizer {
        isUserInteractionEnabled = true
        let wrapper = BAGestureWrapper(handler)
        objc_setAssociatedObject(self, &kBATapKey, wrapper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        let tap = UITapGestureRecognizer(target: wrapper, action: #selector(BAGestureWrapper.invoke(_:)))
        tap.numberOfTapsRequired = numberOfTaps
        addGestureRecognizer(tap)
        return tap
    }

    /// 给任意 UIView 加长按事件（闭包式）。
    /// 回调会在 `.began` 阶段触发一次。
    @discardableResult
    func ba_onLongPress(minimumDuration: TimeInterval = 0.5,
                        handler: @escaping (UIView) -> Void) -> UILongPressGestureRecognizer {
        isUserInteractionEnabled = true
        let wrapper = BAGestureWrapper { v in handler(v) }
        objc_setAssociatedObject(self, &kBALongPressKey, wrapper, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        let press = UILongPressGestureRecognizer(target: wrapper, action: #selector(BAGestureWrapper.invokeOnBegan(_:)))
        press.minimumPressDuration = minimumDuration
        addGestureRecognizer(press)
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
