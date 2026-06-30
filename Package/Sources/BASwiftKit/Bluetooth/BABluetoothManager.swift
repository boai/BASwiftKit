//
//  BABluetoothManager.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

#if canImport(CoreBluetooth)
import Foundation
import CoreBluetooth

/// CoreBluetooth 单设备/多设备连接和数据处理封装。
///
/// `BABluetoothManager` 支持扫描、连接单个外设或多个外设、发现服务/特征、开启通知、读写数据，
/// 并通过 `eventHandler` 统一回调扫描、连接和数据事件。
///
/// ```swift
/// let manager = BABluetoothManager()
/// manager.eventHandler = { event in
///     if case let .dataReceived(packet) = event {
///         print(packet.device.name ?? "", packet.characteristicUUID, packet.spacedHexString)
///     }
/// }
/// manager.ba_startScan()
/// ```
public final class BABluetoothManager: NSObject {

    /// 蓝牙事件回调。CoreBluetooth 回调队列由初始化时传入的 `queue` 决定。
    public var eventHandler: ((BABluetoothEvent) -> Void)?

    /// 当前中心管理器状态。
    public var ba_state: CBManagerState { centralManager.state }

    /// 当前是否正在扫描。
    public var ba_isScanning: Bool { isScanning }

    /// 已发现外设快照，key 为外设 identifier。
    public var ba_discoveredPeripherals: [UUID: BABluetoothDiscoveredPeripheral] {
        discoveredPeripherals
    }

    /// 已连接、正在连接或正在断开的外设快照，key 为外设 identifier。
    public var ba_connectedPeripherals: [UUID: BABluetoothConnectedPeripheral] {
        managedPeripherals.mapValues { record in
            BABluetoothConnectedPeripheral(
                peripheral: record.peripheral,
                state: record.state,
                services: record.services,
                characteristicsByService: record.characteristicsByService
            )
        }
    }

    lazy var centralManager = CBCentralManager(delegate: self, queue: queue)
    let queue: DispatchQueue?

    // MARK: - 共享状态（线程安全）
    //
    // CoreBluetooth delegate 回调在初始化传入的 queue（可能是后台队列）上触发，
    // 而 public API 在调用方线程访问同一批状态。下列字典/标记若无同步会出现并发读写
    // （Swift Dictionary 并发读写会崩溃）。这里统一用 stateLock 保护：
    // 存储改为私有 `_` 后备，对外通过加锁的计算属性访问（名称不变，调用点零改动）。
    // 锁仅在每次存取的瞬间持有，绝不跨 CoreBluetooth 调用或 eventHandler 回调，避免死锁。
    private let stateLock = NSLock()

    private var _discoveredPeripherals: [UUID: BABluetoothDiscoveredPeripheral] = [:]
    private var _managedPeripherals: [UUID: BABluetoothPeripheralRecord] = [:]
    private var _pendingScan: BABluetoothScanRequest?
    private var _isScanning = false

    var discoveredPeripherals: [UUID: BABluetoothDiscoveredPeripheral] {
        get { stateLock.lock(); defer { stateLock.unlock() }; return _discoveredPeripherals }
        set { stateLock.lock(); _discoveredPeripherals = newValue; stateLock.unlock() }
    }
    var managedPeripherals: [UUID: BABluetoothPeripheralRecord] {
        get { stateLock.lock(); defer { stateLock.unlock() }; return _managedPeripherals }
        set { stateLock.lock(); _managedPeripherals = newValue; stateLock.unlock() }
    }
    var pendingScan: BABluetoothScanRequest? {
        get { stateLock.lock(); defer { stateLock.unlock() }; return _pendingScan }
        set { stateLock.lock(); _pendingScan = newValue; stateLock.unlock() }
    }
    /// 扫描标记（内部读写经锁；对外只读暴露为 `ba_isScanning`）。
    var isScanning: Bool {
        get { stateLock.lock(); defer { stateLock.unlock() }; return _isScanning }
        set { stateLock.lock(); _isScanning = newValue; stateLock.unlock() }
    }

    /// 创建蓝牙管理器。
    ///
    /// - Parameter queue: CoreBluetooth delegate 回调队列。传 `nil` 时使用主队列。
    public init(queue: DispatchQueue? = nil) {
        self.queue = queue
        super.init()
        _ = centralManager
    }

