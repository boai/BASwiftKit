//
//  BAAppTheme.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit

/// Demo 设计系统：颜色 / 字号 / 间距常量。
enum BAAppTheme {

    // MARK: - 颜色（深浅色自适应）

    /// 主背景色
    static let background = UIColor.ba_dynamic(
        light: UIColor(ba_hex: "#F4F7FC") ?? .systemBackground,
        dark:  UIColor(ba_hex: "#0A0D13") ?? .black
    )

    static let backgroundElevated = UIColor.ba_dynamic(
        light: UIColor(ba_hex: "#EEF3FA") ?? .secondarySystemBackground,
        dark:  UIColor(ba_hex: "#111722") ?? .secondarySystemBackground
    )

    /// 卡片背景
    static let card = UIColor.ba_dynamic(
        light: .white,
        dark:  UIColor(ba_hex: "#171D28") ?? .secondarySystemBackground
    )

    static let cardHighlight = UIColor.ba_dynamic(
        light: UIColor(ba_hex: "#FBFCFF") ?? .white,
        dark:  UIColor(ba_hex: "#202838") ?? .tertiarySystemBackground
    )

    static let separator = UIColor.ba_dynamic(
        light: UIColor(ba_hex: "#E7ECF4") ?? .separator,
        dark:  UIColor(ba_hex: "#2A3342") ?? .separator
    )

    /// 一级文字
    static let textPrimary = UIColor.ba_dynamic(
        light: UIColor(ba_hex: "#16181D") ?? .label,
        dark:  UIColor(ba_hex: "#F4F5F7") ?? .label
    )

    /// 二级文字
    static let textSecondary = UIColor.ba_dynamic(
        light: UIColor(ba_hex: "#6E7480") ?? .secondaryLabel,
        dark:  UIColor(ba_hex: "#9AA1AE") ?? .secondaryLabel
    )

    /// 主品牌色
    static let accent = UIColor(ba_hex: "#4F7CFF") ?? .systemBlue
    static let accentSecondary = UIColor(ba_hex: "#8F5CFF") ?? .systemPurple
    static let success = UIColor(ba_hex: "#26B67A") ?? .systemGreen
    static let warning = UIColor(ba_hex: "#F2A53B") ?? .systemOrange
    static let danger  = UIColor(ba_hex: "#F05260") ?? .systemRed

    static let brandGradient: [UIColor] = [
        UIColor(ba_hex: "#31D7FF") ?? .systemTeal,
        accent,
        accentSecondary
    ]
    static let warmGradient: [UIColor] = [warning, danger]
    static let coolGradient: [UIColor] = [
        UIColor(ba_hex: "#20E3B2") ?? .systemGreen,
        UIColor(ba_hex: "#2F80ED") ?? .systemBlue
    ]

    // MARK: - 字体

    static let largeTitleFont = UIFont.systemFont(ofSize: 28, weight: .bold)
    static let titleFont = UIFont.systemFont(ofSize: 17, weight: .semibold)
    static let bodyFont = UIFont.systemFont(ofSize: 15, weight: .regular)
    static let captionFont = UIFont.systemFont(ofSize: 12, weight: .medium)

    // MARK: - 间距

    enum Spacing {
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
    }

    // MARK: - 圆角

    static let cornerRadius: CGFloat = 18
    static let smallCornerRadius: CGFloat = 12
    static let controlHeight: CGFloat = 48
}
