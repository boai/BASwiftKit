//
//  Codable+BA.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/26.
//

import Foundation

/// Errors used by Codable conversion helpers when the input or output is not valid JSON.
public enum BACodableError: Error {
    /// The encoded value could not be represented as a top-level JSON dictionary.
    case invalidJSONObject
    /// The JSON string could not be converted to UTF-8 data.
    case invalidJSONString
}

/// Namespace for common Codable conversion helpers.
///
/// Use `BACodable` when you prefer static utility calls, or use the `ba_` extensions
/// on `Encodable`, `Decodable`, `Data`, and `String` for fluent conversions.
public enum BACodable {

    /// Decodes a model from a JSON string.
    ///
    /// - Parameters:
    ///   - type: Target model type.
    ///   - jsonString: UTF-8 JSON string, such as a response copied from an API.
    ///   - decoder: Decoder used to parse the model. Pass a configured decoder for dates or key strategies.
    /// - Returns: A decoded model instance.
    public static func model<T: Decodable>(_ type: T.Type,
                                           from jsonString: String,
                                           decoder: JSONDecoder = JSONDecoder()) throws -> T {
        try T.ba_decode(jsonString: jsonString, decoder: decoder)
    }

    /// Decodes a model from a JSON-compatible dictionary.
    ///
    /// - Parameters:
    ///   - type: Target model type.
    ///   - dictionary: Dictionary containing JSON-safe values.
    ///   - decoder: Decoder used to parse the model.
    /// - Returns: A decoded model instance.
    public static func model<T: Decodable>(_ type: T.Type,
                                           from dictionary: [String: Any],
                                           decoder: JSONDecoder = JSONDecoder()) throws -> T {
        try T.ba_decode(dictionary: dictionary, decoder: decoder)
    }

    /// Encodes a model into a JSON string.
    ///
    /// - Parameters:
    ///   - model: Encodable value to serialize.
    ///   - encoder: Encoder used to create JSON data. Configure it for date or key strategies as needed.
    /// - Returns: UTF-8 JSON string.
    public static func jsonString<T: Encodable>(from model: T,
                                                encoder: JSONEncoder = JSONEncoder()) throws -> String {
        try model.ba_jsonString(encoder: encoder)
    }

    /// Encodes a model into a top-level dictionary.
    ///
    /// - Parameters:
    ///   - model: Encodable value to serialize.
    ///   - encoder: Encoder used to create JSON data before dictionary conversion.
    /// - Returns: Dictionary containing JSON-safe values.
    public static func dictionary<T: Encodable>(from model: T,
                                                encoder: JSONEncoder = JSONEncoder()) throws -> [String: Any] {
        try model.ba_dictionary(encoder: encoder)
    }
}

public extension Encodable {

    /// Encodes the value into JSON data.
    ///
    /// - Parameter encoder: JSON encoder used for serialization.
    /// - Returns: Encoded JSON data.
    func ba_jsonData(encoder: JSONEncoder = JSONEncoder()) throws -> Data {
        try encoder.encode(self)
    }

    /// Encodes the value into a JSON string.
    ///
    /// - Parameters:
    ///   - encoder: JSON encoder used for serialization.
    ///   - encoding: String encoding used to build the result. Defaults to UTF-8.
    /// - Returns: JSON string. If the data cannot be represented with `encoding`, an empty string is returned.
    func ba_jsonString(encoder: JSONEncoder = JSONEncoder(), encoding: String.Encoding = .utf8) throws -> String {
        let data = try ba_jsonData(encoder: encoder)
        return String(data: data, encoding: encoding) ?? ""
    }

    /// Encodes the value into a top-level dictionary.
    ///
    /// - Parameter encoder: JSON encoder used for serialization.
    /// - Returns: Dictionary form of the model.
    /// - Throws: `BACodableError.invalidJSONObject` if the encoded JSON is not a dictionary.
    func ba_dictionary(encoder: JSONEncoder = JSONEncoder()) throws -> [String: Any] {
        let data = try ba_jsonData(encoder: encoder)
        let object = try JSONSerialization.jsonObject(with: data)
        guard let dictionary = object as? [String: Any] else { throw BACodableError.invalidJSONObject }
        return dictionary
    }
}

public extension Decodable {

    /// Decodes the current model type from JSON data.
    ///
    /// - Parameters:
    ///   - data: JSON data to parse.
    ///   - decoder: Decoder used to parse the model.
    /// - Returns: Decoded model instance.
    static func ba_decode(from data: Data, decoder: JSONDecoder = JSONDecoder()) throws -> Self {
        try decoder.decode(Self.self, from: data)
    }

    /// Decodes the current model type from a JSON string.
    ///
    /// - Parameters:
    ///   - jsonString: UTF-8 JSON string.
    ///   - decoder: Decoder used to parse the model.
    /// - Returns: Decoded model instance.
    static func ba_decode(jsonString: String, decoder: JSONDecoder = JSONDecoder()) throws -> Self {
        guard let data = jsonString.data(using: .utf8) else { throw BACodableError.invalidJSONString }
        return try ba_decode(from: data, decoder: decoder)
    }

    /// Decodes the current model type from a JSON-compatible dictionary.
    ///
    /// - Parameters:
    ///   - dictionary: Dictionary containing JSON-safe values.
    ///   - decoder: Decoder used to parse the model.
    /// - Returns: Decoded model instance.
    static func ba_decode(dictionary: [String: Any], decoder: JSONDecoder = JSONDecoder()) throws -> Self {
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        return try ba_decode(from: data, decoder: decoder)
    }
}

public extension Data {

    /// Decodes this data into the specified model type.
    ///
    /// - Parameters:
    ///   - type: Target model type.
    ///   - decoder: Decoder used to parse the model.
    /// - Returns: Decoded model instance.
    func ba_decode<T: Decodable>(_ type: T.Type, decoder: JSONDecoder = JSONDecoder()) throws -> T {
        try decoder.decode(type, from: self)
    }
}

public extension String {

    /// Decodes this JSON string into the specified model type.
    ///
    /// - Parameters:
    ///   - type: Target model type.
    ///   - decoder: Decoder used to parse the model.
    /// - Returns: Decoded model instance.
    func ba_decodeJSON<T: Decodable>(_ type: T.Type, decoder: JSONDecoder = JSONDecoder()) throws -> T {
        try T.ba_decode(jsonString: self, decoder: decoder)
    }
}
