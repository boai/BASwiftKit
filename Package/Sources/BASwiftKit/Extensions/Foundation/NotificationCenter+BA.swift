//
//  NotificationCenter+BA.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

#if canImport(UIKit)
import UIKit

public struct BAKeyboardInfo {
    public let endFrame: CGRect
    public let duration: TimeInterval
    public let curve: UIView.AnimationCurve
    public var animationOptions: UIView.AnimationOptions {
        UIView.AnimationOptions(rawValue: UInt(curve.rawValue) << 16)
    }
}

public extension NotificationCenter {

    /// 监听键盘弹出。返回一个 token，用 `removeObserver(token)` 解绑。
    @discardableResult
    func ba_observeKeyboardWillShow(_ handler: @escaping (BAKeyboardInfo) -> Void) -> NSObjectProtocol {
        addObserver(forName: UIResponder.keyboardWillShowNotification,
                    object: nil,
                    queue: .main) { note in
            guard let info = Self.ba_keyboardInfo(from: note) else { return }
            handler(info)
        }
    }

    /// 监听键盘收起
    @discardableResult
    func ba_observeKeyboardWillHide(_ handler: @escaping (BAKeyboardInfo) -> Void) -> NSObjectProtocol {
        addObserver(forName: UIResponder.keyboardWillHideNotification,
                    object: nil,
                    queue: .main) { note in
            guard let info = Self.ba_keyboardInfo(from: note) else { return }
            handler(info)
        }
    }

    static func ba_keyboardInfo(from note: Notification) -> BAKeyboardInfo? {
        guard let endFrame = (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
              let duration = note.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let curveRaw = note.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int,
              let curve = UIView.AnimationCurve(rawValue: curveRaw) else {
            return nil
        }
        return BAKeyboardInfo(endFrame: endFrame, duration: duration, curve: curve)
    }
}
#endif
