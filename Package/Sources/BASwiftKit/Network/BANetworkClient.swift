//
//  BANetworkClient.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/26.
//

import Foundation

/// Lightweight URLSession-based client for JSON API requests.
///
/// `BANetworkClient` centralizes URL construction, headers, parameter encoding, status-code
/// validation, optional `Decodable` response parsing, and request/response interceptors.
/// Completion handlers are delivered on `BANetworkConfiguration.callbackQueue`.
///
/// 如果项目已经大量使用 Alamofire，也可以在业务层继续保留 Alamofire；本封装保持零额外依赖，
/// 更适合作为基础库默认网络层，避免把第三方网络库强绑定到所有使用者。
public final class BANetworkClient {

    /// Mutable configuration used for subsequent requests.
    public var configuration: BANetworkConfiguration

    /// 请求/响应拦截器数组。按顺序执行，可在请求发送前修改请求，或在响应接收后修改响应。
    public var interceptors: [BAURLRequestInterceptor]

    /// Creates a client with the supplied configuration.
    ///
    /// - Parameters:
    ///   - configuration: Network defaults shared by all requests executed by this client.
    ///   - interceptors: Request/response interceptors. Defaults to empty.
    public init(configuration: BANetworkConfiguration = BANetworkConfiguration(),
                interceptors: [BAURLRequestInterceptor] = []) {
        self.configuration = configuration
        self.interceptors = interceptors
    }

    /// Executes a request and returns raw response data.
    ///
    /// 执行流程：构建 URLRequest → 应用请求拦截器 → 发送请求 → 状态码校验 → 应用响应拦截器 → 回调。
    ///
    /// - Parameters:
    ///   - request: Request description containing path, method, headers, parameters, and encoding.
    ///   - completion: Callback with raw `Data` on success or a request error on failure.
    public func request(_ request: BANetworkRequest,
                        completion: @escaping (Result<Data, Error>) -> Void) {
        do {
            let urlRequest = try makeURLRequest(request)
            applyRequestInterceptors(urlRequest) { [weak self] finalRequest in
                guard let self else { return }
                self.configuration.session.dataTask(with: finalRequest) { data, response, error in
                    if let error {
                        self.finish(.failure(error), completion: completion)
                        return
                    }
                    guard let http = response as? HTTPURLResponse, let data else {
                        self.finish(.failure(BANetworkError.invalidResponse), completion: completion)
                        return
                    }
                    guard 200..<300 ~= http.statusCode else {
                        self.finish(.failure(BANetworkError.statusCode(http.statusCode, data)), completion: completion)
                        return
                    }
                    self.applyResponseInterceptors(data, response: http, for: finalRequest) { finalData, _ in
                        self.finish(.success(finalData), completion: completion)
                    }
                }.resume()
            }
        } catch {
            finish(.failure(error), completion: completion)
        }
    }

    /// Executes an endpoint and returns raw response data.
    ///
    /// - Parameters:
    ///   - endpoint: Type-safe endpoint that can be converted into `BANetworkRequest`.
    ///   - completion: Callback with raw `Data` on success or a request error on failure.
    public func request(_ endpoint: BANetworkEndpoint,
                        completion: @escaping (Result<Data, Error>) -> Void) {
        request(endpoint.ba_request, completion: completion)
    }

