//
//  URLProtocolStub.swift
//  ArtworkTests
//
//  Created by Dima Starodubtsev on 6/24/26.
//
//  A `URLProtocol` subclass that intercepts requests made through a configured
//  `URLSession` and replies with canned data / response / error. Lets the real
//  `ArtworkService` (and its URL building + decoding) be tested end-to-end with
//  zero network access.
//

import Foundation

final class URLProtocolStub: URLProtocol {

    struct Stub {
        var data: Data?
        var response: URLResponse?
        var error: Error?
    }

    // Stub storage is process-global (URLProtocol is instantiated by the system),
    // so guard it with a lock for safe access across the loader's queue.
    private static let lock = NSLock()
    nonisolated(unsafe) private static var stub: Stub?
    /// Records every URL the session attempted — lets tests assert on query items.
    nonisolated(unsafe) private(set) static var requestedURLs: [URL] = []

    /// Builds a `URLSession` whose every request is served by this stub.
    static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: config)
    }

    /// Stub a successful HTTP response with the given status code and body.
    static func stub(data: Data, statusCode: Int = 200, url: URL = anyURL) {
        let response = HTTPURLResponse(
            url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil
        )
        set(Stub(data: data, response: response, error: nil))
    }

    /// Stub a transport-level failure (no response).
    static func stub(error: Error) {
        set(Stub(data: nil, response: nil, error: error))
    }

    /// Stub a non-HTTP response, to exercise the `invalidResponse` path.
    static func stubNonHTTPResponse(data: Data = Data()) {
        let response = URLResponse(
            url: anyURL, mimeType: nil, expectedContentLength: 0, textEncodingName: nil
        )
        set(Stub(data: data, response: response, error: nil))
    }

    static func reset() {
        lock.withLock {
            stub = nil
            requestedURLs = []
        }
    }

    private static func set(_ newStub: Stub) {
        lock.withLock { stub = newStub }
    }

    static let anyURL = URL(string: "https://api.artic.edu/api/v1/artworks")!

    // MARK: - URLProtocol

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        if let url = request.url {
            Self.lock.withLock { Self.requestedURLs.append(url) }
        }
        let stub = Self.lock.withLock { Self.stub }

        if let error = stub?.error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        if let response = stub?.response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        if let data = stub?.data {
            client?.urlProtocol(self, didLoad: data)
        }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
