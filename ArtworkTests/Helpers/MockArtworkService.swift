//
//  MockArtworkService.swift
//  ArtworkTests
//
//  Created by Dima Starodubtsev on 6/24/26.
//
//  In-memory `ArtworkServiceProtocol` for testing the repository without a
//  network. Recording state is guarded by a lock so it stays safe even when the
//  repository fires concurrent requests (e.g. rapid search), while keeping the
//  type a plain value-like `Sendable` class — no actor-hop thunks.
//

import Foundation
@testable import Artwork

final class MockArtworkService: ArtworkServiceProtocol, @unchecked Sendable {

    /// Results returned for successive `fetchArtworks` calls, in order. When the
    /// list is exhausted the last entry is reused, so a single-element array
    /// means "always return this".
    private let fetchResults: [Result<ArtworkPageModel, Error>]
    private let searchResults: [Result<ArtworkPageModel, Error>]
    private let detailResult: Result<ArtworkDetailModel, Error>?

    private let lock = NSLock()
    private var fetchIndex = 0
    private var searchIndex = 0
    private var _fetchCalls: [Int] = []
    private var _searchCalls: [(query: String, page: Int)] = []
    private var _detailCalls: [Int] = []

    var fetchCalls: [Int] { lock.withLock { _fetchCalls } }
    var searchCalls: [(query: String, page: Int)] { lock.withLock { _searchCalls } }
    var detailCalls: [Int] { lock.withLock { _detailCalls } }

    init(
        fetchResults: [Result<ArtworkPageModel, Error>] = [],
        searchResults: [Result<ArtworkPageModel, Error>] = [],
        detailResult: Result<ArtworkDetailModel, Error>? = nil
    ) {
        self.fetchResults = fetchResults
        self.searchResults = searchResults
        self.detailResult = detailResult
    }

    /// Convenience: a service that always returns `page` for both endpoints.
    static func returning(_ page: ArtworkPageModel) -> MockArtworkService {
        MockArtworkService(fetchResults: [.success(page)], searchResults: [.success(page)])
    }

    /// Convenience: a service that always throws `error`.
    static func failing(_ error: Error) -> MockArtworkService {
        MockArtworkService(fetchResults: [.failure(error)], searchResults: [.failure(error)])
    }

    func fetchArtworks(page: Int) async throws -> ArtworkPageModel {
        try lock.withLock {
            _fetchCalls.append(page)
            return try value(from: fetchResults, index: &fetchIndex)
        }
    }

    func searchArtworks(query: String, page: Int) async throws -> ArtworkPageModel {
        try lock.withLock {
            _searchCalls.append((query, page))
            return try value(from: searchResults, index: &searchIndex)
        }
    }

    func fetchArtwork(id: Int) async throws -> ArtworkDetailModel {
        try lock.withLock {
            _detailCalls.append(id)
            guard let detailResult else {
                throw APIError.invalidResponse
            }
            return try detailResult.get()
        }
    }

    private func value(
        from results: [Result<ArtworkPageModel, Error>],
        index: inout Int
    ) throws -> ArtworkPageModel {
        guard !results.isEmpty else { return ArtworkPageModel(items: [], currentPage: 1, totalPages: 1) }
        let result = results[min(index, results.count - 1)]
        index += 1
        return try result.get()
    }
}
