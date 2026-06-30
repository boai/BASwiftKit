//
//  BARouterTests.swift
//  BASwiftKitTests
//
//  Created by boai on 2026/06/30.
//

import XCTest
@testable import BASwiftKit

// MARK: - Test Doubles

/// 测试用空 Handler（不依赖 UIKit）。
private final class BATestRouteHandler: BARouteHandler {
    func handle(params: [String: Any],
                sourceType: BARouteSourceType,
                animated: Bool,
                completion: @escaping (BARouteError?) -> Void) {
        completion(nil)
    }
}

private func makeConfig(_ pattern: String) -> BARouteConfig {
    BARouteConfig(pattern: pattern, handler: BATestRouteHandler())
}

// MARK: - Trie Tests

final class BARouteTrieTests: XCTestCase {

    func test_staticExactMatch() {
        let trie = BARouteTrie()
        trie.insert("/demo/ui/animation", config: makeConfig("/demo/ui/animation"))

        let result = trie.search("/demo/ui/animation")
        XCTAssertEqual(result?.config.pattern, "/demo/ui/animation")
        XCTAssertTrue(result?.pathParams.isEmpty ?? false)
    }

    func test_noMatchReturnsNil() {
        let trie = BARouteTrie()
        trie.insert("/a/b", config: makeConfig("/a/b"))
        XCTAssertNil(trie.search("/a/c"))
        XCTAssertNil(trie.search("/a/b/c")) // 比注册路径更深
        XCTAssertNil(trie.search("/a"))     // 比注册路径更浅
    }

    func test_paramExtraction() {
        let trie = BARouteTrie()
        trie.insert("/user/detail/:userId", config: makeConfig("/user/detail/:userId"))

        let result = trie.search("/user/detail/123")
        XCTAssertEqual(result?.config.pattern, "/user/detail/:userId")
        XCTAssertEqual(result?.pathParams["userId"], "123")
    }

    func test_multipleParams() {
        let trie = BARouteTrie()
        trie.insert("/order/:orderId/item/:itemId", config: makeConfig("/order/:orderId/item/:itemId"))

        let result = trie.search("/order/A100/item/B200")
        XCTAssertEqual(result?.pathParams["orderId"], "A100")
        XCTAssertEqual(result?.pathParams["itemId"], "B200")
    }

    func test_staticBeatsParam() {
        // 同层同时存在静态段与参数段时，静态优先（最具体者优先）。
        let trie = BARouteTrie()
        trie.insert("/user/:name", config: makeConfig("/user/:name"))
        trie.insert("/user/profile", config: makeConfig("/user/profile"))

        XCTAssertEqual(trie.search("/user/profile")?.config.pattern, "/user/profile")
        XCTAssertEqual(trie.search("/user/boai")?.config.pattern, "/user/:name")
        XCTAssertEqual(trie.search("/user/boai")?.pathParams["name"], "boai")
    }

    func test_wildcardMatchesRemaining() {
        let trie = BARouteTrie()
        trie.insert("/web/*", config: makeConfig("/web/*"))

        XCTAssertEqual(trie.search("/web/a")?.config.pattern, "/web/*")
        XCTAssertEqual(trie.search("/web/a/b/c")?.config.pattern, "/web/*")
        XCTAssertNil(trie.search("/web")) // 通配需至少有一段剩余
    }

    func test_staticBeatsWildcard() {
        let trie = BARouteTrie()
        trie.insert("/web/*", config: makeConfig("/web/*"))
        trie.insert("/web/home", config: makeConfig("/web/home"))

        XCTAssertEqual(trie.search("/web/home")?.config.pattern, "/web/home")
        XCTAssertEqual(trie.search("/web/other")?.config.pattern, "/web/*")
    }

    func test_caseInsensitiveStatic() {
        let trie = BARouteTrie()
        trie.insert("/Demo/UI/Color", config: makeConfig("/Demo/UI/Color"))
        XCTAssertEqual(trie.search("/demo/ui/color")?.config.pattern, "/Demo/UI/Color")
    }

    func test_rootPath() {
        let trie = BARouteTrie()
        trie.insert("/", config: makeConfig("/"))
        XCTAssertEqual(trie.search("/")?.config.pattern, "/")
    }

    func test_overwriteSamePattern() {
        let trie = BARouteTrie()
        trie.insert("/a", config: makeConfig("/a-old"))
        trie.insert("/a", config: makeConfig("/a-new"))
        XCTAssertEqual(trie.search("/a")?.config.pattern, "/a-new")
    }
}

// MARK: - Router Integration Tests

final class BARouterMatchTests: XCTestCase {

    func test_queryAndPathParamsMerged() {
        let router = BARouter.shared
        let pattern = "/unittest/user/:userId"
        let expectation = expectation(description: "route opened")
        var received: [String: Any] = [:]

        router.register(BARouteConfig(pattern: pattern, handler: BAParamCapturingHandler { params in
            received = params
            expectation.fulfill()
        }))
        defer { router.unregister(pattern: pattern) }

        router.open("/unittest/user/42?from=home&vip=1")
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(received["userId"] as? String, "42") // 路径参数
        XCTAssertEqual(received["from"] as? String, "home")  // Query 参数
        XCTAssertEqual(received["vip"] as? String, "1")
    }
}

/// 捕获参数的 Handler（用于集成测试断言参数合并）。
private final class BAParamCapturingHandler: BARouteHandler {
    private let onHandle: ([String: Any]) -> Void
    init(_ onHandle: @escaping ([String: Any]) -> Void) { self.onHandle = onHandle }
    func handle(params: [String: Any],
                sourceType: BARouteSourceType,
                animated: Bool,
                completion: @escaping (BARouteError?) -> Void) {
        onHandle(params)
        completion(nil)
    }
}

// MARK: - Route Params Tests

final class BARouteParamsTests: XCTestCase {

    func test_stringAccessor() {
        let params = BARouteParams(["name": "boai", "age": 28])
        XCTAssertEqual(params.string("name"), "boai")
        XCTAssertEqual(params.string("age"), "28")          // 非字符串兜底
        XCTAssertEqual(params.string("missing", default: "x"), "x")
    }

    func test_intAccessor() {
        let params = BARouteParams(["a": 5, "b": "10", "c": "nope"])
        XCTAssertEqual(params.int("a"), 5)
        XCTAssertEqual(params.int("b"), 10)                 // 字符串解析
        XCTAssertEqual(params.int("c", default: -1), -1)    // 解析失败走默认
    }

    func test_boolAccessor() {
        XCTAssertTrue(BARouteParams(["v": "true"]).bool("v"))
        XCTAssertTrue(BARouteParams(["v": "1"]).bool("v"))
        XCTAssertTrue(BARouteParams(["v": "YES"]).bool("v"))
        XCTAssertFalse(BARouteParams(["v": "0"]).bool("v"))
        XCTAssertFalse(BARouteParams(["v": "false"]).bool("v"))
    }

    func test_doubleAndValue() {
        let params = BARouteParams(["price": "9.9", "count": 3])
        XCTAssertEqual(params.double("price"), 9.9, accuracy: 0.0001)
        XCTAssertEqual(params.value("count", as: Int.self), 3)
    }
}
