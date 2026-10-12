import Foundation
import Testing
@testable import BioSwiftNetworking

@Suite("HTTP transport", .serialized)
struct HTTPTransportTests {
    @Test("Responses provide case-insensitive header access")
    func headerAccess() {
        let response = HTTPResponse(
            data: Data(),
            statusCode: 200,
            headers: ["Content-Type": "application/json", "LINK": "<next>"]
        )

        #expect(response.value(forHeaderField: "content-type") == "application/json")
        #expect(response.value(forHeaderField: "Content-Type") == "application/json")
        #expect(response.value(forHeaderField: "link") == "<next>")
        #expect(response.value(forHeaderField: "missing") == nil)
    }

    @Test("Validation preserves successful responses")
    func successfulValidation() throws {
        let response = HTTPResponse(data: Data("ok".utf8), statusCode: 206)

        #expect(try response.validated() == response)
    }

    @Test("Validation reports status and response body")
    func unsuccessfulValidation() {
        let body = Data("rate limited".utf8)
        let response = HTTPResponse(data: body, statusCode: 429)

        #expect(throws: NetworkingError.unsuccessfulStatus(code: 429, responseBody: body)) {
            try response.validated()
        }
    }

    @Test("URLSession transport forwards requests and maps responses")
    func sessionTransport() async throws {
        let expectedBody = Data("response".utf8)
        StubURLProtocol.handler = { request in
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
            #expect(try requestBody(from: request) == Data("request".utf8))

            guard let requestURL = request.url,
                let response = HTTPURLResponse(
                url: requestURL,
                statusCode: 202,
                httpVersion: "HTTP/1.1",
                headerFields: ["X-Request-ID": "abc123"]
                )
            else {
                throw TestSetupError.invalidResponse
            }
            return (response, expectedBody)
        }
        defer { StubURLProtocol.handler = nil }

        var request = URLRequest(url: try #require(URL(string: "https://example.test/search")))
        request.httpMethod = "POST"
        request.httpBody = Data("request".utf8)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let response = try await URLSessionTransport(session: makeSession()).data(for: request)

        #expect(response.data == expectedBody)
        #expect(response.statusCode == 202)
        #expect(response.url == request.url)
        #expect(response.value(forHeaderField: "x-request-id") == "abc123")
    }

    @Test("URLSession transport propagates loading errors")
    func transportError() async throws {
        StubURLProtocol.handler = { _ in
            throw URLError(.notConnectedToInternet)
        }
        defer { StubURLProtocol.handler = nil }

        let request = URLRequest(url: try #require(URL(string: "https://example.test")))

        await #expect(throws: URLError.self) {
            try await URLSessionTransport(session: makeSession()).data(for: request)
        }
    }

    @Test("Transport and response values are Sendable")
    func sendable() {
        requireSendable(URLSessionTransport(session: makeSession()))
        requireSendable(HTTPResponse(data: Data(), statusCode: 200))
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    private func requireSendable<Value: Sendable>(_: Value) {}
}

private enum TestSetupError: Error {
    case bodyStreamFailed
    case invalidResponse
}

private func requestBody(from request: URLRequest) throws -> Data? {
    if let body = request.httpBody {
        return body
    }
    guard let stream = request.httpBodyStream else {
        return nil
    }

    stream.open()
    defer { stream.close() }

    var body = Data()
    var buffer = [UInt8](repeating: 0, count: 1_024)
    while true {
        let bytesRead = stream.read(&buffer, maxLength: buffer.count)
        if bytesRead < 0 {
            throw stream.streamError ?? TestSetupError.bodyStreamFailed
        }
        if bytesRead == 0 {
            return body
        }
        body.append(contentsOf: buffer.prefix(bytesRead))
    }
}

private final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var handler: (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
