//
//  Date+Calendar.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

import Foundation

public extension Date {

    // MARK: - 日期边界

    /// 当天的 00:00:00
    func ba_startOfDay(calendar: Calendar = .current) -> Date {
        calendar.startOfDay(for: self)
    }

    /// 当天的 23:59:59.999
    func ba_endOfDay(calendar: Calendar = .current) -> Date {
        var comps = DateComponents()
        comps.day = 1
        comps.second = -1
        return calendar.date(byAdding: comps, to: ba_startOfDay(calendar: calendar)) ?? self
    }

    /// 当月第一天
    func ba_startOfMonth(calendar: Calendar = .current) -> Date {
        let comps = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: comps) ?? self
    }

    /// 当月最后一天
    func ba_endOfMonth(calendar: Calendar = .current) -> Date {
        var comps = DateComponents()
        comps.month = 1
        comps.day = -1
        return calendar.date(byAdding: comps, to: ba_startOfMonth(calendar: calendar)) ?? self
    }

    // MARK: - 加减

    func ba_adding(days: Int, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: days, to: self) ?? self
    }

    func ba_adding(months: Int, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .month, value: months, to: self) ?? self
    }

    func ba_adding(years: Int, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .year, value: years, to: self) ?? self
    }

    // MARK: - 比较 / 查询

    var ba_isToday: Bool { Calendar.current.isDateInToday(self) }
    var ba_isYesterday: Bool { Calendar.current.isDateInYesterday(self) }
    var ba_isTomorrow: Bool { Calendar.current.isDateInTomorrow(self) }
    var ba_isWeekend: Bool { Calendar.current.isDateInWeekend(self) }

    /// 周几（本地化全称，如 "星期一" / "Monday"）
    func ba_weekdayName(locale: Locale = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }

    /// 周几（本地化短名，如 "周一" / "Mon"）
    func ba_weekdayShortName(locale: Locale = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "EEE"
        return formatter.string(from: self)
    }

    /// 距离另一个日期相差的整天数
    func ba_daysBetween(_ other: Date, calendar: Calendar = .current) -> Int {
        let from = ba_startOfDay(calendar: calendar)
        let to = other.ba_startOfDay(calendar: calendar)
        return calendar.dateComponents([.day], from: from, to: to).day ?? 0
    }

    /// 年龄（按出生日期计算到今天）
    var ba_ageInYears: Int {
        let comps = Calendar.current.dateComponents([.year], from: self, to: Date())
        return comps.year ?? 0
    }
}

public extension String {
    /// 用指定格式串解析为 Date
    func ba_date(format: String = "yyyy-MM-dd HH:mm:ss",
                 locale: Locale = .current,
                 timeZone: TimeZone = .current) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateFormat = format
        return formatter.date(from: self)
    }
}
