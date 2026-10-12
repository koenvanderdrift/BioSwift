//
//  HTTPTransport.swift
//  BioSwiftNetworking
//

import Foundation

/// Executes HTTP requests for remote biological-data services.
///
/// Transports return every valid HTTP response, including non-success status codes.
/// A provider client can interpret those codes itself or call `validated()` on the response.
public protocol HTTPTransport: Sendable {
    func data(for request: URLRequest) async throws -> HTTPResponse
}

/// The provider-independent result of an HTTP request.
public struct HTTPResponse: Equatable, Sendable {
    public let data: Data
    public let statusCode: Int
    public let url: URL?

    private let normalizedHeaders: [String: String]

    public init(
        data: Data,
        statusCode: Int,
        url: URL? = nil,
        headers: [String: String] = [:]
    ) {
        self.data = data
        self.statusCode = statusCode
        self.url = url
        normalizedHeaders = Dictionary(
            headers.map { ($0.key.lowercased(), $0.value) },
            uniquingKeysWith: { _, latest in latest }
        )
    }

    /// Returns an HTTP header value using a case-insensitive field name.
    public func value(forHeaderField field: String) -> String? {
        normalizedHeaders[field.lowercased()]
    }

    /// Returns this response when its status is successful, otherwise throws with its body.
    @discardableResult
    public func validated() throws -> HTTPResponse {
        guard (200...299).contains(statusCode) else {
            throw NetworkingError.unsuccessfulStatus(
                code: statusCode,
                responseBody: data
            )
        }
        return self
    }
}

/// Errors produced by the shared networking layer.
public enum NetworkingError: Error, Equatable, Sendable {
    /// The transport received a response that was not HTTP.
    case invalidResponse

    /// Explicit response validation encountered a non-success status.
    case unsuccessfulStatus(code: Int, responseBody: Data)
}

/// An HTTP transport backed by an injected URL session.
public struct URLSessionTransport: HTTPTransport {
    private let session: URLSession

    /// Creates a transport. The caller owns connectivity, caching, and access policy
    /// through the supplied session configuration.
    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func data(for request: URLRequest) async throws -> HTTPResponse {
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw NetworkingError.invalidResponse
        }

        let headers = response.allHeaderFields.reduce(into: [String: String]()) { result, field in
            result[String(describing: field.key)] = String(describing: field.value)
        }

        return HTTPResponse(
            data: data,
            statusCode: response.statusCode,
            url: response.url,
            headers: headers
        )
    }
}
