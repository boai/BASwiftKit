//
//  BABluetoothDataPacket.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

#if canImport(CoreBluetooth)
import Foundation
import CoreBluetooth

/// 蓝牙特征上报的数据包。
///
/// 将外设、特征、原始 Data 和接收时间统一包装，业务层可直接读取十六进制、字节数组，
/// 或通过 `ba_reader` 按协议顺序解析整数、浮点数、字符串等字段。
public struct BABluetoothDataPacket {
    /// 数据来源外设。
    public let device: BABluetoothConnectedPeripheral
    /// 数据来源特征。
    public let characteristic: CBCharacteristic
    /// 原始特征数据。
    public let data: Data
    /// 收到数据的时间。
    public let timestamp: Date

    /// 外设唯一标识。
    public var peripheralID: UUID { device.identifier }
    /// 特征 UUID。
    public var characteristicUUID: CBUUID { characteristic.uuid }
    /// 字节数组。
    public var bytes: [UInt8] { data.ba_bytes }
    /// 连续十六进制字符串。
    public var hexString: String { data.ba_hexString }
    /// 带空格分隔的十六进制字符串，便于调试日志查看。
    public var spacedHexString: String { data.ba_spacedHexString }
    /// 按顺序读取字段的数据读取器。
    public var ba_reader: BADataReader { BADataReader(data: data) }

    /// 创建蓝牙数据包。
    ///
    /// - Parameters:
    ///   - device: 数据来源外设。
    ///   - characteristic: 数据来源特征。
    ///   - data: 原始特征数据。
    ///   - timestamp: 收到数据的时间，默认当前时间。
    public init(device: BABluetoothConnectedPeripheral,
                characteristic: CBCharacteristic,
                data: Data,
                timestamp: Date = Date()) {
        self.device = device
        self.characteristic = characteristic
        self.data = data
        self.timestamp = timestamp
    }
}

/// 蓝牙数据分包合并器。
///
/// 一些蓝牙协议会以固定包头/包尾或长度字段拆分发送数据，业务层可把多次收到的 `Data`
/// 追加进该对象，再按包尾或长度取出完整帧。
public final class BABluetoothDataBuffer {
    private var buffer = Data()

    /// 当前缓存数据。
    public var ba_bufferedData: Data { buffer }

    /// 当前缓存字节数。
    public var ba_count: Int { buffer.count }

    /// 创建空数据缓冲区。
    public init() {}

    /// 追加新收到的数据。
    ///
    /// - Parameter data: 待追加的数据片段。
    public func ba_append(_ data: Data) {
        buffer.append(data)
    }

    /// 清空缓存。
    public func ba_removeAll() {
        buffer.removeAll(keepingCapacity: true)
    }

    /// 按固定长度取出一帧数据。
    ///
    /// - Parameter length: 单帧字节长度。
    /// - Returns: 缓存足够时返回一帧并从缓存移除；否则返回 `nil`。
    public func ba_popFrame(length: Int) -> Data? {
        guard length > 0, buffer.count >= length else { return nil }
        let frame = buffer.prefix(length)
        buffer.removeFirst(length)
        return Data(frame)
    }

    /// 按包尾分隔符取出一帧数据。
    ///
    /// - Parameters:
    ///   - delimiter: 包尾分隔符，例如 `0x0D 0x0A`。
    ///   - includesDelimiter: 返回帧里是否保留包尾，默认 `false`。
    /// - Returns: 找到完整包尾时返回一帧并从缓存移除；否则返回 `nil`。
    public func ba_popFrame(delimiter: Data, includesDelimiter: Bool = false) -> Data? {
        guard !delimiter.isEmpty, let range = buffer.range(of: delimiter) else { return nil }
        let frameEnd = includesDelimiter ? range.upperBound : range.lowerBound
        let removeEnd = range.upperBound
        let frame = buffer[..<frameEnd]
        buffer.removeSubrange(..<removeEnd)
        return Data(frame)
    }

    /// 按包头包尾取出一帧数据。
    ///
    /// - Parameters:
    ///   - header: 包头字节。
    ///   - footer: 包尾字节。
    ///   - includesBoundary: 返回帧里是否保留包头包尾，默认 `true`。
    /// - Returns: 找到完整帧时返回并从缓存移除；否则返回 `nil`。
    public func ba_popFrame(header: Data, footer: Data, includesBoundary: Bool = true) -> Data? {
        guard !header.isEmpty, !footer.isEmpty, let headerRange = buffer.range(of: header) else { return nil }
        if headerRange.lowerBound > buffer.startIndex {
            // 丢弃包头之前的脏数据，避免后续解析反复命中无效前缀。
            buffer.removeSubrange(buffer.startIndex..<headerRange.lowerBound)
        }
        guard let footerRange = buffer.range(of: footer, in: headerRange.upperBound..<buffer.endIndex) else { return nil }
        let frameStart = includesBoundary ? headerRange.lowerBound : headerRange.upperBound
        let frameEnd = includesBoundary ? footerRange.upperBound : footerRange.lowerBound
        let frame = buffer[frameStart..<frameEnd]
        buffer.removeSubrange(buffer.startIndex..<footerRange.upperBound)
        return Data(frame)
    }
}
#endif
