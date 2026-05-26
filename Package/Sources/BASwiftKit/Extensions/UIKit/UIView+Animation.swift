//
//  UIView+Animation.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

#if canImport(UIKit)
import UIKit

public extension UIView {

    /// 渐入
    func ba_fadeIn(duration: TimeInterval = 0.3,
                   delay: TimeInterval = 0,
                   completion: ((Bool) -> Void)? = nil) {
        if isHidden { isHidden = false }
        UIView.animate(withDuration: duration,
                       delay: delay,
                       options: [.curveEaseOut],
                       animations: { self.alpha = 1 },
                       completion: completion)
    }

    /// 渐出
    func ba_fadeOut(duration: TimeInterval = 0.3,
                    delay: TimeInterval = 0,
                    hideOnComplete: Bool = false,
                    completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: duration,
                       delay: delay,
                       options: [.curveEaseIn],
                       animations: { self.alpha = 0 },
                       completion: { finished in
            if hideOnComplete { self.isHidden = true }
            completion?(finished)
        })
    }

    /// 水平抖动（提示错误时常用）
    func ba_shake(intensity: CGFloat = 10, duration: TimeInterval = 0.5) {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.duration = duration
        animation.values = [-intensity, intensity, -intensity * 0.6, intensity * 0.6, -intensity * 0.3, intensity * 0.3, 0]
        animation.keyTimes = [0, 0.16, 0.33, 0.5, 0.66, 0.83, 1].map { NSNumber(value: $0) }
        layer.add(animation, forKey: "ba_shake")
    }

    /// 心跳脉冲
    func ba_pulse(scale: CGFloat = 1.08, duration: TimeInterval = 0.6, repeatCount: Float = .infinity) {
        let anim = CABasicAnimation(keyPath: "transform.scale")
        anim.duration = duration
        anim.fromValue = 1.0
        anim.toValue = scale
        anim.autoreverses = true
        anim.repeatCount = repeatCount
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.add(anim, forKey: "ba_pulse")
    }

    func ba_stopPulse() {
        layer.removeAnimation(forKey: "ba_pulse")
    }

    /// 弹簧出现（从缩小+透明到正常）
    func ba_springAppear(duration: TimeInterval = 0.5,
                         damping: CGFloat = 0.55,
                         initialVelocity: CGFloat = 0.6,
                         completion: ((Bool) -> Void)? = nil) {
        alpha = 0
        transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        UIView.animate(withDuration: duration,
                       delay: 0,
                       usingSpringWithDamping: damping,
                       initialSpringVelocity: initialVelocity,
                       options: [.allowUserInteraction],
                       animations: {
            self.alpha = 1
            self.transform = .identity
        }, completion: completion)
    }

    /// 绕中心旋转一次
    func ba_rotate(by radians: CGFloat = .pi, duration: TimeInterval = 0.4) {
        UIView.animate(withDuration: duration) {
            self.transform = self.transform.rotated(by: radians)
        }
    }

    /// 从指定方向滑入
    enum BASlideDirection {
        case top, bottom, leading, trailing
    }

    func ba_slideIn(from direction: BASlideDirection,
                    distance: CGFloat = 24,
                    duration: TimeInterval = 0.35,
                    completion: ((Bool) -> Void)? = nil) {
        let dx: CGFloat
        let dy: CGFloat
        switch direction {
        case .top:      dx = 0;        dy = -distance
        case .bottom:   dx = 0;        dy = distance
        case .leading:  dx = -distance; dy = 0
        case .trailing: dx = distance;  dy = 0
        }
        alpha = 0
        transform = CGAffineTransform(translationX: dx, y: dy)
        UIView.animate(withDuration: duration,
                       delay: 0,
                       options: [.curveEaseOut],
                       animations: {
            self.alpha = 1
            self.transform = .identity
        }, completion: completion)
    }
}
#endif
