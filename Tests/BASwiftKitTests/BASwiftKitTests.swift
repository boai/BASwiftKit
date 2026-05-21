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
}
