//
//  BANetworkRequest.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

import Foundation

/// Describes one network request before it is converted into `URLRequest`.
public struct BANetworkRequest {
    /// Absolute URL string or relative path. Relative paths are appended to `configuration.baseURL`.
    public var path: String
    /// HTTP method used by the request.
    public var method: BAHTTPMethod
    /// Headers that override or extend `BANetworkConfiguration.defaultHeaders`.
    public var headers: [String: String]
    /// Request parameters encoded according to `encoding`.
    public var parameters: [String: Any]
    /// Parameter placement strategy for `parameters`.
    public var encoding: BAParameterEncoding

    /// Creates a request description that can be executed by `BANetworkClient`.
    ///
    /// - Parameters:
    ///   - path: Absolute URL string or relative endpoint path such as `users/1`.
    ///   - method: HTTP method. Defaults to `.get`.
    ///   - headers: Request-specific headers. Values with the same key override default headers.
    ///   - parameters: Query, JSON body, or form body parameters.
    ///   - encoding: Parameter encoding strategy. Defaults to `.query`.
    public init(path: String,
                method: BAHTTPMethod = .get,
                headers: [String: String] = [:],
                parameters: [String: Any] = [:],
                encoding: BAParameterEncoding = .query) {
        self.path = path
        self.method = method
        self.headers = headers
        self.parameters = parameters
        self.encoding = encoding
    }
}
