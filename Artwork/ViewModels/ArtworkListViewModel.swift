//
//  ArtworkListViewModel.swift
//  Artwork
//
//  Created by Dima Starodubtsev on 6/24/26.
//
//  Maps repository results onto presentation state for the list screen. Owns no
//  pagination math or networking — it translates outcomes into `ViewState`,
//  tracks the footer-spinner flag, and debounces/cancels search so only the
//  latest query is applied. `@MainActor` so every published mutation is on the
//  main thread.
//

import Foundation
import Combine

@MainActor
final class ArtworkListViewModel: ArtworkListViewModelProtocol {

    @Published private(set) var artworks: [ArtworkModel] = []
    @Published private(set) var viewState: ViewState = .loading
    @Published private(set) var isLoadingNextPage = false
    @Published private(set) var canLoadMore = true

    private let repository: any ArtworkRepositoryProtocol
    private let searchDebounce: Duration

    /// The in-flight debounced search. Retained so a new keystroke can cancel it
    /// before starting another; exposed for tests to await deterministically.
    private(set) var searchTask: Task<Void, Never>?

    init(
        repository: any ArtworkRepositoryProtocol,
        searchDebounce: Duration = .milliseconds(300)
    ) {
        self.repository = repository
        self.searchDebounce = searchDebounce
    }

    func loadNextPage() async {
        // First load drives the full-screen spinner; later pages drive the
        // footer spinner so the already-visible list isn't replaced.
        let isFirstLoad = artworks.isEmpty
        if isFirstLoad { viewState = .loading } else { isLoadingNextPage = true }
        defer { isLoadingNextPage = false }

        do {
            try await repository.loadNextPage()
            apply()
        } catch {
            // A failed *additional* page keeps the existing list visible; only a
            // failed first load escalates to the full-screen error state.
            if artworks.isEmpty {
                viewState = .error(message(for: error))
            } else {
                viewState = .loaded
            }
        }
    }

    func search(_ query: String) {
        searchTask?.cancel()
        searchTask = Task { [weak self] in
            guard let self else { return }
            // Debounce: a newer keystroke cancels this task during the sleep.
            try? await Task.sleep(for: searchDebounce)
            guard !Task.isCancelled else { return }

            do {
                try await repository.search(query)
                guard !Task.isCancelled else { return }
                apply()
            } catch is CancellationError {
                // Superseded by a newer query — ignore.
            } catch {
                viewState = .error(message(for: error))
            }
        }
    }

    // MARK: - Private

    /// Pulls the latest snapshot from the repository into presentation state.
    private func apply() {
        artworks = repository.artworks
        canLoadMore = repository.canLoadMore
        viewState = artworks.isEmpty ? .empty : .loaded
    }

    private func message(for error: Error) -> String {
        (error as? APIError)?.message ?? error.localizedDescription
    }
}
