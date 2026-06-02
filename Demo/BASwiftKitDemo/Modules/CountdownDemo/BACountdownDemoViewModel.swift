//
//  BACountdownDemoViewModel.swift
//  BASwiftKitDemo
//
//  Created by boai on 2026/06/02.
//

import Foundation
import BASwiftKit

/// 模拟商品数据
struct BACountdownProduct {
    let id: String
    let name: String
    let image: String       // SF Symbol 名
    let price: String       // 现价
    let originalPrice: String // 原价
    let endDate: Date       // 截止时间

    /// 是否已过期（相对当前时间）。
    var isExpired: Bool { Date() >= endDate }
}

final class BACountdownDemoViewModel {

    /// 商品列表。
    let products: BAObservable<[BACountdownProduct]> = BAObservable([])

    /// 最近一个即将到期的商品（用于顶部 Banner）。
    let nearestProduct: BAObservable<BACountdownProduct?> = BAObservable(nil)

    private let disposeBag = BADisposeBag()
    private var headerCountdownId: String?
    /// 模拟数据池。
    private let productPool: [BACountdownProduct] = BACountdownDemoViewModel.makeProductPool()

    // MARK: - Public

    func loadData() {
        refreshProducts()
    }

    func refreshProducts() {
        // 取消旧的 banner 观察
        if let id = headerCountdownId {
            BACountdownManager.shared.unregister(id: id)
            headerCountdownId = nil
        }

        let items = generateProducts()
        products.update(items)

        // 绑定 banner 倒计时（用最近截止的商品）
        if let nearest = items.min(by: { $0.endDate < $1.endDate }) {
            nearestProduct.update(nearest)
            headerCountdownId = BACountdownManager.shared.register(
                endDate: nearest.endDate
            ) { [weak self] status in
                DispatchQueue.main.async {
                    // 刷新 nearestProduct 的剩余时间 —— UI 通过绑定 nearestProduct
                    // 上的 formatted 使用。为避免 View 层直接拿 Date 算，
                    // 这里用 status 驱动。
                    self?.nearestProduct.update(nearest)
                }
            }
        }
    }

    // MARK: - Private

    /// 从产品池中随机抽取 6~12 个商品，赋予不同的未来截止时间。
    private func generateProducts() -> [BACountdownProduct] {
        let count = Int.random(in: 6...12)
        let selected = productPool.shuffled().prefix(count)
        let now = Date()
        // 截止时间在 30s ~ 10min 之间散布
        let offsets: [TimeInterval] = [30, 60, 90, 120, 180, 300, 420, 600]
        return selected.enumerated().map { index, template in
            let offset = offsets[index % offsets.count]
            return BACountdownProduct(
                id: UUID().uuidString,
                name: template.name,
                image: template.image,
                price: template.price,
                originalPrice: template.originalPrice,
                endDate: now.addingTimeInterval(offset)
            )
        }
    }

    /// 预定义的模拟商品模板。
    private static func makeProductPool() -> [BACountdownProduct] {
        let templates: [(name: String, image: String, price: String, original: String)] = [
            ("iPhone 17 Pro Max 256GB",    "iphone.gen3",          "¥8999",  "¥9999"),
            ("AirPods Pro 3",              "airpodspro",           "¥1599",  "¥1999"),
            ("MacBook Air M4 15\"",        "laptopcomputer",       "¥8999",  "¥10999"),
            ("Apple Watch Ultra 3",        "applewatch",           "¥5999",  "¥6999"),
            ("iPad Pro M5 11\"",           "ipad.landscape",       "¥6499",  "¥7999"),
            ("索尼 PS6 游戏主机",          "playstation.logo",     "¥3999",  "¥4999"),
            ("戴森 V16 无线吸尘器",        "fan.ceiling",          "¥3299",  "¥4290"),
            ("SK-II 神仙水 230ml",         "drop.circle",          "¥899",   "¥1370"),
            ("飞天茅台 53° 500ml",         "wineglass",            "¥1499",  "¥2899"),
            ("乐高 千年隼 75192",          "cube.transparent",     "¥3999",  "¥5999"),
            ("Nike Air Jordan 1 Retro",    "shoe.2",               "¥1099",  "¥1499"),
            ("海蓝之谜 面霜 60ml",         "aqi.low",              "¥1699",  "¥2550"),
            ("Switch 2 游戏机",            "gamecontroller",       "¥2499",  "¥3199"),
            ("大疆 Mavic 4 Pro 无人机",    "airplane.circle",      "¥6999",  "¥8499"),
            ("加拿大鹅 Expedition 羽绒服",  "jacket",              "¥6999",  "¥9900"),
            ("特斯拉 Cybertruck 模型 1:18", "car.2",               "¥999",   "¥1499"),
        ]
        return templates.map { t in
            BACountdownProduct(
                id: UUID().uuidString,
                name: t.name,
                image: t.image,
                price: t.price,
                originalPrice: t.original,
                endDate: Date() // 临时值，generateProducts 会重新设
            )
        }
    }
}
