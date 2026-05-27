//
//  BABluetoothManager+Peripheral.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

#if canImport(CoreBluetooth)
import Foundation
import CoreBluetooth

extension BABluetoothManager: CBPeripheralDelegate {
    /// 服务发现完成时缓存服务列表并派发 `.servicesDiscovered` 事件。
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error {
            eventHandler?(.failed(.underlying(error)))
            return
        }
        guard var record = managedPeripherals[peripheral.identifier] else { return }
        record.services = peripheral.services ?? []
        managedPeripherals[peripheral.identifier] = record
        if let device = ba_connectedPeripherals[peripheral.identifier] {
            eventHandler?(.servicesDiscovered(device, record.services))
        }
    }

    /// 特征发现完成时按服务 UUID 缓存特征并派发 `.characteristicsDiscovered` 事件。
    public func peripheral(_ peripheral: CBPeripheral,
                           didDiscoverCharacteristicsFor service: CBService,
                           error: Error?) {
        if let error {
            eventHandler?(.failed(.underlying(error)))
            return
        }
        guard var record = managedPeripherals[peripheral.identifier] else { return }
        let characteristics = service.characteristics ?? []
        record.characteristicsByService[service.uuid] = characteristics
        managedPeripherals[peripheral.identifier] = record
        if let device = ba_connectedPeripherals[peripheral.identifier] {
            eventHandler?(.characteristicsDiscovered(device, service, characteristics))
        }
    }

    /// 特征值更新时读取数据并派发 `.dataReceived` 事件。
    public func peripheral(_ peripheral: CBPeripheral,
                           didUpdateValueFor characteristic: CBCharacteristic,
                           error: Error?) {
        if let error {
            eventHandler?(.failed(.underlying(error)))
            return
        }
        guard let data = characteristic.value,
              let device = ba_connectedPeripherals[peripheral.identifier] else { return }
        let packet = BABluetoothDataPacket(device: device, characteristic: characteristic, data: data)
        eventHandler?(.dataReceived(packet))
    }

    /// 写入特征完成时转发可能出现的系统错误。
    public func peripheral(_ peripheral: CBPeripheral,
                           didWriteValueFor characteristic: CBCharacteristic,
                           error: Error?) {
        if let error {
            eventHandler?(.failed(.underlying(error)))
        }
    }

    /// 通知状态变化完成时转发可能出现的系统错误。
    public func peripheral(_ peripheral: CBPeripheral,
                           didUpdateNotificationStateFor characteristic: CBCharacteristic,
                           error: Error?) {
        if let error {
            eventHandler?(.failed(.underlying(error)))
        }
    }
}
#endif
