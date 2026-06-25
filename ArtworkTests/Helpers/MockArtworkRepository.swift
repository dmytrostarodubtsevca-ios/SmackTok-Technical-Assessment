//
//  MockArtworkRepository.swift
//  ArtworkTests
//
//  Created by Dima Starodubtsev on 6/24/26.
//
//  In-memory `ArtworkRepositoryProtocol` for testing the view model without a
//  real repository or network. Tests drive its state directly and can inject
//  errors, delays, or per-call side effects. `@MainActor` to match the protocol.
//

import Foundation
@testable import Artwork

@MainActor
final class MockArtworkRepository: ArtworkRepositoryProtocol {

    var artworks: [ArtworkModel] = []
    var canLoadMore: Bool = true

    /// If set, `loadNextPage()` / `search(_:)` throw this instead of succeeding.
    var loadNextPageError: Error?
    var searchError: Error?

    /// Optional artificial delay (nanoseconds) so tests can interleave/cancel
    /// concurrent calls — used to verify rapid-search cancellation.
    var delay: UInt64 = 0

    /// Side effect run on a successful `loadNextPage()` — e.g. append a page so
    /// the view model observes growth.
    var onLoadNextPage: (@MainActor () -> Void)?
    /// Side effect run on a successful `search(_:)`.
    var onSearch: (@MainActor (String) -> Void)?

    private(set) var loadNextPageCallCount = 0
    private(set) var searchedQueries: [String] = []

    func loadNextPage() async throws {
        loadNextPageCallCount += 1
        if delay > 0 { try await Task.sleep(nanoseconds: delay) }
        if let loadNextPageError { throw loadNextPageError }
        onLoadNextPage?()
    }

    func search(_ query: String) async throws {
        searchedQueries.append(query)
        if delay > 0 { try await Task.sleep(nanoseconds: delay) }
        if let searchError { throw searchError }
        onSearch?(query)
    }
}
