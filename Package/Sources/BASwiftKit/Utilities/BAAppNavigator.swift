//
//  BAAppNavigator.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

#if canImport(UIKit)
import UIKit

/// 常用系统跳转封装。
///
/// 只封装 Apple 公开支持的 URL Scheme 和系统设置入口，避免使用私有设置路径导致审核风险。
/// 所有跳转都会在主线程调用 `UIApplication.open`，结果通过 completion 返回。
public enum BAAppNavigator {

    /// 打开结果回调。
    public typealias Completion = (Bool) -> Void

    /// 打开指定 URL。
    ///
    /// - Parameters:
    ///   - url: 目标 URL。
    ///   - options: `UIApplication.open` 选项，默认空。
    ///   - completion: 打开完成回调，`true` 表示系统接受了跳转请求。
    public static func ba_open(_ url: URL,
                               options: [UIApplication.OpenExternalURLOptionsKey: Any] = [:],
                               completion: Completion? = nil) {
        DispatchQueue.main.async {
            UIApplication.shared.open(url, options: options) { success in
                completion?(success)
            }
        }
    }

    /// 打开当前 App 的系统设置页。
    ///
    /// 常用于权限被拒绝后引导用户手动开启相机、相册、定位、通知等权限。
    /// - Parameter completion: 打开完成回调。
    public static func ba_openAppSettings(completion: Completion? = nil) {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            completion?(false)
            return
        }
        ba_open(url, completion: completion)
    }

    /// 拨打电话。
    ///
    /// - Parameters:
    ///   - phoneNumber: 电话号码。方法会移除空格、短横线、括号等常见分隔符。
    ///   - completion: 打开完成回调。
    public static func ba_call(_ phoneNumber: String, completion: Completion? = nil) {
        let sanitized = phoneNumber.filter { $0.isNumber || $0 == "+" }
        guard let url = URL(string: "tel://\(sanitized)") else {
            completion?(false)
            return
        }
        ba_open(url, completion: completion)
    }

    /// 打开短信编辑界面。
    ///
    /// - Parameters:
    ///   - phoneNumber: 收件人手机号，可为空。
    ///   - completion: 打开完成回调。
    public static func ba_sendSMS(to phoneNumber: String = "", completion: Completion? = nil) {
        guard let url = URL(string: "sms://\(phoneNumber)") else {
            completion?(false)
            return
        }
        ba_open(url, completion: completion)
    }

    /// 打开邮件编辑界面。
    ///
    /// - Parameters:
    ///   - email: 收件人邮箱，可为空。
    ///   - completion: 打开完成回调。
    public static func ba_sendEmail(to email: String = "", completion: Completion? = nil) {
        guard let url = URL(string: "mailto:\(email)") else {
            completion?(false)
            return
        }
        ba_open(url, completion: completion)
    }

    /// 在系统地图中打开坐标点。
    ///
    /// - Parameters:
    ///   - latitude: 纬度。
    ///   - longitude: 经度。
    ///   - name: 地点名称，会作为查询关键字传给地图。
    ///   - completion: 打开完成回调。
    public static func ba_openMap(latitude: Double,
                                  longitude: Double,
                                  name: String? = nil,
                                  completion: Completion? = nil) {
        var components = URLComponents(string: "http://maps.apple.com/")
        var items = [
            URLQueryItem(name: "ll", value: "\(latitude),\(longitude)")
        ]
        if let name, !name.isEmpty {
            items.append(URLQueryItem(name: "q", value: name))
        }
        components?.queryItems = items
        guard let url = components?.url else {
            completion?(false)
            return
        }
        ba_open(url, completion: completion)
    }

    /// 打开 App Store 应用详情页。
    ///
    /// - Parameters:
    ///   - appID: App Store Connect 中的 Apple ID，不包含 `id` 前缀。
    ///   - completion: 打开完成回调。
    public static func ba_openAppStore(appID: String, completion: Completion? = nil) {
        guard let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appID)") else {
            completion?(false)
            return
        }
        ba_open(url, completion: completion)
    }

    /// 打开 App Store 评分页。
    ///
    /// - Parameters:
    ///   - appID: App Store Connect 中的 Apple ID，不包含 `id` 前缀。
    ///   - completion: 打开完成回调。
    public static func ba_openAppReview(appID: String, completion: Completion? = nil) {
        guard let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appID)?action=write-review") else {
            completion?(false)
            return
        }
        ba_open(url, completion: completion)
    }

    /// 打开网页链接。
    ///
    /// - Parameters:
    ///   - string: URL 字符串。
    ///   - completion: 打开完成回调。
    public static func ba_openWeb(_ string: String, completion: Completion? = nil) {
        guard let url = URL(string: string) else {
            completion?(false)
            return
        }
        ba_open(url, completion: completion)
    }
}
#endif
