//
//  Data+BABytes.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

import Foundation

/// 字节序。
public enum BAByteOrder {
    /// 高位字节在前，例如网络字节序。
    case bigEndian
    /// 低位字节在前，例如部分蓝牙外设协议。
    case littleEndian
}

/// Data 字节解析错误。
public enum BADataError: Error {
    /// 十六进制字符串包含非法字符或长度不正确。
    case invalidHexString
    /// 读取范围越界。
    case outOfBounds
    /// 字符串编码或解码失败。
    case stringEncodingFailed
}

public extension Data {
    /// 当前数据的字节数组。
    var ba_bytes: [UInt8] { Array(self) }

    /// 连续大写十六进制字符串，例如 `0A1BFF`。
    var ba_hexString: String {
        map { String(format: "%02X", $0) }.joined()
    }

    /// 空格分隔的大写十六进制字符串，例如 `0A 1B FF`。
    var ba_spacedHexString: String {
        map { String(format: "%02X", $0) }.joined(separator: " ")
    }

    /// 根据十六进制字符串创建 Data。
    ///
    /// - Parameter hexString: 十六进制字符串，允许包含空格、换行、`0x` 前缀和冒号分隔符。
    /// - Throws: 字符串长度不是偶数或包含非法字符时抛出 `BADataError.invalidHexString`。
    init(ba_hexString hexString: String) throws {
        var raw = hexString
            .replacingOccurrences(of: "0x", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\t", with: "")
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "-", with: "")
        guard raw.count % 2 == 0 else { throw BADataError.invalidHexString }
        var data = Data(capacity: raw.count / 2)
        while !raw.isEmpty {
            // 每两个十六进制字符正好表示一个字节。
            let byteText = String(raw.prefix(2))
            guard let byte = UInt8(byteText, radix: 16) else { throw BADataError.invalidHexString }
            data.append(byte)
            raw.removeFirst(2)
        }
        self = data
    }

    /// 安全读取指定位置的单字节。
    ///
    /// - Parameter offset: 字节偏移量。
    /// - Returns: 偏移有效时返回字节，否则返回 `nil`。
    func ba_uint8(at offset: Int) -> UInt8? {
        guard indices.contains(offset) else { return nil }
        return self[startIndex + offset]
    }

    /// 安全读取一段子数据。
    ///
    /// - Parameters:
    ///   - offset: 起始偏移量。
    ///   - length: 读取长度。
    /// - Returns: 范围有效时返回子数据，否则返回 `nil`。
    func ba_subdata(offset: Int, length: Int) -> Data? {
        guard offset >= 0, length >= 0, offset + length <= count else { return nil }
        return subdata(in: offset..<(offset + length))
    }

    /// 读取无符号整数，支持 1、2、4、8 字节。
    ///
    /// - Parameters:
    ///   - offset: 起始偏移量。
    ///   - length: 字节长度，仅支持 1、2、4、8。
    ///   - byteOrder: 字节序，默认 `.bigEndian`。
    /// - Returns: 读取成功返回整数，否则返回 `nil`。
    func ba_uint(offset: Int, length: Int, byteOrder: BAByteOrder = .bigEndian) -> UInt64? {
        guard [1, 2, 4, 8].contains(length), let slice = ba_subdata(offset: offset, length: length) else { return nil }
        let bytes = byteOrder == .bigEndian ? slice.ba_bytes : slice.ba_bytes.reversed()
        // 统一转成高位在前后再左移累加，避免每种字节序单独写解析逻辑。
        return bytes.reduce(UInt64(0)) { ($0 << 8) | UInt64($1) }
    }

    /// 读取 `UInt16`。
    ///
    /// - Parameters:
    ///   - offset: 起始偏移量。
    ///   - byteOrder: 字节序，默认 `.bigEndian`。
    /// - Returns: 读取成功返回 `UInt16`，否则返回 `nil`。
    func ba_uint16(offset: Int, byteOrder: BAByteOrder = .bigEndian) -> UInt16? {
        ba_uint(offset: offset, length: 2, byteOrder: byteOrder).map(UInt16.init)
    }