    /// Executes a request and decodes the response body into a model.
    ///
    /// - Parameters:
    ///   - request: Request description containing path, method, headers, parameters, and encoding.
    ///   - responseType: Expected `Decodable` model type.
    ///   - completion: Callback with the decoded model or request/decoding error.
    public func request<T: Decodable>(_ request: BANetworkRequest,
                                      responseType: T.Type,
                                      completion: @escaping (Result<T, Error>) -> Void) {
        self.request(request) { [configuration] result in
            switch result {
            case .success(let data):
                do {
                    completion(.success(try configuration.decoder.decode(responseType, from: data)))
                } catch {
                    completion(.failure(error))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Executes an endpoint and decodes the response body into a model.
    ///
    /// - Parameters:
    ///   - endpoint: Type-safe endpoint that can be converted into `BANetworkRequest`.
    ///   - responseType: Expected `Decodable` model type.
    ///   - completion: Callback with the decoded model or request/decoding error.
    public func request<T: Decodable>(_ endpoint: BANetworkEndpoint,
                                      responseType: T.Type,
                                      completion: @escaping (Result<T, Error>) -> Void) {
        request(endpoint.ba_request, responseType: responseType, completion: completion)
    }

    /// Convenience GET request.
    ///
    /// - Parameters:
    ///   - path: Absolute URL string or relative endpoint path.
    ///   - parameters: Query parameters appended to the URL.
    ///   - headers: Request-specific headers.
    ///   - responseType: Expected `Decodable` model type.
    ///   - completion: Callback with the decoded model or error.
    public func get<T: Decodable>(_ path: String,
                                  parameters: [String: Any] = [:],
                                  headers: [String: String] = [:],
                                  responseType: T.Type,
                                  completion: @escaping (Result<T, Error>) -> Void) {
        request(BANetworkRequest(path: path, method: .get, headers: headers, parameters: parameters, encoding: .query),
                responseType: responseType,
                completion: completion)
    }

    /// Convenience JSON POST request.
    ///
    /// - Parameters:
    ///   - path: Absolute URL string or relative endpoint path.
    ///   - parameters: JSON body parameters.
    ///   - headers: Request-specific headers.
    ///   - responseType: Expected `Decodable` model type.
    ///   - completion: Callback with the decoded model or error.
    public func post<T: Decodable>(_ path: String,
                                   parameters: [String: Any] = [:],
                                   headers: [String: String] = [:],
                                   responseType: T.Type,
                                   completion: @escaping (Result<T, Error>) -> Void) {
        request(BANetworkRequest(path: path, method: .post, headers: headers, parameters: parameters, encoding: .json),
                responseType: responseType,
                completion: completion)
    }

    /// Builds a `URLRequest` from a request description.
    ///
    /// This method is public to make unit tests, request signing, and manual debugging easier.
    /// It does not apply interceptors; interceptors are only applied by `request` before sending.
    ///
    /// - Parameter request: Request description.
    /// - Returns: Configured URL request.
    /// - Throws: `BANetworkError.invalidURL` or `BANetworkError.invalidParameters`.
    public func makeURLRequest(_ request: BANetworkRequest) throws -> URLRequest {
        guard var components = URLComponents(url: resolvedURL(path: request.path), resolvingAgainstBaseURL: false) else {
            throw BANetworkError.invalidURL
        }

        if request.encoding == .query, !request.parameters.isEmpty {
            components.queryItems = request.parameters.map { key, value in
                URLQueryItem(name: key, value: String(describing: value))
            }
        }
        guard let url = components.url else { throw BANetworkError.invalidURL }

        var urlRequest = URLRequest(url: url, timeoutInterval: configuration.timeout)
        urlRequest.httpMethod = request.method.rawValue
        configuration.defaultHeaders.merging(request.headers) { _, new in new }.forEach { key, value in
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        switch request.encoding {
        case .query:
            break
        case .json:
            try encodeJSONBody(request.parameters, into: &urlRequest)
        case .formURLEncoded:
            encodeFormBody(request.parameters, into: &urlRequest)
        }
        return urlRequest
    }

    private func encodeJSONBody(_ parameters: [String: Any], into request: inout URLRequest) throws {
        guard !parameters.isEmpty else { return }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        guard JSONSerialization.isValidJSONObject(parameters) else { throw BANetworkError.invalidParameters }
        request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
    }

    private func encodeFormBody(_ parameters: [String: Any], into request: inout URLRequest) {
        guard !parameters.isEmpty else { return }
        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        let body = parameters.map { key, value in
            "\(key.ba_urlQueryEscaped)=\(String(describing: value).ba_urlQueryEscaped)"
        }.joined(separator: "&")
        request.httpBody = body.data(using: .utf8)
    }

    private func resolvedURL(path: String) -> URL {
        if let url = URL(string: path), url.scheme != nil {
            return url
        }
        if let baseURL = configuration.baseURL {
            return baseURL.appendingPathComponent(path)
        }
        return URL(string: path) ?? URL(fileURLWithPath: path)
    }

    private func finish<T>(_ result: Result<T, Error>, completion: @escaping (Result<T, Error>) -> Void) {
        configuration.callbackQueue.async { completion(result) }
    }

    private func applyRequestInterceptors(_ request: URLRequest, completion: @escaping (URLRequest) -> Void) {
        var current = request
        func apply(at index: Int) {
            guard index < interceptors.count else {
                completion(current)
                return
            }
            interceptors[index].intercept(current) { modified in
                current = modified
                apply(at: index + 1)
            }
        }
        apply(at: 0)
    }

    private func applyResponseInterceptors(_ data: Data, response: URLResponse, for request: URLRequest, completion: @escaping (Data, URLResponse) -> Void) {
        var currentData = data
        var currentResponse = response
        func apply(at index: Int) {
            guard index < interceptors.count else {
                completion(currentData, currentResponse)
                return
            }
            interceptors[index].intercept(currentData, response: currentResponse, for: request) { modifiedData, modifiedResponse in
                currentData = modifiedData
                currentResponse = modifiedResponse
                apply(at: index + 1)
            }
        }
        apply(at: 0)
    }
}

private extension String {
    var ba_urlQueryEscaped: String {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }
}
