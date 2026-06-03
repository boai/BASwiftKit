//
//  BAAppTheme.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/05/21.
//

import UIKit
import BASwiftKit

/// Demo 设计系统：颜色 / 字号 / 间距常量。
public enum BAAppTheme {

    // MARK: - 颜色（深浅色自适应）

    /// 主背景色
    public static let background = UIColor.ba_dynamic(
        light: UIColor(ba_hex: "#F4F7FC") ?? .systemBackground,
        dark:  UIColor(ba_hex: "#0A0D13") ?? .black
    )

    public static let backgroundElevated = UIColor.ba_dynamic(
        light: UIColor(ba_hex: "#EEF3FA") ?? .secondarySystemBackground,
        dark:  UIColor(ba_hex: "#111722") ?? .secondarySystemBackground
    )

    /// 卡片背景
    public static let card = UIColor.ba_dynamic(
        light: .white,
        dark:  UIColor(ba_hex: "#171D28") ?? .secondarySystemBackground
    )

    public static let cardHighlight = UIColor.ba_dynamic(
        light: UIColor(ba_hex: "#FBFCFF") ?? .white,
        dark:  UIColor(ba_hex: "#202838") ?? .tertiarySystemBackground
    )

    public static let separator = UIColor.ba_dynamic(
        light: UIColor(ba_hex: "#E7ECF4") ?? .separator,
        dark:  UIColor(ba_hex: "#2A3342") ?? .separator
    )

    /// 一级文字
    public static let textPrimary = UIColor.ba_dynamic(
        light: UIColor(ba_hex: "#16181D") ?? .label,
        dark:  UIColor(ba_hex: "#F4F5F7") ?? .label
    )

    /// 二级文字
    public static let textSecondary = UIColor.ba_dynamic(
        light: UIColor(ba_hex: "#6E7480") ?? .secondaryLabel,
        dark:  UIColor(ba_hex: "#9AA1AE") ?? .secondaryLabel
    )

    /// 主品牌色
    public static let accent = UIColor(ba_hex: "#4F7CFF") ?? .systemBlue
    public static let accentSecondary = UIColor(ba_hex: "#8F5CFF") ?? .systemPurple
    public static let success = UIColor(ba_hex: "#26B67A") ?? .systemGreen
    public static let warning = UIColor(ba_hex: "#F2A53B") ?? .systemOrange
    public static let danger  = UIColor(ba_hex: "#F05260") ?? .systemRed

    public static let brandGradient: [UIColor] = [
        UIColor(ba_hex: "#31D7FF") ?? .systemTeal,
        accent,
        accentSecondary
    ]
    public static let warmGradient: [UIColor] = [warning, danger]
    public static let coolGradient: [UIColor] = [
        UIColor(ba_hex: "#20E3B2") ?? .systemGreen,
        UIColor(ba_hex: "#2F80ED") ?? .systemBlue
    ]

    // MARK: - 字体

    public static let largeTitleFont = UIFont.systemFont(ofSize: 28, weight: .bold)
    public static let titleFont = UIFont.systemFont(ofSize: 17, weight: .semibold)
    public static let bodyFont = UIFont.systemFont(ofSize: 15, weight: .regular)
    public static let captionFont = UIFont.systemFont(ofSize: 12, weight: .medium)

    // MARK: - 间距

    public enum Spacing {
        public static let small: CGFloat = 8
        public static let medium: CGFloat = 16
        public static let large: CGFloat = 24
    }

    // MARK: - 圆角

    public static let cornerRadius: CGFloat = 18
    public static let smallCornerRadius: CGFloat = 12
    public static let controlHeight: CGFloat = 48
}