    /// 读取 `UInt32`。
    ///
    /// - Parameters:
    ///   - offset: 起始偏移量。
    ///   - byteOrder: 字节序，默认 `.bigEndian`。
    /// - Returns: 读取成功返回 `UInt32`，否则返回 `nil`。
    func ba_uint32(offset: Int, byteOrder: BAByteOrder = .bigEndian) -> UInt32? {
        ba_uint(offset: offset, length: 4, byteOrder: byteOrder).map(UInt32.init)
    }

    /// 读取 `UInt64`。
    ///
    /// - Parameters:
    ///   - offset: 起始偏移量。
    ///   - byteOrder: 字节序，默认 `.bigEndian`。
    /// - Returns: 读取成功返回 `UInt64`，否则返回 `nil`。
    func ba_uint64(offset: Int, byteOrder: BAByteOrder = .bigEndian) -> UInt64? {
        ba_uint(offset: offset, length: 8, byteOrder: byteOrder)
    }

    /// 读取 UTF-8 字符串。
    ///
    /// - Parameters:
    ///   - offset: 起始偏移量。
    ///   - length: 字节长度。
    ///   - encoding: 字符编码，默认 `.utf8`。
    /// - Returns: 解码成功返回字符串，否则返回 `nil`。
    func ba_string(offset: Int, length: Int, encoding: String.Encoding = .utf8) -> String? {
        guard let data = ba_subdata(offset: offset, length: length) else { return nil }
        return String(data: data, encoding: encoding)
    }

    /// 在尾部追加一个字节后返回新 Data。
    ///
    /// - Parameter byte: 要追加的字节。
    /// - Returns: 追加后的新 Data。
    func ba_appending(byte: UInt8) -> Data {
        var data = self
        data.append(byte)
        return data
    }

    /// 在尾部追加字节数组后返回新 Data。
    ///
    /// - Parameter bytes: 要追加的字节数组。
    /// - Returns: 追加后的新 Data。
    func ba_appending(bytes: [UInt8]) -> Data {
        var data = self
        data.append(contentsOf: bytes)
        return data
    }

    /// 将数据按固定长度拆分为多个 Data。
    ///
    /// - Parameter size: 每片最大字节数。
    /// - Returns: 分片数组；`size <= 0` 时返回空数组。
    func ba_chunks(size: Int) -> [Data] {
        guard size > 0, !isEmpty else { return [] }
        var result: [Data] = []
        var offset = 0
        while offset < count {
            let length = Swift.min(size, count - offset)
            result.append(subdata(in: offset..<(offset + length)))
            offset += length
        }
        return result
    }

    /// 逐字节累加校验和，返回低 8 位。
    var ba_checksum8: UInt8 {
        reduce(UInt8(0)) { $0 &+ $1 }
    }

    /// 逐字节异或校验值。
    var ba_xorChecksum: UInt8 {
        reduce(UInt8(0)) { $0 ^ $1 }
    }

    /// CRC16-MODBUS 校验值。
    ///
    /// - Parameters:
    ///   - initial: 初始值，默认 `0xFFFF`。
    ///   - polynomial: 多项式，默认 `0xA001`。
    /// - Returns: CRC16 校验值。
    func ba_crc16Modbus(initial: UInt16 = 0xFFFF, polynomial: UInt16 = 0xA001) -> UInt16 {
        var crc = initial
        for byte in self {
            crc ^= UInt16(byte)
            // MODBUS CRC 按低位优先处理每个 bit。
            for _ in 0..<8 {
                if crc & 0x0001 != 0 {
                    crc = (crc >> 1) ^ polynomial
                } else {
                    crc >>= 1
                }
            }
        }
        return crc
    }

    /// CRC16-MODBUS 校验字节，低字节在前。
    var ba_crc16ModbusData: Data {
        let crc = ba_crc16Modbus()
        return Data([UInt8(crc & 0x00FF), UInt8((crc >> 8) & 0x00FF)])
    }
}

