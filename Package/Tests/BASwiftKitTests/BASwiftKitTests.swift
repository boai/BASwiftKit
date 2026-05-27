//
//  BASwiftKitTests.swift
//  BASwiftKitTests
//
//  Created by boai on 2026/05/21.
//

import XCTest
@testable import BASwiftKit

final class BASwiftKitTests: XCTestCase {

    func test_versionIsNotEmpty() {
        XCTAssertFalse(BASwiftKit.version.isEmpty)
    }

    func test_stringTrim() {
        XCTAssertEqual("   abc  ".ba_trimmed, "abc")
    }

    func test_stringBlank() {
        XCTAssertTrue("    \n".ba_isBlank)
        XCTAssertFalse("hi".ba_isBlank)
    }

    func test_emailValidation() {
        XCTAssertTrue("a@b.co".ba_isEmail)
        XCTAssertFalse("a@b".ba_isEmail)
    }

    func test_md5() {
        XCTAssertEqual("hello".ba_md5, "5d41402abc4b2a76b9719d911017c592")
    }

    func test_base64Roundtrip() {
        let raw = "hi 你好"
        let encoded = raw.ba_base64Encoded
        XCTAssertNotNil(encoded)
        XCTAssertEqual(encoded?.ba_base64Decoded, raw)
    }

    func test_arrayUnique() {
        XCTAssertEqual([1, 2, 2, 3, 1].ba_unique(), [1, 2, 3])
    }

    func test_arrayChunked() {
        XCTAssertEqual([1, 2, 3, 4, 5].ba_chunked(into: 2), [[1, 2], [3, 4], [5]])
    }

    func test_collectionSafeSubscript() {
        let arr = [10, 20, 30]
        XCTAssertEqual(arr.ba_safe(1), 20)
        XCTAssertNil(arr.ba_safe(10))
    }

    func test_dateRelative() {
        let now = Date()
        XCTAssertEqual(now.ba_relativeFromNow, "刚刚")
    }

    // MARK: - Date+Calendar

    func test_dateStartAndEndOfDay() {
        let d = "2026-05-21 13:45:30".ba_date()!
        let start = d.ba_startOfDay()
        let end = d.ba_endOfDay()
        XCTAssertEqual(start.ba_components.hour, 0)
        XCTAssertEqual(start.ba_components.minute, 0)
        XCTAssertEqual(end.ba_components.hour, 23)
        XCTAssertEqual(end.ba_components.minute, 59)
    }

    func test_dateAddingDays() {
        let d = "2026-05-21".ba_date(format: "yyyy-MM-dd")!
        let next = d.ba_adding(days: 10)
        XCTAssertEqual(d.ba_daysBetween(next), 10)
    }

    func test_dateIsToday() {
        XCTAssertTrue(Date().ba_isToday)
    }

    // MARK: - Localization

    func test_localizationRoundtrip() {
        BALocalization.shared.register(["unit_test_key": "Hello"], for: "en")
        BALocalization.shared.register(["unit_test_key": "你好"], for: "zh-Hans")

        BALocalization.shared.setLanguage("en")
        XCTAssertEqual("unit_test_key".ba_localized, "Hello")

        BALocalization.shared.setLanguage("zh-Hans")
        XCTAssertEqual("unit_test_key".ba_localized, "你好")

        // 未注册 key 走兜底
        XCTAssertEqual("nonexistent_key".ba_localized, "nonexistent_key")
    }

    // MARK: - Data+BABytes

    func test_dataHexAndEndianParsing() throws {
        let data = try Data(ba_hexString: "01 02 0A FF")
        XCTAssertEqual(data.ba_bytes, [0x01, 0x02, 0x0A, 0xFF])
        XCTAssertEqual(data.ba_hexString, "01020AFF")
        XCTAssertEqual(data.ba_spacedHexString, "01 02 0A FF")
        XCTAssertEqual(data.ba_uint16(offset: 0, byteOrder: .bigEndian), 0x0102)
        XCTAssertEqual(data.ba_uint16(offset: 0, byteOrder: .littleEndian), 0x0201)
    }

