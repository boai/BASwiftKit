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
}
