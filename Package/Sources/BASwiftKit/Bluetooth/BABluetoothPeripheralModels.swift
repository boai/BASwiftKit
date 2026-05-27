//
//  BABluetoothPeripheralModels.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

#if canImport(CoreBluetooth)
import Foundation
import CoreBluetooth

/// 扫描发现的外设信息。
public struct BABluetoothDiscoveredPeripheral {
    /// 原生外设对象。
    public let peripheral: CBPeripheral
    /// 广播数据。
    public let advertisementData: [String: Any]
    /// RSSI 信号强度。
    public let rssi: NSNumber

    /// 外设唯一标识。
    public var identifier: UUID { peripheral.identifier }
    /// 外设名称；优先使用 `peripheral.name`，其次读取广播名称。
    public var name: String? {
        peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String
    }

    /// 创建发现外设模型。
    ///
    /// - Parameters:
    ///   - peripheral: 原生外设对象。
    ///   - advertisementData: 广播数据。
    ///   - rssi: RSSI 信号强度。
    public init(peripheral: CBPeripheral, advertisementData: [String: Any], rssi: NSNumber) {
        self.peripheral = peripheral
        self.advertisementData = advertisementData
        self.rssi = rssi
    }
}

/// 已连接外设信息。
public struct BABluetoothConnectedPeripheral {
    /// 原生外设对象。
    public let peripheral: CBPeripheral
    /// 当前连接状态。
    public let state: BABluetoothConnectionState
    /// 已发现服务。
    public let services: [CBService]
    /// 按服务 UUID 缓存的特征数组。
    public let characteristicsByService: [CBUUID: [CBCharacteristic]]

    /// 外设唯一标识。
    public var identifier: UUID { peripheral.identifier }
    /// 外设名称。
    public var name: String? { peripheral.name }

    /// 创建已连接外设模型。
    ///
    /// - Parameters:
    ///   - peripheral: 原生外设对象。
    ///   - state: 当前连接状态。
    ///   - services: 已发现服务。
    ///   - characteristicsByService: 按服务 UUID 缓存的特征数组。
    public init(peripheral: CBPeripheral,
                state: BABluetoothConnectionState,
                services: [CBService],
                characteristicsByService: [CBUUID: [CBCharacteristic]]) {
        self.peripheral = peripheral
        self.state = state
        self.services = services
        self.characteristicsByService = characteristicsByService
    }
}
#endif
