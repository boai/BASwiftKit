//
//  UIViewController+BA.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

#if canImport(UIKit)
import UIKit

public extension UIViewController {

    /// 当前可见的最顶层控制器。
    static var ba_current: UIViewController? { BAAppEnvironment.ba_currentViewController }

    /// 弹出系统 Alert
    func ba_alert(title: String?,
                  message: String?,
                  confirmTitle: String = "好",
                  cancelTitle: String? = nil,
                  onConfirm: (() -> Void)? = nil,
                  onCancel: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        if let cancelTitle = cancelTitle {
            alert.addAction(UIAlertAction(title: cancelTitle, style: .cancel) { _ in onCancel?() })
        }
        alert.addAction(UIAlertAction(title: confirmTitle, style: .default) { _ in onConfirm?() })
        present(alert, animated: true)
    }

    /// 弹出 ActionSheet
    func ba_actionSheet(title: String? = nil,
                        message: String? = nil,
                        actions: [(title: String, style: UIAlertAction.Style)],
                        onSelect: @escaping (Int) -> Void) {
        let sheet = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        for (idx, item) in actions.enumerated() {
            sheet.addAction(UIAlertAction(title: item.title, style: item.style) { _ in onSelect(idx) })
        }
        sheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(sheet, animated: true)
    }

    /// 收起当前键盘
    func ba_dismissKeyboard() {
        view.endEditing(true)
    }

    /// 在导航栈中查找指定类型的 VC
    func ba_findInNavigation<T: UIViewController>(_ type: T.Type) -> T? {
        navigationController?.viewControllers.first(where: { $0 is T }) as? T
    }
}
#endif