    func test_dataReaderAndChunks() throws {
        let data = try Data(ba_hexString: "01 02 0A FF")
        var reader = BADataReader(data: data)
        XCTAssertEqual(try reader.readUInt8(), 0x01)
        XCTAssertEqual(try reader.readUInt16(byteOrder: .bigEndian), 0x020A)
        XCTAssertEqual(reader.remainingCount, 1)
        XCTAssertEqual(data.ba_chunks(size: 2).map(\.ba_hexString), ["0102", "0AFF"])
    }

    func test_bluetoothDataBufferFrames() throws {
        let buffer = BABluetoothDataBuffer()
        buffer.ba_append(try Data(ba_hexString: "AA 01 02 55 AA 03 55"))
        XCTAssertEqual(buffer.ba_popFrame(header: Data([0xAA]), footer: Data([0x55]))?.ba_hexString, "AA010255")
        XCTAssertEqual(buffer.ba_popFrame(header: Data([0xAA]), footer: Data([0x55]), includesBoundary: false)?.ba_hexString, "03")
    }

    func test_baseModelCacheLifecycle() {
        let cache = BACacheManager(strategy: .memory)
        let key = "unit_test_base_model"
        let model = BATestUserModel(id: 1, name: "boai")

        XCTAssertTrue(model.ba_saveCache(key: key, cache: cache))
        XCTAssertTrue(BATestUserModel.ba_hasCache(key: key, cache: cache))

        let cached: BATestUserModel? = BATestUserModel.ba_cache(key: key, cache: cache)
        XCTAssertEqual(cached?.id, 1)
        XCTAssertEqual(cached?.name, "boai")

        model.name = "updated"
        XCTAssertTrue(model.ba_updateCache(key: key, cache: cache))
        let updated: BATestUserModel? = BATestUserModel.ba_cache(key: key, cache: cache)
        XCTAssertEqual(updated?.name, "updated")

        model.ba_removeCache(key: key, cache: cache)
        XCTAssertNil(BATestUserModel.ba_cache(key: key, cache: cache) as BATestUserModel?)
    }

    func test_networkRequestBuildsQueryAndFormBody() throws {
        let client = BANetworkClient(configuration: BANetworkConfiguration(baseURL: URL(string: "https://api.example.com")))
        let query = try client.makeURLRequest(BANetworkRequest(path: "users", parameters: ["page": 1]))
        XCTAssertEqual(query.url?.absoluteString, "https://api.example.com/users?page=1")

        let form = try client.makeURLRequest(BANetworkRequest(path: "login", method: .post, parameters: ["name": "boai"], encoding: .formURLEncoded))
        XCTAssertEqual(form.value(forHTTPHeaderField: "Content-Type"), "application/x-www-form-urlencoded; charset=utf-8")
        XCTAssertEqual(String(data: form.httpBody ?? Data(), encoding: .utf8), "name=boai")
    }

    func test_cryptoHashHMACAndAES() throws {
        XCTAssertEqual("abc".ba_sha256, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad")
        XCTAssertEqual("hello".ba_hmac(key: "key", algorithm: .sha256), "9307b3b915efb5171ff14d8cb55fbcc798c6c0ef1456d66ded1a6aa723a58b7b")

        let key = "1234567890abcdef"
        let iv = "abcdef1234567890"
        let encrypted = try "BASwiftKit".ba_aesCBCEncryptedBase64(key: key, iv: iv)
        XCTAssertEqual(try encrypted.ba_aesCBCDecryptedFromBase64(key: key, iv: iv), "BASwiftKit")
    }
}

final class BATestUserModel: BABaseModel, Codable {
    var id: Int
    var name: String

    init(id: Int, name: String) {
        self.id = id
        self.name = name
        super.init()
    }
}

