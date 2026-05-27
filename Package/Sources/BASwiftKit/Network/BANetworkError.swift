//
//  BANetworkError.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

import Foundation

/// Errors produced by the network module before or during response decoding.
public enum BANetworkError: Error {
    /// The final URL could not be constructed from `path` and `baseURL`.
    case invalidURL
    /// The request parameters could not be represented as valid JSON or form data.
    case invalidParameters
    /// The server response was not an `HTTPURLResponse` or did not contain data.
    case invalidResponse
    /// The server returned a non-2xx status code. The associated data is the raw response body.
    case statusCode(Int, Data)
}
