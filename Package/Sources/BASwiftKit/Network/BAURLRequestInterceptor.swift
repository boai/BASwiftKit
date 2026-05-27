//
//  BAURLRequestInterceptor.swift
//  BASwiftKit
//
//  Created by boai on 2026/05/27.
//

import Foundation

/// 网络请求拦截器协议，用于在请求发送前或响应接收后插入自定义逻辑。
///
/// 典型用途包括：缓存读取/写入、请求签名、日志记录、重试逻辑等。
/// 拦截器按数组顺序依次执行。
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