    /// 开始扫描外设。
    ///
    /// - Parameters:
    ///   - serviceUUIDs: 只扫描包含这些服务的外设；传 `nil` 扫描全部外设。
    ///   - allowDuplicates: 是否允许重复发现同一外设，默认 `false`。
    public func ba_startScan(serviceUUIDs: [CBUUID]? = nil, allowDuplicates: Bool = false) {
        ba_startScan(BABluetoothScanRequest(serviceUUIDs: serviceUUIDs, allowDuplicates: allowDuplicates))
    }

    /// 按请求配置开始扫描外设。
    ///
    /// - Parameter request: 扫描请求配置。
    public func ba_startScan(_ request: BABluetoothScanRequest) {
        guard centralManager.state == .poweredOn else {
            // CoreBluetooth 初始化后常先进入 unknown/resetting，先缓存请求，等 poweredOn 回调再启动扫描。
            pendingScan = request
            if centralManager.state != .unknown && centralManager.state != .resetting {
                eventHandler?(.failed(.bluetoothUnavailable(centralManager.state)))
            }
            return
        }
        startScan(request)
    }

    /// 停止扫描外设。
    public func ba_stopScan() {
        pendingScan = nil
        isScanning = false
        centralManager.stopScan()
    }

    /// 连接扫描发现的外设，不影响其他已连接设备。
    ///
    /// - Parameters:
    ///   - peripheral: 目标外设。
    ///   - options: CoreBluetooth 连接选项。
    public func ba_connect(_ peripheral: CBPeripheral, options: [String: Any]? = nil) {
        managedPeripherals[peripheral.identifier] = BABluetoothPeripheralRecord(peripheral: peripheral, state: .connecting)
        peripheral.delegate = self
        centralManager.connect(peripheral, options: options)
        emitConnectionChanged(for: peripheral.identifier)
    }

    /// 只连接一个外设，连接前会断开目前已管理的其他外设。
    ///
    /// - Parameters:
    ///   - peripheral: 目标外设。
    ///   - options: CoreBluetooth 连接选项。
    public func ba_connectOnly(_ peripheral: CBPeripheral, options: [String: Any]? = nil) {
        managedPeripherals.values
            .map(\.peripheral)
            .filter { $0.identifier != peripheral.identifier }
            // 单设备模式下先断开其他已管理外设，多设备模式可直接调用 ba_connect(_:options:)。
            .forEach { ba_disconnect($0) }
        ba_connect(peripheral, options: options)
    }

    /// 批量连接多个外设。
    ///
    /// - Parameters:
    ///   - peripherals: 目标外设数组。
    ///   - options: CoreBluetooth 连接选项。
    public func ba_connect(_ peripherals: [CBPeripheral], options: [String: Any]? = nil) {
        peripherals.forEach { ba_connect($0, options: options) }
    }

    /// 断开指定外设连接。
    ///
    /// - Parameter peripheral: 目标外设。
    public func ba_disconnect(_ peripheral: CBPeripheral) {
        guard var record = managedPeripherals[peripheral.identifier] else { return }
        record.state = .disconnecting
        managedPeripherals[peripheral.identifier] = record
        centralManager.cancelPeripheralConnection(peripheral)
        emitConnectionChanged(for: peripheral.identifier)
    }

    /// 断开指定外设连接。
    ///
    /// - Parameter identifier: 外设唯一标识。
    public func ba_disconnect(identifier: UUID) {
        guard let peripheral = managedPeripherals[identifier]?.peripheral else { return }
        ba_disconnect(peripheral)
    }

    /// 断开全部已管理外设。
    public func ba_disconnectAll() {
        managedPeripherals.values.forEach { ba_disconnect($0.peripheral) }
    }

    /// 发现指定外设的服务。
    ///
    /// - Parameters:
    ///   - peripheral: 已连接外设。
    ///   - serviceUUIDs: 需要发现的服务 UUID；传 `nil` 发现全部服务。
    public func ba_discoverServices(for peripheral: CBPeripheral, serviceUUIDs: [CBUUID]? = nil) {
        guard managedPeripherals[peripheral.identifier]?.state == .connected else {
            eventHandler?(.failed(.peripheralNotConnected(peripheral.identifier)))
            return
        }
        peripheral.discoverServices(serviceUUIDs)
    }

    /// 为全部已连接外设发现服务。
    ///
    /// - Parameter serviceUUIDs: 需要发现的服务 UUID；传 `nil` 发现全部服务。
    public func ba_discoverServicesForAllConnected(serviceUUIDs: [CBUUID]? = nil) {
        managedPeripherals.values
            .filter { $0.state == .connected }
            .forEach { $0.peripheral.discoverServices(serviceUUIDs) }
    }

