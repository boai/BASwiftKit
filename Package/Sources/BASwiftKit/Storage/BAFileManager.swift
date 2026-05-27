//
//  BAFileManager.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

import Foundation

/// FileManager 常用文件操作封装。
///
/// 统一处理 App 沙盒目录、文件读写、目录创建、移动/复制/删除、大小统计等能力。
/// 所有写入类方法都会在需要时自动创建父目录。
public enum BAFileManager {

    /// 常用沙盒目录类型，便于用相对路径读写文件。
    public enum BADirectory {
        /// App 沙盒 Document 目录，适合保存用户生成且需要长期保留的文件。
        case documents
        /// App 沙盒 Library 目录，适合保存支持文件、数据库、离线资源等。
        case library
        /// App 沙盒 Caches 目录，适合保存可重新生成的缓存文件。
        case caches
        /// App 临时目录，系统可在需要时清理。
        case temporary

        /// 目录对应的 URL。
        public var url: URL {
            switch self {
            case .documents:
                return BAFileManager.ba_documentsDirectory
            case .library:
                return BAFileManager.ba_libraryDirectory
            case .caches:
                return BAFileManager.ba_cachesDirectory
            case .temporary:
                return BAFileManager.ba_temporaryDirectory
            }
        }
    }

    /// App 沙盒 Document 目录，适合保存用户生成且需要长期保留的文件。
    public static var ba_documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// App 沙盒 Library 目录，适合保存支持文件、数据库、离线资源等。
    public static var ba_libraryDirectory: URL {
        FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
    }

