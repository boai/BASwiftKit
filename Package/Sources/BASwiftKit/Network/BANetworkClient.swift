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

    deinit {
        // 自定义注入的 URLSession 若不 invalidate，其内部强引用的 delegate / operationQueue 会泄漏。
        // 仅处理非 .shared 的 session —— 绝不能 invalidate 全局共享 session（会影响整个 App 的网络）。
        // 用 finishTasksAndInvalidate 等在途任务正常结束后再释放，避免打断已发出的请求。
        let session = configuration.session
        if session !== URLSession.shared {
            session.finishTasksAndInvalidate()
        }
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
                    guard let http = response as? HTTPURLResponse else {
                        self.finish(.failure(BANetworkError.invalidResponse), completion: completion)
                        return
                    }
                    // 204/304 等合法响应可能没有 body，data 为 nil 时用空 Data 兜底，
                    // 不能因 data==nil 直接判失败，否则空响应会被误判为 invalidResponse。
                    let data = data ?? Data()
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
            // 用 flatMap 展开：数组值（如 [1,2,3]）需编码成 ids=1&ids=2&ids=3，
            // 而不是 String(describing:) 得到的单个 "[1, 2, 3]"。
            components.queryItems = request.parameters.flatMap { key, value -> [URLQueryItem] in
                Self.queryItems(name: key, value: value)
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

    /// 把单个参数键值对展开为一个或多个 `URLQueryItem`。
    ///
    /// - 数组值（`[Any]`）展开为多个同名 item，符合 `key=v1&key=v2` 约定；
    ///   嵌套数组会进一步递归展开。
    /// - 其余标量用 `ba_stringValue` 统一转字符串（`Bool` 转 "true"/"false"）。
    private static func queryItems(name: String, value: Any) -> [URLQueryItem] {
        if let array = value as? [Any] {
            return array.flatMap { queryItems(name: name, value: $0) }
        }
        return [URLQueryItem(name: name, value: ba_stringValue(value))]
    }

    /// 把标量参数值转换为字符串。
    ///
    /// `Bool` 经 `String(describing:)` 在多数语境下虽是 "true"/"false"，但 NSNumber 包装的布尔值
    /// 可能输出 "1"/"0"，故显式分支保证统一为 "true"/"false"；其余类型沿用 `String(describing:)`。
    private static func ba_stringValue(_ value: Any) -> String {
        if let bool = value as? Bool {
            return bool ? "true" : "false"
        }
        return String(describing: value)
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
        // key 与 value 都用严格转义；value 经 ba_stringValue 统一处理（Bool→"true"/"false"）。
        let body = parameters.map { key, value in
            "\(key.ba_formEscaped)=\(Self.ba_stringValue(value).ba_formEscaped)"
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
        // interceptors 是 public var，可能在异步遍历期间被外部修改；
        // 先取局部快照再按 index 遍历，避免并发改动导致越界或读到不一致状态。
        let snapshot = interceptors
        var current = request
        func apply(at index: Int) {
            guard index < snapshot.count else {
                completion(current)
                return
            }
            snapshot[index].intercept(current) { modified in
                current = modified
                apply(at: index + 1)
            }
        }
        apply(at: 0)
    }

    private func applyResponseInterceptors(_ data: Data, response: URLResponse, for request: URLRequest, completion: @escaping (Data, URLResponse) -> Void) {
        // 同 applyRequestInterceptors：先快照再遍历，规避并发修改 interceptors 的竞争。
        let snapshot = interceptors
        var currentData = data
        var currentResponse = response
        func apply(at index: Int) {
            guard index < snapshot.count else {
                completion(currentData, currentResponse)
                return
            }
            snapshot[index].intercept(currentData, response: currentResponse, for: request) { modifiedData, modifiedResponse in
                currentData = modifiedData
                currentResponse = modifiedResponse
                apply(at: index + 1)
            }
        }
        apply(at: 0)
    }
}

/// 表单 body 百分号编码使用的允许字符集（性能优化：仅计算一次后复用）。
///
/// 在 `urlQueryAllowed` 基础上移除 `+ & = ? /` 等危险字符。原实现每次编码都重新拷贝
/// `urlQueryAllowed` 并 remove，构造 `CharacterSet` 有一定开销；提为文件级常量后多次编码复用同一实例，行为不变。
private let baFormAllowedCharacterSet: CharacterSet = {
    var allowed = CharacterSet.urlQueryAllowed
    allowed.remove(charactersIn: "+&=?/ ")
    return allowed
}()

private extension String {
    /// 表单 body 专用的严格百分号编码。
    ///
    /// 不能直接用 `.urlQueryAllowed`：它把 `+ & = ? /` 等子分隔符视为合法、不转义，
    /// 而在 `application/x-www-form-urlencoded` body 里这些字符会破坏键值结构
    /// （例如 `+` 会被服务端解析成空格）。这里在 query 集合基础上移除这些危险字符，
    /// 确保 `+`→`%2B`、`&`→`%26`、`=`→`%3D` 等被正确转义。
    var ba_formEscaped: String {
        // 优化：复用预计算的字符集常量，避免每次重新构造。
        addingPercentEncoding(withAllowedCharacters: baFormAllowedCharacterSet) ?? self
    }
}
