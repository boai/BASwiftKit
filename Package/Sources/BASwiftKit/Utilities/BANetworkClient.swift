//
//  BANetworkClient.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/26.
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

/// Controls where request parameters are placed when building a `URLRequest`.
public enum BAParameterEncoding {
    /// Encodes parameters into the URL query string, such as `?page=1&size=20`.
    case query
    /// Encodes parameters as a JSON request body and sets `Content-Type` to `application/json`.
    case json
}

/// Shared configuration used by `BANetworkClient` when creating and decoding requests.
///
/// Use this type to define app-wide network defaults such as the API host, timeout,
/// default headers, custom encoder/decoder strategies, or an injected `URLSession`.
public struct BANetworkConfiguration {
    /// Base URL used for relative request paths. Absolute request paths ignore this value.
    public var baseURL: URL?
    /// Per-request timeout interval in seconds.
    public var timeout: TimeInterval
    /// Headers applied to every request before request-specific headers are merged.
    public var defaultHeaders: [String: String]
    /// Decoder used by typed `request(_:responseType:completion:)` calls.
    public var decoder: JSONDecoder
    /// Encoder reserved for callers that want matching encode/decode configuration.
    public var encoder: JSONEncoder
    /// URL session that performs requests. Inject a custom session for caching, proxies, or tests.
    public var session: URLSession

    /// Creates a reusable network configuration.
    ///
    /// - Parameters:
    ///   - baseURL: Optional API host for relative request paths, for example `https://api.example.com`.
    ///   - timeout: Timeout interval applied to each generated `URLRequest`.
    ///   - defaultHeaders: Headers included on every request unless overridden by request headers.
    ///   - decoder: JSON decoder used for `Decodable` response models.
    ///   - encoder: JSON encoder kept with the configuration for matching request/response strategies.
    ///   - session: URL session used to execute requests. Defaults to `.shared`.
    public init(baseURL: URL? = nil,
                timeout: TimeInterval = 30,
                defaultHeaders: [String: String] = [:],
                decoder: JSONDecoder = JSONDecoder(),
                encoder: JSONEncoder = JSONEncoder(),
                session: URLSession = .shared) {
        self.baseURL = baseURL
        self.timeout = timeout
        self.defaultHeaders = defaultHeaders
        self.decoder = decoder
        self.encoder = encoder
        self.session = session
    }
}

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
    ///   - parameters: Query or JSON body parameters.
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

/// 网络请求拦截器协议，用于在请求发送前或响应接收后插入自定义逻辑。
///
/// 典型用途包括：缓存读取/写入、请求签名、日志记录、重试逻辑等。
/// 拦截器按数组顺序依次执行。
///
/// ```swift
/// struct CacheInterceptor: BAURLRequestInterceptor {
///     func intercept(_ request: URLRequest, completion: @escaping (URLRequest) -> Void) {
///         var req = request
///         req.setValue("my-token", forHTTPHeaderField: "X-Token")
///         completion(req)
///     }
///
///     func intercept(_ data: Data, response: URLResponse, for request: URLRequest, completion: @escaping (Data, URLResponse) -> Void) {
///         completion(data, response)
///     }
/// }
/// ```
public protocol BAURLRequestInterceptor {
    /// 拦截并修改即将发送的请求。必须调用 `completion` 继续。
    func intercept(_ request: URLRequest, completion: @escaping (URLRequest) -> Void)
    /// 拦截并修改已接收的响应和数据。必须调用 `completion` 继续。
    func intercept(_ data: Data, response: URLResponse, for request: URLRequest, completion: @escaping (Data, URLResponse) -> Void)
}

/// 提供默认空实现的拦截器扩展，方便只重写其中一侧。
public extension BAURLRequestInterceptor {
    func intercept(_ request: URLRequest, completion: @escaping (URLRequest) -> Void) {
        completion(request)
    }
    func intercept(_ data: Data, response: URLResponse, for request: URLRequest, completion: @escaping (Data, URLResponse) -> Void) {
        completion(data, response)
    }
}

/// Errors produced by `BANetworkClient` before a response is decoded.
public enum BANetworkError: Error {
    /// The final URL could not be constructed from `path` and `baseURL`.
    case invalidURL
    /// The server response was not an `HTTPURLResponse` or did not contain data.
    case invalidResponse
    /// The server returned a non-2xx status code. The associated data is the raw response body.
    case statusCode(Int, Data)
}

/// Lightweight URLSession-based client for JSON API requests.
///
/// `BANetworkClient` centralizes URL construction, headers, parameter encoding, status-code
/// validation, and optional `Decodable` response parsing. Completion handlers are delivered
/// on the main queue so UI callers can update views directly.
///
/// 支持通过 `interceptors` 插入请求/响应拦截器，实现缓存、签名、日志等横切逻辑。
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
    /// 执行流程：构建 URLRequest → 应用请求拦截器 → 发送请求 → 应用响应拦截器 → 状态码校验 → 回调。
    ///
    /// - Parameters:
    ///   - request: Request description containing path, method, headers, parameters, and encoding.
    ///   - completion: Main-thread callback with raw `Data` on success or a request error on failure.
    public func request(_ request: BANetworkRequest,
                        completion: @escaping (Result<Data, Error>) -> Void) {
        do {
            let urlRequest = try makeURLRequest(request)
            applyRequestInterceptors(urlRequest) { [weak self] finalRequest in
                guard let self = self else { return }
                self.configuration.session.dataTask(with: finalRequest) { data, response, error in
                    if let error {
                        DispatchQueue.main.async { completion(.failure(error)) }
                        return
                    }
                    guard let http = response as? HTTPURLResponse, let data = data else {
                        DispatchQueue.main.async { completion(.failure(BANetworkError.invalidResponse)) }
                        return
                    }
                    guard 200..<300 ~= http.statusCode else {
                        DispatchQueue.main.async { completion(.failure(BANetworkError.statusCode(http.statusCode, data))) }
                        return
                    }
                    self.applyResponseInterceptors(data, response: http, for: finalRequest) { finalData, _ in
                        DispatchQueue.main.async { completion(.success(finalData)) }
                    }
                }.resume()
            }
        } catch {
            DispatchQueue.main.async { completion(.failure(error)) }
        }
    }

    /// Executes a request and decodes the response body into a model.
    ///
    /// - Parameters:
    ///   - request: Request description containing path, method, headers, parameters, and encoding.
    ///   - responseType: Expected `Decodable` model type.
    ///   - completion: Main-thread callback with the decoded model or request/decoding error.
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

    private func makeURLRequest(_ request: BANetworkRequest) throws -> URLRequest {
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

        if request.encoding == .json, !request.parameters.isEmpty {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: request.parameters)
        }
        return urlRequest
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

    // MARK: - Interceptors

    /// 顺序应用请求拦截器。
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

    /// 顺序应用响应拦截器。
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
