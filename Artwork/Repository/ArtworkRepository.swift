//
//  ArtworkRepository.swift
//  Artwork
//
//  Created by Dima Starodubtsev on 6/24/26.
//

import Foundation

/// Default `ArtworkRepositoryProtocol` implementation.
///
/// Owns all pagination state and accumulates results across pages. Delegates
/// the actual fetching to an injected `ArtworkServiceProtocol`, so it can be
/// unit-tested against a mock service with no network. Main-actor isolated:
/// every state mutation is serialized, so concurrent `loadNextPage()` calls
/// from fast scrolling can't race.
@MainActor
final class ArtworkRepository: ArtworkRepositoryProtocol {

    /// Where the current results come from — browse listing or a search query.
    private enum Mode: Equatable {
        case browsing
        case searching(String)
    }

    private(set) var artworks: [ArtworkModel] = []

    /// More pages remain while we haven't reached the last known page. Starts
    /// `true` (0 < 1) so the very first `loadNextPage()` is allowed.
    var canLoadMore: Bool { currentPage < totalPages }

    private let service: ArtworkServiceProtocol
    private var mode: Mode = .browsing
    private var currentPage = 0
    private var totalPages = 1
    private var isLoading = false
    /// Tracks IDs already shown so pages that re-list an artwork (the API's
    /// collection shifts as you paginate) don't introduce duplicate IDs, which
    /// would break `ForEach`.
    private var seenIDs: Set<Int> = []

    init(service: ArtworkServiceProtocol) {
        self.service = service
    }

    func loadNextPage() async throws {
        // Absorb duplicate triggers (e.g. repeated `.onAppear`) and stop at the
        // last page. The guard runs synchronously on the main actor before any
        // suspension, so two near-simultaneous calls can't both pass it.
        guard !isLoading, canLoadMore else { return }
        isLoading = true
        defer { isLoading = false }

        let nextPage = currentPage + 1
        let page = try await fetch(page: nextPage)

        // Append rather than replace — pagination accumulates results — while
        // dropping any artwork already shown on an earlier page.
        let newItems = page.items.filter { seenIDs.insert($0.id).inserted }
        artworks += newItems
        currentPage = page.currentPage
        totalPages = page.totalPages
    }

    func search(_ query: String) async throws {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        mode = trimmed.isEmpty ? .browsing : .searching(trimmed)

        // A new query is a fresh result set: reset pagination and clear the list
        // before loading page 1 of the new mode.
        reset()
        try await loadNextPage()
    }

    // MARK: - Private

    private func fetch(page: Int) async throws -> ArtworkPageModel {
        switch mode {
        case .browsing:
            return try await service.fetchArtworks(page: page)
        case .searching(let query):
            return try await service.searchArtworks(query: query, page: page)
        }
    }

    private func reset() {
        artworks = []
        seenIDs = []
        currentPage = 0
        totalPages = 1
    }
}