    /// 发现服务下的特征。
    ///
    /// - Parameters:
    ///   - characteristicUUIDs: 需要发现的特征 UUID；传 `nil` 发现全部特征。
    ///   - service: 已发现的服务。
    public func ba_discoverCharacteristics(_ characteristicUUIDs: [CBUUID]? = nil, for service: CBService) {
        guard let peripheral = service.peripheral else { return }
        peripheral.discoverCharacteristics(characteristicUUIDs, for: service)
    }

    /// 开启或关闭特征通知。
    ///
    /// - Parameters:
    ///   - enabled: 是否开启通知。
    ///   - characteristic: 目标特征。
    ///   - peripheral: 特征所属外设。
    public func ba_setNotify(_ enabled: Bool, for characteristic: CBCharacteristic, on peripheral: CBPeripheral) {
        guard managedPeripherals[peripheral.identifier]?.state == .connected else {
            eventHandler?(.failed(.peripheralNotConnected(peripheral.identifier)))
            return
        }
        peripheral.setNotifyValue(enabled, for: characteristic)
    }

    /// 读取特征数据。
    ///
    /// - Parameters:
    ///   - characteristic: 目标特征。
    ///   - peripheral: 特征所属外设。
    public func ba_readValue(for characteristic: CBCharacteristic, on peripheral: CBPeripheral) {
        guard managedPeripherals[peripheral.identifier]?.state == .connected else {
            eventHandler?(.failed(.peripheralNotConnected(peripheral.identifier)))
            return
        }
        peripheral.readValue(for: characteristic)
    }

    /// 写入特征数据。
    ///
    /// - Parameters:
    ///   - data: 要写入的数据。
    ///   - characteristic: 目标特征。
    ///   - peripheral: 特征所属外设。
    ///   - type: 写入方式，默认 `.withResponse`。
    public func ba_write(_ data: Data,
                         to characteristic: CBCharacteristic,
                         on peripheral: CBPeripheral,
                         type: CBCharacteristicWriteType = .withResponse) {
        guard managedPeripherals[peripheral.identifier]?.state == .connected else {
            eventHandler?(.failed(.peripheralNotConnected(peripheral.identifier)))
            return
        }
        peripheral.writeValue(data, for: characteristic, type: type)
    }

    /// 分包写入特征数据。
    ///
    /// - Parameters:
    ///   - data: 要写入的数据。
    ///   - mtu: 单包最大字节数。
    ///   - characteristic: 目标特征。
    ///   - peripheral: 特征所属外设。
    ///   - type: 写入方式，默认 `.withResponse`。
    public func ba_writeChunks(_ data: Data,
                               mtu: Int,
                               to characteristic: CBCharacteristic,
                               on peripheral: CBPeripheral,
                               type: CBCharacteristicWriteType = .withResponse) {
        data.ba_chunks(size: mtu).forEach { ba_write($0, to: characteristic, on: peripheral, type: type) }
    }

    /// 按 UUID 查找已发现特征。
    ///
    /// - Parameters:
    ///   - characteristicUUID: 特征 UUID。
    ///   - peripheral: 外设。
    /// - Returns: 已缓存的特征；未发现时返回 `nil`。
    public func ba_characteristic(_ characteristicUUID: CBUUID, on peripheral: CBPeripheral) -> CBCharacteristic? {
        managedPeripherals[peripheral.identifier]?
            .characteristicsByService
            .values
            .flatMap { $0 }
            .first { $0.uuid == characteristicUUID }
    }

    /// 按 UUID 写入特征数据。
    ///
    /// - Parameters:
    ///   - data: 要写入的数据。
    ///   - characteristicUUID: 目标特征 UUID。
    ///   - peripheral: 目标外设。
    ///   - type: 写入方式，默认 `.withResponse`。
    public func ba_write(_ data: Data,
                         to characteristicUUID: CBUUID,
                         on peripheral: CBPeripheral,
                         type: CBCharacteristicWriteType = .withResponse) {
        guard let characteristic = ba_characteristic(characteristicUUID, on: peripheral) else {
            eventHandler?(.failed(.characteristicNotFound(characteristicUUID)))
            return
        }
        ba_write(data, to: characteristic, on: peripheral, type: type)
    }

    func emitConnectionChanged(for identifier: UUID) {
        guard let device = ba_connectedPeripherals[identifier] else { return }
        eventHandler?(.connectionChanged(device, device.state))
    }

    func startScan(_ request: BABluetoothScanRequest) {
        isScanning = true
        centralManager.scanForPeripherals(
            withServices: request.serviceUUIDs,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: request.allowDuplicates]
        )
    }
}
#endif