    /// App 沙盒 Caches 目录，适合保存可重新生成的缓存文件。
    public static var ba_cachesDirectory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
    }

    /// App 临时目录，系统可在需要时清理。
    public static var ba_temporaryDirectory: URL {
        FileManager.default.temporaryDirectory
    }

    /// 判断指定路径是否存在。
    ///
    /// - Parameter url: 需要检查的文件或目录 URL。
    /// - Returns: 路径存在返回 `true`，否则返回 `false`。
    public static func ba_exists(at url: URL) -> Bool {
        FileManager.default.fileExists(atPath: url.path)
    }

    /// 判断指定 URL 是否为目录。
    ///
    /// - Parameter url: 需要检查的 URL。
    /// - Returns: URL 存在且是目录返回 `true`。
    public static func ba_isDirectory(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }

    /// 创建目录。
    ///
    /// - Parameters:
    ///   - url: 目录 URL。
    ///   - createIntermediates: 是否自动创建不存在的上级目录，默认 `true`。
    /// - Throws: `FileManager` 创建目录时抛出的错误。
    public static func ba_createDirectory(at url: URL, createIntermediates: Bool = true) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: createIntermediates)
    }

    /// 写入二进制数据。
    ///
    /// - Parameters:
    ///   - data: 要写入的内容。
    ///   - url: 目标文件 URL。
    ///   - options: 写入选项，默认 `.atomic`，避免写入中断留下半个文件。
    /// - Throws: 创建父目录或写入文件时抛出的错误。
    public static func ba_write(_ data: Data, to url: URL, options: Data.WritingOptions = .atomic) throws {
        try ba_createParentDirectoryIfNeeded(for: url)
        try data.write(to: url, options: options)
    }

    /// 写入字符串。
    ///
    /// - Parameters:
    ///   - string: 要写入的文本。
    ///   - url: 目标文件 URL。
    ///   - encoding: 字符编码，默认 `.utf8`。
    /// - Throws: 编码失败、创建父目录或写入文件时抛出的错误。
    public static func ba_write(_ string: String, to url: URL, encoding: String.Encoding = .utf8) throws {
        guard let data = string.data(using: encoding) else {
            throw BAFileManagerError.encodingFailed
        }
        try ba_write(data, to: url)
    }

    /// 写入二进制数据到指定沙盒目录下的相对路径。
    ///
    /// - Parameters:
    ///   - data: 要写入的内容。
    ///   - path: 相对路径，例如 `logs/app.log`。
    ///   - directory: 沙盒基准目录，默认 `.documents`。
    ///   - options: 写入选项，默认 `.atomic`。
    /// - Throws: 创建父目录或写入文件时抛出的错误。
    public static func ba_write(_ data: Data,
                                to path: String,
                                in directory: BADirectory = .documents,
                                options: Data.WritingOptions = .atomic) throws {
        try ba_write(data, to: ba_url(for: path, in: directory), options: options)
    }

    /// 写入字符串到指定沙盒目录下的相对路径。
    ///
    /// - Parameters:
    ///   - string: 要写入的文本。
    ///   - path: 相对路径，例如 `config/profile.json`。
    ///   - directory: 沙盒基准目录，默认 `.documents`。
    ///   - encoding: 字符编码，默认 `.utf8`。
    /// - Throws: 编码失败、创建父目录或写入文件时抛出的错误。
    public static func ba_write(_ string: String,
                                to path: String,
                                in directory: BADirectory = .documents,
                                encoding: String.Encoding = .utf8) throws {
        try ba_write(string, to: ba_url(for: path, in: directory), encoding: encoding)
    }

    /// 将 Codable 对象编码为 JSON 并写入文件。
    ///
    /// - Parameters:
    ///   - value: 要保存的 Codable 对象。
    ///   - path: 相对路径，例如 `user/profile.json`。
    ///   - directory: 沙盒基准目录，默认 `.documents`。
    ///   - encoder: JSON 编码器，默认 `JSONEncoder()`。
    /// - Throws: JSON 编码、创建父目录或写入文件时抛出的错误。
    public static func ba_writeJSON<T: Encodable>(_ value: T,
                                                  to path: String,
                                                  in directory: BADirectory = .documents,
                                                  encoder: JSONEncoder = JSONEncoder()) throws {
        try ba_write(encoder.encode(value), to: path, in: directory)
    }

    /// 读取二进制数据。
    ///
    /// - Parameter url: 文件 URL。
    /// - Returns: 文件内容。
    /// - Throws: `Data(contentsOf:)` 读取错误。
    public static func ba_readData(from url: URL) throws -> Data {
        try Data(contentsOf: url)
    }

    /// 读取指定沙盒目录下相对路径的二进制数据。
    ///
    /// - Parameters:
    ///   - path: 相对路径，例如 `images/avatar.png`。
    ///   - directory: 沙盒基准目录，默认 `.documents`。
    /// - Returns: 文件内容。
    /// - Throws: `Data(contentsOf:)` 读取错误。
    public static func ba_readData(from path: String, in directory: BADirectory = .documents) throws -> Data {
        try ba_readData(from: ba_url(for: path, in: directory))
    }

    /// 读取字符串。
    ///
    /// - Parameters:
    ///   - url: 文件 URL。
    ///   - encoding: 字符编码，默认 `.utf8`。
    /// - Returns: 文件文本内容。
    /// - Throws: 文件读取或文本解码错误。
    public static func ba_readString(from url: URL, encoding: String.Encoding = .utf8) throws -> String {
        guard let string = String(data: try ba_readData(from: url), encoding: encoding) else {
            throw BAFileManagerError.decodingFailed
        }
        return string
    }

    /// 读取指定沙盒目录下相对路径的字符串。
    ///
    /// - Parameters:
    ///   - path: 相对路径，例如 `logs/app.log`。
    ///   - directory: 沙盒基准目录，默认 `.documents`。
    ///   - encoding: 字符编码，默认 `.utf8`。
    /// - Returns: 文件文本内容。
    /// - Throws: 文件读取或文本解码错误。
    public static func ba_readString(from path: String,
                                     in directory: BADirectory = .documents,
                                     encoding: String.Encoding = .utf8) throws -> String {
        try ba_readString(from: ba_url(for: path, in: directory), encoding: encoding)
    }

    /// 从 JSON 文件解码 Codable 对象。
    ///
    /// - Parameters:
    ///   - path: 相对路径，例如 `user/profile.json`。
    ///   - type: 目标类型。
    ///   - directory: 沙盒基准目录，默认 `.documents`。
    ///   - decoder: JSON 解码器，默认 `JSONDecoder()`。
    /// - Returns: 解码后的对象。
    /// - Throws: 读取文件或 JSON 解码时抛出的错误。
    public static func ba_readJSON<T: Decodable>(from path: String,
                                                 type: T.Type,
                                                 in directory: BADirectory = .documents,
                                                 decoder: JSONDecoder = JSONDecoder()) throws -> T {
        try decoder.decode(type, from: ba_readData(from: path, in: directory))
    }

    /// 删除文件或目录；路径不存在时不做任何操作。
    ///
    /// - Parameter url: 要删除的文件或目录 URL。
    /// - Throws: `FileManager` 删除时抛出的错误。
    public static func ba_removeItem(at url: URL) throws {
        guard ba_exists(at: url) else { return }
        try FileManager.default.removeItem(at: url)
    }

    /// 删除指定沙盒目录下相对路径的文件或目录；路径不存在时不做任何操作。
    ///
    /// - Parameters:
    ///   - path: 相对路径。
    ///   - directory: 沙盒基准目录，默认 `.documents`。
    /// - Throws: `FileManager` 删除时抛出的错误。
    public static func ba_removeItem(at path: String, in directory: BADirectory = .documents) throws {
        try ba_removeItem(at: ba_url(for: path, in: directory))
    }

    /// 复制文件或目录；目标父目录不存在时会自动创建。
    ///
    /// - Parameters:
    ///   - sourceURL: 源 URL。
    ///   - destinationURL: 目标 URL。
    ///   - overwrite: 目标已存在时是否先删除再复制，默认 `false`。
    /// - Throws: 创建父目录、删除旧文件或复制时抛出的错误。
    public static func ba_copyItem(from sourceURL: URL, to destinationURL: URL, overwrite: Bool = false) throws {
        try ba_createParentDirectoryIfNeeded(for: destinationURL)
        if overwrite {
            try ba_removeItem(at: destinationURL)
        }
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
    }

    /// 移动文件或目录；目标父目录不存在时会自动创建。
    ///
    /// - Parameters:
    ///   - sourceURL: 源 URL。
    ///   - destinationURL: 目标 URL。
    ///   - overwrite: 目标已存在时是否先删除再移动，默认 `false`。
    /// - Throws: 创建父目录、删除旧文件或移动时抛出的错误。
    public static func ba_moveItem(from sourceURL: URL, to destinationURL: URL, overwrite: Bool = false) throws {
        try ba_createParentDirectoryIfNeeded(for: destinationURL)
        if overwrite {
            try ba_removeItem(at: destinationURL)
        }
        try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
    }

    /// 列出目录下的直接子项。
    ///
    /// - Parameters:
    ///   - url: 目录 URL。
    ///   - includingPropertiesForKeys: 需要预取的资源字段。
    ///   - skipsHiddenFiles: 是否跳过隐藏文件，默认 `true`。
    /// - Returns: 子文件和子目录 URL 数组。
    /// - Throws: 枚举目录时抛出的错误。
    public static func ba_contentsOfDirectory(at url: URL,
                                              includingPropertiesForKeys keys: [URLResourceKey]? = nil,
                                              skipsHiddenFiles: Bool = true) throws -> [URL] {
        let options: FileManager.DirectoryEnumerationOptions = skipsHiddenFiles ? [.skipsHiddenFiles] : []
        return try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: keys, options: options)
    }

    /// 递归计算文件或目录大小。
    ///
    /// - Parameter url: 文件或目录 URL。
    /// - Returns: 字节数；路径不存在返回 0。
    /// - Throws: 读取文件属性或枚举目录时抛出的错误。
    public static func ba_sizeOfItem(at url: URL) throws -> UInt64 {
        guard ba_exists(at: url) else { return 0 }
        if !ba_isDirectory(at: url) {
            return try ba_fileSize(at: url)
        }
        let urls = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: [.skipsHiddenFiles])?.compactMap { $0 as? URL } ?? []
        return try urls.reduce(UInt64(0)) { partial, fileURL in
            partial + (ba_isDirectory(at: fileURL) ? 0 : try ba_fileSize(at: fileURL))
        }
    }

    /// 生成指定目录下的子路径 URL。
    ///
    /// - Parameters:
    ///   - path: 相对路径，例如 `images/avatar.png`。
    ///   - directory: 基准目录，默认 Document 目录。
    /// - Returns: 拼接后的文件 URL。
    public static func ba_url(for path: String, in directory: URL = ba_documentsDirectory) -> URL {
        directory.appendingPathComponent(path)
    }

    /// 生成指定沙盒目录下的子路径 URL。
    ///
    /// - Parameters:
    ///   - path: 相对路径，例如 `images/avatar.png`。
    ///   - directory: 沙盒基准目录，默认 `.documents`。
    /// - Returns: 拼接后的文件 URL。
    public static func ba_url(for path: String, in directory: BADirectory = .documents) -> URL {
        directory.url.appendingPathComponent(path)
    }

    /// 递归计算指定沙盒目录下相对路径的大小。
    ///
    /// - Parameters:
    ///   - path: 相对路径。
    ///   - directory: 沙盒基准目录，默认 `.documents`。
    /// - Returns: 字节数；路径不存在返回 0。
    /// - Throws: 读取文件属性或枚举目录时抛出的错误。
    public static func ba_sizeOfItem(at path: String, in directory: BADirectory = .documents) throws -> UInt64 {
        try ba_sizeOfItem(at: ba_url(for: path, in: directory))
    }

    /// 将字节数格式化为系统本地化文件大小文本。
    ///
    /// - Parameter bytes: 字节数。
    /// - Returns: 格式化后的大小文本，例如 `12 KB`。
    public static func ba_formattedSize(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    private static func ba_createParentDirectoryIfNeeded(for fileURL: URL) throws {
        let parentURL = fileURL.deletingLastPathComponent()
        guard !ba_exists(at: parentURL) else { return }
        try ba_createDirectory(at: parentURL)
    }

    private static func ba_fileSize(at url: URL) throws -> UInt64 {
        let values = try url.resourceValues(forKeys: [.fileSizeKey])
        return UInt64(values.fileSize ?? 0)
    }
}

/// FileManager 封装内部错误。
public enum BAFileManagerError: Error {
    /// 字符串无法按指定编码转换成 Data。
    case encodingFailed
    /// Data 无法按指定编码转换成字符串。
    case decodingFailed
}
