//
//  ArtworkListViewModelTests.swift
//  ArtworkTests
//
//  Created by Dima Starodubtsev on 6/24/26.
//
//  Drives the view model against a mock repository: full-screen state
//  transitions (loading/loaded/empty/error), the separate pagination flag,
//  append-on-next-page, and debounced search where only the latest query's
//  results are applied. No network.
//

import Foundation
import Testing
@testable import Artwork

@MainActor
struct ArtworkListViewModelTests {

    private func makeSUT(
        repository: MockArtworkRepository,
        debounce: Duration = .milliseconds(20)
    ) -> ArtworkListViewModel {
        ArtworkListViewModel(repository: repository, searchDebounce: debounce)
    }

    // MARK: - First load

    @Test func successfulLoadShowsLoadedState() async {
        let repo = MockArtworkRepository()
        repo.canLoadMore = false
        repo.onLoadNextPage = { repo.artworks = [Fixtures.artwork(id: 1), Fixtures.artwork(id: 2)] }
        let sut = makeSUT(repository: repo)

        await sut.loadNextPage()

        #expect(sut.viewState == .loaded)
        #expect(sut.artworks.map(\.id) == [1, 2])
        #expect(sut.isLoadingNextPage == false)
        #expect(sut.canLoadMore == false)
    }

    @Test func emptyResultShowsEmptyState() async {
        let repo = MockArtworkRepository()
        repo.canLoadMore = false
        // onLoadNextPage leaves artworks empty
        let sut = makeSUT(repository: repo)

        await sut.loadNextPage()

        #expect(sut.viewState == .empty)
        #expect(sut.artworks.isEmpty)
    }

    @Test func failedFirstLoadShowsErrorState() async {
        let repo = MockArtworkRepository()
        repo.loadNextPageError = APIError.transport
        let sut = makeSUT(repository: repo)

        await sut.loadNextPage()

        #expect(sut.viewState == .error(APIError.transport.message))
        #expect(sut.artworks.isEmpty)
    }

    // MARK: - Pagination

    @Test func secondPageAppendsAndStaysLoaded() async {
        let repo = MockArtworkRepository()
        repo.canLoadMore = true
        var call = 0
        repo.onLoadNextPage = {
            call += 1
            if call == 1 { repo.artworks = [Fixtures.artwork(id: 1)] }
            else { repo.artworks += [Fixtures.artwork(id: 2)] }
        }
        let sut = makeSUT(repository: repo)

        await sut.loadNextPage()
        await sut.loadNextPage()

        #expect(sut.viewState == .loaded)
        #expect(sut.artworks.map(\.id) == [1, 2])
        #expect(repo.loadNextPageCallCount == 2)
    }

    @Test func paginationErrorKeepsExistingList() async {
        let repo = MockArtworkRepository()
        repo.onLoadNextPage = { repo.artworks = [Fixtures.artwork(id: 1)] }
        let sut = makeSUT(repository: repo)

        await sut.loadNextPage()                 // succeeds → [1]
        repo.onLoadNextPage = nil
        repo.loadNextPageError = APIError.transport
        await sut.loadNextPage()                 // fails

        // A failed *next* page must not wipe the list or show a full-screen error.
        #expect(sut.viewState == .loaded)
        #expect(sut.artworks.map(\.id) == [1])
    }

    // MARK: - Search (debounced, cancellable)

    @Test func searchAppliesResults() async {
        let repo = MockArtworkRepository()
        repo.onSearch = { _ in repo.artworks = [Fixtures.artwork(id: 99)] }
        let sut = makeSUT(repository: repo)

        sut.search("monet")
        await sut.searchTask?.value

        #expect(sut.artworks.map(\.id) == [99])
        #expect(repo.searchedQueries == ["monet"])
    }

    @Test func rapidSearchAppliesOnlyLastQuery() async {
        let repo = MockArtworkRepository()
        repo.onSearch = { query in repo.artworks = [Fixtures.artwork(id: query.count)] }
        let sut = makeSUT(repository: repo, debounce: .milliseconds(30))

        sut.search("a")
        sut.search("ab")
        sut.search("monet")
        await sut.searchTask?.value

        // Earlier queries were cancelled during debounce → never reached the repo.
        #expect(repo.searchedQueries == ["monet"])
        #expect(sut.artworks.map(\.id) == [5])
    }
}
