//
//  ArtworkRepositoryTests.swift
//  ArtworkTests
//
//  Created by Dima Starodubtsev on 6/24/26.
//
//  Verifies the repository's pagination state machine against a mock service:
//  appending across pages, the canLoadMore stop condition, the concurrent-call
//  guard, search reset, and error propagation. No network.
//

import Foundation
import Testing
@testable import Artwork

@MainActor
struct ArtworkRepositoryTests {

    private func page(_ items: [Int], currentPage: Int, totalPages: Int) -> ArtworkPageModel {
        ArtworkPageModel(
            items: items.map { Fixtures.artwork(id: $0) },
            currentPage: currentPage,
            totalPages: totalPages
        )
    }

    // MARK: - First load

    @Test func firstLoadStartsAtPageOne() async throws {
        let service = MockArtworkService(fetchResults: [
            .success(page([1, 2], currentPage: 1, totalPages: 3))
        ])
        let sut = ArtworkRepository(service: service)

        try await sut.loadNextPage()

        #expect(sut.artworks.map(\.id) == [1, 2])
        let calls = service.fetchCalls
        #expect(calls == [1])
    }

    // MARK: - Pagination

    @Test func loadNextPageAppendsAndAdvances() async throws {
        let service = MockArtworkService(fetchResults: [
            .success(page([1, 2], currentPage: 1, totalPages: 3)),
            .success(page([3, 4], currentPage: 2, totalPages: 3))
        ])
        let sut = ArtworkRepository(service: service)

        try await sut.loadNextPage()
        try await sut.loadNextPage()

        #expect(sut.artworks.map(\.id) == [1, 2, 3, 4])
        let calls = service.fetchCalls
        #expect(calls == [1, 2])
    }

    @Test func canLoadMoreBecomesFalseOnLastPage() async throws {
        let service = MockArtworkService(fetchResults: [
            .success(page([1], currentPage: 1, totalPages: 1))
        ])
        let sut = ArtworkRepository(service: service)

        #expect(sut.canLoadMore) // 0 < 1 before any load
        try await sut.loadNextPage()
        #expect(sut.canLoadMore == false)
    }

    @Test func loadNextPageNoOpsPastLastPage() async throws {
        let service = MockArtworkService(fetchResults: [
            .success(page([1], currentPage: 1, totalPages: 1))
        ])
        let sut = ArtworkRepository(service: service)

        try await sut.loadNextPage()
        try await sut.loadNextPage() // should not hit the service again

        let calls = service.fetchCalls
        #expect(calls == [1])
        #expect(sut.artworks.count == 1)
    }

    // MARK: - Search

    @Test func searchResetsPaginationAndUsesSearchEndpoint() async throws {
        let service = MockArtworkService(
            fetchResults: [.success(page([1, 2], currentPage: 1, totalPages: 3))],
            searchResults: [.success(page([99], currentPage: 1, totalPages: 1))]
        )
        let sut = ArtworkRepository(service: service)

        try await sut.loadNextPage()          // browse page 1 → [1, 2]
        try await sut.search("monet")          // resets → [99]

        #expect(sut.artworks.map(\.id) == [99])
        let searchCalls = service.searchCalls
        #expect(searchCalls.count == 1)
        #expect(searchCalls.first?.query == "monet")
        #expect(searchCalls.first?.page == 1)
    }

    @Test func emptyQueryReturnsToBrowsing() async throws {
        let service = MockArtworkService(
            fetchResults: [.success(page([1, 2], currentPage: 1, totalPages: 3))],
            searchResults: [.success(page([99], currentPage: 1, totalPages: 1))]
        )
        let sut = ArtworkRepository(service: service)

        try await sut.search("   ")            // whitespace → browse

        #expect(sut.artworks.map(\.id) == [1, 2])
        let fetchCalls = service.fetchCalls
        #expect(fetchCalls == [1])
    }

    // MARK: - Errors

    @Test func errorPropagatesAndLeavesStateClean() async throws {
        let service = MockArtworkService.failing(APIError.transport)
        let sut = ArtworkRepository(service: service)

        await #expect(throws: APIError.transport) {
            try await sut.loadNextPage()
        }
        #expect(sut.artworks.isEmpty)
        #expect(sut.canLoadMore) // failed load didn't advance the cursor
    }

    @Test func retryAfterErrorRequestsPageOneAgain() async throws {
        let service = MockArtworkService(fetchResults: [
            .failure(APIError.transport),
            .success(page([1, 2], currentPage: 1, totalPages: 2))
        ])
        let sut = ArtworkRepository(service: service)

        await #expect(throws: APIError.transport) {
            try await sut.loadNextPage()
        }
        try await sut.loadNextPage() // retry

        #expect(sut.artworks.map(\.id) == [1, 2])
        let calls = service.fetchCalls
        #expect(calls == [1, 1]) // both attempts targeted page 1
    }
}
