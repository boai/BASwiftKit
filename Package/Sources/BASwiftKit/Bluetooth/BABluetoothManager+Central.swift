//
//  BABluetoothManager+Central.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

#if canImport(CoreBluetooth)
import Foundation
import CoreBluetooth

extension BABluetoothManager: CBCentralManagerDelegate {
    /// 蓝牙中心状态变化回调；状态变为 `.poweredOn` 时会执行等待中的扫描请求。
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        eventHandler?(.stateChanged(central.state))
        if central.state == .poweredOn, let pendingScan {
            self.pendingScan = nil
            startScan(pendingScan)
        }
    }

    /// 扫描发现外设时缓存广播信息并派发 `.discovered` 事件。
    public func centralManager(_ central: CBCentralManager,
                               didDiscover peripheral: CBPeripheral,
                               advertisementData: [String: Any],
                               rssi RSSI: NSNumber) {
        let discovered = BABluetoothDiscoveredPeripheral(peripheral: peripheral, advertisementData: advertisementData, rssi: RSSI)
        discoveredPeripherals[peripheral.identifier] = discovered
        eventHandler?(.discovered(discovered))
    }

    /// 外设连接成功时记录连接状态并派发 `.connectionChanged` 事件。
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        // 重连成功后使用新记录，避免沿用上一次连接缓存的服务和特征。
        let record = BABluetoothPeripheralRecord(peripheral: peripheral, state: .connected)
        managedPeripherals[peripheral.identifier] = record
        emitConnectionChanged(for: peripheral.identifier)
    }

    /// 外设连接失败时更新状态并转发系统错误。
    public func centralManager(_ central: CBCentralManager,
                               didFailToConnect peripheral: CBPeripheral,
                               error: Error?) {
        var record = managedPeripherals[peripheral.identifier] ?? BABluetoothPeripheralRecord(peripheral: peripheral, state: .disconnected)
        record.state = .disconnected
        managedPeripherals[peripheral.identifier] = record
        emitConnectionChanged(for: peripheral.identifier)
        if let error { eventHandler?(.failed(.underlying(error))) }
    }

    /// 外设断开连接时更新状态并转发断开错误。
    public func centralManager(_ central: CBCentralManager,
                               didDisconnectPeripheral peripheral: CBPeripheral,
                               error: Error?) {
        var record = managedPeripherals[peripheral.identifier] ?? BABluetoothPeripheralRecord(peripheral: peripheral, state: .disconnected)
        record.state = .disconnected
        managedPeripherals[peripheral.identifier] = record
        emitConnectionChanged(for: peripheral.identifier)
        if let error { eventHandler?(.failed(.underlying(error))) }
    }
}
#endif
