//
//  UIColor+BA.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

#if canImport(UIKit)
import UIKit

public extension UIColor {

    // MARK: - 16 进制解析缓存（性能优化）

    /// hex 字符串 → 解析出的 RGBA 分量缓存。
    ///
    /// hex 串解析（大小写转换、前缀剥离、短格式扩展、按位运算）在高频构造时有一定开销，
    /// 这里按「hex|alpha」缓存解析结果（RGBA 分量）复用。缓存只读写一个字典，用 `NSLock` 保证并发安全。
    /// 注意：缓存的是「分量」而非 `UIColor` 实例——便利失败构造器必须以 `self.init(...)` 收尾，
    /// 无法直接返回已有对象，故缓存分量后再委托给指定构造器，行为与原实现完全一致。
    private static var hexComponentsCache: [String: (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)] = [:]
    private static let hexCacheLock = NSLock()

    /// 解析 hex 串得到 RGBA 分量；命中缓存直接返回，未命中则解析并写入缓存。
    ///
    /// - Returns: 解析成功返回分量元组；非法输入返回 `nil`（保持原构造器返回 nil 的语义）。
    private static func ba_hexComponents(hex: String,
                                         alpha: CGFloat) -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)? {
        // key 需带 alpha：同一 hex 配不同 alpha 解析出的最终分量不同（6 位格式使用外部 alpha）。
        let key = "\(hex)|\(alpha)"

        hexCacheLock.lock()
        if let cached = hexComponentsCache[key] {
            hexCacheLock.unlock()
            return cached
        }
        hexCacheLock.unlock()

        var raw = hex.uppercased()
        if raw.hasPrefix("#") { raw.removeFirst() }
        if raw.hasPrefix("0X") { raw.removeFirst(2) }

        // 扩展短格式
        if raw.count == 3 || raw.count == 4 {
            raw = raw.map { "\($0)\($0)" }.joined()
        }

        guard raw.count == 6 || raw.count == 8,
              let value = UInt64(raw, radix: 16) else { return nil }

        let r, g, b, a: CGFloat
        if raw.count == 6 {
            r = CGFloat((value & 0xFF0000) >> 16) / 255.0
            g = CGFloat((value & 0x00FF00) >> 8) / 255.0
            b = CGFloat(value & 0x0000FF) / 255.0
            a = alpha
        } else {
            r = CGFloat((value & 0xFF000000) >> 24) / 255.0
            g = CGFloat((value & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((value & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(value & 0x000000FF) / 255.0
        }

        let components = (r: r, g: g, b: b, a: a)
        hexCacheLock.lock()
        hexComponentsCache[key] = components
        hexCacheLock.unlock()
        return components
    }

    /// 16 进制串构造（支持 #RGB、#RGBA、#RRGGBB、#RRGGBBAA，前缀可省）
    convenience init?(ba_hex hex: String, alpha: CGFloat = 1.0) {
        // 优化：复用缓存的解析分量，避免重复解析同一 hex 串。非法输入仍返回 nil。
        guard let c = UIColor.ba_hexComponents(hex: hex, alpha: alpha) else { return nil }
        self.init(red: c.r, green: c.g, blue: c.b, alpha: c.a)
    }

    /// 0~255 RGB 便利构造
    static func ba_rgb(_ r: Int, _ g: Int, _ b: Int, alpha: CGFloat = 1.0) -> UIColor {
        UIColor(red: CGFloat(r) / 255.0,
                green: CGFloat(g) / 255.0,
                blue: CGFloat(b) / 255.0,
                alpha: alpha)
    }

    /// 随机颜色
    static var ba_random: UIColor {
        UIColor(red: .random(in: 0...1),
                green: .random(in: 0...1),
                blue: .random(in: 0...1),
                alpha: 1.0)
    }

    /// 适配深浅色。
    static func ba_dynamic(light: UIColor, dark: UIColor) -> UIColor {
        UIColor { trait in
            trait.userInterfaceStyle == .dark ? dark : light
        }
    }

    /// 转为 16 进制串（#RRGGBB）
    var ba_hexString: String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let ri = Int(round(r * 255))
        let gi = Int(round(g * 255))
        let bi = Int(round(b * 255))
        return String(format: "#%02X%02X%02X", ri, gi, bi)
    }
}
#endif
