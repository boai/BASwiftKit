//
//  BABluetoothInternalModels.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

#if canImport(CoreBluetooth)
import Foundation
import CoreBluetooth

struct BABluetoothPeripheralRecord {
    var peripheral: CBPeripheral
    var state: BABluetoothConnectionState
    var services: [CBService] = []
    var characteristicsByService: [CBUUID: [CBCharacteristic]] = [:]
}
#endif
