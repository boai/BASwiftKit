//
//  BAHTTPMethod.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

import Foundation

/// HTTP request methods supported by `BANetworkClient`.
///
/// The raw value is written directly to `URLRequest.httpMethod`, so these cases cover
/// the common REST verbs used by most JSON APIs.
public enum BAHTTPMethod: String {
    /// Reads data from the server. Parameters are usually encoded as URL query items.
    case get = "GET"
    /// Creates data on the server. Parameters are commonly encoded as JSON body data.
    case post = "POST"
    /// Replaces an existing server resource.
    case put = "PUT"
    /// Partially updates an existing server resource.
    case patch = "PATCH"
    /// Deletes a server resource.
    case delete = "DELETE"
}
