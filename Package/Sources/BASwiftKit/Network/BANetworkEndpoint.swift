//
//  BANetworkEndpoint.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

import Foundation

/// Type-safe endpoint description for organizing API modules.
///
/// 使用接口枚举遵循该协议可以把 path、method、headers、parameters 统一收口，
/// ViewModel/Repository 层只需要把 endpoint 交给 `BANetworkClient` 执行。
///
/// ```swift
/// enum UserAPI: BANetworkEndpoint {
///     case detail(id: Int)
///
///     var path: String { "users/\(id)" }
///     var method: BAHTTPMethod { .get }
/// }
/// ```
public protocol BANetworkEndpoint {
    /// Relative path or absolute URL string.
    var path: String { get }
    /// HTTP method for this endpoint.
    var method: BAHTTPMethod { get }
    /// Extra headers for this endpoint.
    var headers: [String: String] { get }
    /// Parameters encoded according to `encoding`.
    var parameters: [String: Any] { get }
    /// Parameter encoding strategy.
    var encoding: BAParameterEncoding { get }
}

public extension BANetworkEndpoint {
    var method: BAHTTPMethod { .get }
    var headers: [String: String] { [:] }
    var parameters: [String: Any] { [:] }
    var encoding: BAParameterEncoding { .query }

    /// Converts this endpoint into an executable request.
    var ba_request: BANetworkRequest {
        BANetworkRequest(path: path, method: method, headers: headers, parameters: parameters, encoding: encoding)
    }
}
