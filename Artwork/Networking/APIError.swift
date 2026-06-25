//
//  APIError.swift
//  Artwork
//
//  Created by Dima Starodubtsev on 6/24/26.
//

import Foundation

/// Typed failures surfaced by the networking layer.
///
/// Mapping low-level `URLSession`/decoding failures onto a small, explicit set
/// lets callers (and tests) reason about *why* a request failed and lets the UI
/// show a meaningful message instead of a raw system error.
enum APIError: Error, Equatable {
    /// A non-2xx HTTP response; carries the status code.
    case badStatus(Int)
    /// The response body could not be decoded into the expected shape.
    case decoding
    /// The request never completed (offline, timeout, cancelled, …).
    case transport
    /// The response was not an `HTTPURLResponse`.
    case invalidResponse
}

extension APIError {
    /// A user-facing description suitable for an error state.
    var message: String {
        switch self {
        case .badStatus(let code): return "The server responded with an error (\(code))."
        case .decoding:            return "We couldn't read the data from the server."
        case .transport:           return "Couldn't reach the server. Check your connection."
        case .invalidResponse:     return "The server returned an unexpected response."
        }
    }
}
