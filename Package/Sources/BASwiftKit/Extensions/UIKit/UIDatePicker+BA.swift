//
//  UIDatePicker+BA.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/26.
//

#if canImport(UIKit)
import UIKit
import ObjectiveC.runtime

private var kBADatePickerActionKey: UInt8 = 0

public extension UIDatePicker {

    static func ba_make(mode: UIDatePicker.Mode = .date,
                        date: Date = Date(),
                        minimumDate: Date? = nil,
                        maximumDate: Date? = nil,
                        minuteInterval: Int = 1) -> UIDatePicker {
        let picker = UIDatePicker()
        picker.datePickerMode = mode
        picker.date = date
        picker.minimumDate = minimumDate
        picker.maximumDate = maximumDate
        picker.minuteInterval = minuteInterval
        return picker
    }

    static func ba_make(mode: UIDatePicker.Mode = .date,
                        date: Date = Date(),
                        minimumDate: Date? = nil,
                        maximumDate: Date? = nil,
                        minuteInterval: Int = 1,
                        preferredStyle: UIDatePickerStyle) -> UIDatePicker {
        let picker = ba_make(mode: mode,
                             date: date,
                             minimumDate: minimumDate,
                             maximumDate: maximumDate,
                             minuteInterval: minuteInterval)
        picker.preferredDatePickerStyle = preferredStyle
        return picker
    }

    func ba_onChange(_ action: @escaping (UIDatePicker, Date) -> Void) {
        objc_setAssociatedObject(self, &kBADatePickerActionKey, BADatePickerAction(action), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        addTarget(self, action: #selector(ba_handleDateChanged), for: .valueChanged)
    }

    @objc private func ba_handleDateChanged() {
        guard let box = objc_getAssociatedObject(self, &kBADatePickerActionKey) as? BADatePickerAction else { return }
        box.invoke(self)
    }
}

private final class BADatePickerAction {
    private let action: (UIDatePicker, Date) -> Void
    init(_ action: @escaping (UIDatePicker, Date) -> Void) { self.action = action }
    func invoke(_ picker: UIDatePicker) { action(picker, picker.date) }
}
#endif
