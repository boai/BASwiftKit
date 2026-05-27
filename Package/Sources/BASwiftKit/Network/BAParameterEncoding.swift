//
//  BAParameterEncoding.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

import Foundation

/// Controls where request parameters are placed when building a `URLRequest`.
public enum BAParameterEncoding {
    /// Encodes parameters into the URL query string, such as `?page=1&size=20`.
    case query
    /// Encodes parameters as a JSON request body and sets `Content-Type` to `application/json`.
    case json
    /// Sends parameters as `application/x-www-form-urlencoded` body data.
    case formURLEncoded
}
