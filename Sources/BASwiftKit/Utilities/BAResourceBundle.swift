//
//  BAResourceBundle.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/21.
//

#if canImport(UIKit)
import UIKit
#endif
import Foundation

/// 组件化资源 bundle 查找器。
///
/// 典型组件化项目里每个 podspec 会带一个 `MyComponent.bundle`，
/// 通过组件内任意一个类定位到框架 bundle，再向下查找 `.bundle` 文件即可。
///
/// 用法：
/// ```swift
/// // 1. 解析一次（建议放在组件入口缓存起来）
/// let bundle = BAResourceBundle.ba_resolve(anchorClass: MyComponent.self,
///                                          bundleName: "MyComponent")
///
/// // 2. 后续读图 / 读文件
/// let img = BAResourceBundle.ba_image(named: "logo", from: bundle)
/// let url = bundle?.ba_resourceURL(named: "config", ext: "json")
/// ```
public enum BAResourceBundle {

    /// 用一个组件内的类做锚点，定位它所在的 framework bundle，
    /// 再去找平级 `<bundleName>.bundle`。两者都失败时返回 nil。
    public static func ba_resolve(anchorClass: AnyClass,
                                  bundleName: String) -> Bundle? {
        let frameworkBundle = Bundle(for: anchorClass)
        if let url = frameworkBundle.url(forResource: bundleName, withExtension: "bundle"),
           let nested = Bundle(url: url) {
            return nested
        }
        // 没找到 .bundle 时，使用框架自身 bundle 作为退路
        return frameworkBundle
    }

    /// 通过 module 名直接从 main bundle 找 `<moduleName>.bundle`
    /// （SwiftPM 资源 / 手拖入工程的 .bundle 都适用）
    public static func ba_resolve(named bundleName: String,
                                  in base: Bundle = .main) -> Bundle? {
        guard let url = base.url(forResource: bundleName, withExtension: "bundle"),
              let nested = Bundle(url: url) else {
            return base
        }
        return nested
    }

    #if canImport(UIKit)
    /// 从指定 bundle 读取图片（兼容深浅色 Asset Catalog）
    public static func ba_image(named name: String,
                                from bundle: Bundle?) -> UIImage? {
        guard let bundle = bundle else { return nil }
        return UIImage(named: name, in: bundle, compatibleWith: nil)
    }
    #endif
}
