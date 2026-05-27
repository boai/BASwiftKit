//
//  BANetworkConfiguration.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

import Foundation

/// Shared configuration used by `BANetworkClient` when creating and decoding requests.
///
/// Use this type to define app-wide network defaults such as the API host, timeout,
/// default headers, custom encoder/decoder strategies, callback queue, or an injected `URLSession`.
public struct BANetworkConfiguration {
    /// Base URL used for relative request paths. Absolute request paths ignore this value.
    public var baseURL: URL?
    /// Per-request timeout interval in seconds.
    public var timeout: TimeInterval
    /// Headers applied to every request before request-specific headers are merged.
    public var defaultHeaders: [String: String]
    /// Decoder used by typed response calls.
    public var decoder: JSONDecoder
    /// Encoder kept with the configuration for matching request/response strategies.
    public var encoder: JSONEncoder
    /// URL session that performs requests. Inject a custom session for caching, proxies, or tests.
    public var session: URLSession
    /// Queue used to deliver completion callbacks. Defaults to `.main` for UI-friendly usage.
    public var callbackQueue: DispatchQueue

    /// Creates a reusable network configuration.
    ///
    /// - Parameters:
    ///   - baseURL: Optional API host for relative request paths, for example `https://api.example.com`.
    ///   - timeout: Timeout interval applied to each generated `URLRequest`.
    ///   - defaultHeaders: Headers included on every request unless overridden by request headers.
    ///   - decoder: JSON decoder used for `Decodable` response models.
    ///   - encoder: JSON encoder kept with the configuration for matching request/response strategies.
    ///   - session: URL session used to execute requests. Defaults to `.shared`.
    ///   - callbackQueue: Queue used for callbacks. Defaults to `.main`.
    public init(baseURL: URL? = nil,
                timeout: TimeInterval = 30,
                defaultHeaders: [String: String] = [:],
                decoder: JSONDecoder = JSONDecoder(),
                encoder: JSONEncoder = JSONEncoder(),
                session: URLSession = .shared,
                callbackQueue: DispatchQueue = .main) {
        self.baseURL = baseURL
        self.timeout = timeout
        self.defaultHeaders = defaultHeaders
        self.decoder = decoder
        self.encoder = encoder
        self.session = session
        self.callbackQueue = callbackQueue
    }
}
