//
//  BABluetoothTypes.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

#if canImport(CoreBluetooth)
import Foundation
import CoreBluetooth

/// 蓝牙外设连接状态。
public enum BABluetoothConnectionState: Equatable {
    /// 尚未连接。
    case disconnected
    /// 正在连接。
    case connecting
    /// 已连接。
    case connected
    /// 正在断开连接。
    case disconnecting
}

/// 蓝牙管理器事件。
public enum BABluetoothEvent {
    /// 中心管理器状态变化。
    case stateChanged(CBManagerState)
    /// 扫描发现外设。
    case discovered(BABluetoothDiscoveredPeripheral)
    /// 外设连接状态变化。
    case connectionChanged(BABluetoothConnectedPeripheral, BABluetoothConnectionState)
    /// 服务发现完成。
    case servicesDiscovered(BABluetoothConnectedPeripheral, [CBService])
    /// 特征发现完成。
    case characteristicsDiscovered(BABluetoothConnectedPeripheral, CBService, [CBCharacteristic])
    /// 收到特征数据。
    case dataReceived(BABluetoothDataPacket)
    /// 蓝牙操作产生错误。
    case failed(BABluetoothError)
}

/// 蓝牙封装错误。
public enum BABluetoothError: Error {
    /// 当前蓝牙不可用，关联值为系统蓝牙状态。
    case bluetoothUnavailable(CBManagerState)
    /// 外设未连接或未被管理器记录。
    case peripheralNotConnected(UUID)
    /// 未找到指定特征。
    case characteristicNotFound(CBUUID)
    /// 系统回调返回错误。
    case underlying(Error)
}

/// 蓝牙扫描请求配置。
public struct BABluetoothScanRequest {
    /// 只扫描包含这些服务的外设；传 `nil` 扫描全部外设。
    public var serviceUUIDs: [CBUUID]?
    /// 是否允许重复发现同一外设。
    public var allowDuplicates: Bool

    /// 创建扫描配置。
    ///
    /// - Parameters:
    ///   - serviceUUIDs: 只扫描包含这些服务的外设；传 `nil` 扫描全部外设。
    ///   - allowDuplicates: 是否允许重复发现同一外设。
    public init(serviceUUIDs: [CBUUID]? = nil, allowDuplicates: Bool = false) {
        self.serviceUUIDs = serviceUUIDs
        self.allowDuplicates = allowDuplicates
    }
}
#endif
