//
//  Date+BA.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

import Foundation

public extension Date {

    /// 用指定格式串格式化（默认 yyyy-MM-dd HH:mm:ss）
    func ba_string(format: String = "yyyy-MM-dd HH:mm:ss",
                   locale: Locale = .current,
                   timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateFormat = format
        return formatter.string(from: self)
    }

    /// 时间戳（秒）
    var ba_timestamp: TimeInterval { timeIntervalSince1970 }

    /// 距今多久（人类友好串）
    var ba_relativeFromNow: String {
        let delta = Date().timeIntervalSince(self)
        if delta < 60 { return "刚刚" }
        if delta < 3600 { return "\(Int(delta / 60))分钟前" }
        if delta < 86_400 { return "\(Int(delta / 3600))小时前" }
        if delta < 86_400 * 30 { return "\(Int(delta / 86_400))天前" }
        return ba_string(format: "yyyy-MM-dd")
    }

    /// 年 / 月 / 日 / 时 / 分 / 秒 元组
    var ba_components: (year: Int, month: Int, day: Int, hour: Int, minute: Int, second: Int) {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self)
        return (comps.year ?? 0, comps.month ?? 0, comps.day ?? 0,
                comps.hour ?? 0, comps.minute ?? 0, comps.second ?? 0)
    }

    /// 是否为同一天
    func ba_isSameDay(as other: Date, calendar: Calendar = .current) -> Bool {
        calendar.isDate(self, inSameDayAs: other)
    }
}

public extension TimeInterval {
    /// 时间戳（秒）转 Date
    var ba_date: Date { Date(timeIntervalSince1970: self) }
}