public extension FixedWidthInteger {
    /// 按指定字节序转换为 Data。
    ///
    /// - Parameter byteOrder: 字节序，默认 `.bigEndian`。
    /// - Returns: 整数对应的字节数据。
    func ba_data(byteOrder: BAByteOrder = .bigEndian) -> Data {
        let bytes = withUnsafeBytes(of: self) { Array($0) }
        return Data(byteOrder == .bigEndian ? bytes.reversed() : bytes)
    }
}

/// 顺序读取 Data 的字节读取器。
///
/// 适合解析蓝牙协议中的固定字段报文：先读包头，再读长度、命令字、payload、校验位。
public struct BADataReader {
    /// 被读取的原始数据。
    public let data: Data
    /// 当前读取偏移量。
    public private(set) var offset: Int

    /// 剩余未读取字节数。
    public var remainingCount: Int { max(0, data.count - offset) }
    /// 是否已经读到末尾。
    public var isAtEnd: Bool { offset >= data.count }

    /// 创建 Data 读取器。
    ///
    /// - Parameters:
    ///   - data: 原始数据。
    ///   - offset: 初始偏移量，默认 0。
    public init(data: Data, offset: Int = 0) {
        self.data = data
        self.offset = max(0, offset)
    }

    /// 跳过指定字节数。
    ///
    /// - Parameter count: 要跳过的字节数。
    /// - Throws: 超出数据范围时抛出 `BADataError.outOfBounds`。
    public mutating func skip(_ count: Int) throws {
        guard count >= 0, offset + count <= data.count else { throw BADataError.outOfBounds }
        offset += count
    }

    /// 读取一个字节。
    ///
    /// - Returns: 读取到的字节。
    /// - Throws: 超出数据范围时抛出 `BADataError.outOfBounds`。
    public mutating func readUInt8() throws -> UInt8 {
        guard let value = data.ba_uint8(at: offset) else { throw BADataError.outOfBounds }
        offset += 1
        return value
    }

    /// 读取 `UInt16`。
    ///
    /// - Parameter byteOrder: 字节序，默认 `.bigEndian`。
    /// - Returns: 读取到的 `UInt16`。
    /// - Throws: 超出数据范围时抛出 `BADataError.outOfBounds`。
    public mutating func readUInt16(byteOrder: BAByteOrder = .bigEndian) throws -> UInt16 {
        guard let value = data.ba_uint16(offset: offset, byteOrder: byteOrder) else { throw BADataError.outOfBounds }
        offset += 2
        return value
    }

    /// 读取 `UInt32`。
    ///
    /// - Parameter byteOrder: 字节序，默认 `.bigEndian`。
    /// - Returns: 读取到的 `UInt32`。
    /// - Throws: 超出数据范围时抛出 `BADataError.outOfBounds`。
    public mutating func readUInt32(byteOrder: BAByteOrder = .bigEndian) throws -> UInt32 {
        guard let value = data.ba_uint32(offset: offset, byteOrder: byteOrder) else { throw BADataError.outOfBounds }
        offset += 4
        return value
    }

    /// 读取指定长度 Data。
    ///
    /// - Parameter length: 要读取的字节数。
    /// - Returns: 子数据。
    /// - Throws: 超出数据范围时抛出 `BADataError.outOfBounds`。
    public mutating func readData(length: Int) throws -> Data {
        guard let value = data.ba_subdata(offset: offset, length: length) else { throw BADataError.outOfBounds }
        offset += length
        return value
    }

    /// 读取指定长度字符串。
    ///
    /// - Parameters:
    ///   - length: 字节长度。
    ///   - encoding: 字符编码，默认 `.utf8`。
    /// - Returns: 解码后的字符串。
    /// - Throws: 越界时抛出 `BADataError.outOfBounds`，编码失败时抛出 `BADataError.stringEncodingFailed`。
    public mutating func readString(length: Int, encoding: String.Encoding = .utf8) throws -> String {
        let data = try readData(length: length)
        guard let string = String(data: data, encoding: encoding) else { throw BADataError.stringEncodingFailed }
        return string
    }
}
