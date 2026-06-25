//
//  MockArtworkService.swift
//  ArtworkTests
//
//  Created by Dima Starodubtsev on 6/24/26.
//
//  In-memory `ArtworkServiceProtocol` for testing the repository without a
//  network. Implemented as an `actor` so its call-recording state stays safe
//  even when the repository fires concurrent requests (e.g. rapid search).
//

import Foundation
@testable import Artwork

actor MockArtworkService: ArtworkServiceProtocol {

    /// Results returned for successive `fetchArtworks` calls, in order. When the
    /// list is exhausted the last entry is reused, so a single-element array
    /// means "always return this".
    private let fetchResults: [Result<ArtworkPageModel, Error>]
    private let searchResults: [Result<ArtworkPageModel, Error>]

    private var fetchIndex = 0
    private var searchIndex = 0

    private(set) var fetchCalls: [Int] = []
    private(set) var searchCalls: [(query: String, page: Int)] = []

    init(
        fetchResults: [Result<ArtworkPageModel, Error>] = [],
        searchResults: [Result<ArtworkPageModel, Error>] = []
    ) {
        self.fetchResults = fetchResults
        self.searchResults = searchResults
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
        fetchCalls.append(page)
        return try value(from: fetchResults, index: &fetchIndex)
    }

    func searchArtworks(query: String, page: Int) async throws -> ArtworkPageModel {
        searchCalls.append((query, page))
        return try value(from: searchResults, index: &searchIndex)
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
