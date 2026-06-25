//
//  ArtworkListView.swift
//  Artwork
//
//  Created by Dima Starodubtsev on 6/24/26.
//
//  The list screen. Switches on the view model's ViewState to show the right
//  full-screen state, renders rows when loaded, and drives infinite scroll by
//  triggering the next page as the last row appears.
//

import SwiftUI

struct ArtworkListView: View {
    @StateObject private var viewModel: ArtworkListViewModel
    @State private var query = ""

    /// Builds a detail view model for a tapped artwork. Injected so the view
    /// stays unaware of how the detail screen gets its service.
    private let makeDetailViewModel: (ArtworkModel) -> ArtworkDetailViewModel

    init(
        viewModel: ArtworkListViewModel,
        makeDetailViewModel: @escaping (ArtworkModel) -> ArtworkDetailViewModel
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.makeDetailViewModel = makeDetailViewModel
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(Strings.List.title)
                .navigationDestination(for: ArtworkModel.self) { artwork in
                    ArtworkDetailView(viewModel: makeDetailViewModel(artwork))
                }
                .searchable(text: $query, prompt: Strings.List.searchPrompt)
                .onChange(of: query) { _, newValue in
                    // The view model debounces and cancels in-flight work, so
                    // it's safe to forward every keystroke (and the clear).
                    viewModel.search(newValue)
                }
        }
        .task {
            // Initial load only — re-entering the view shouldn't refetch.
            if viewModel.artworks.isEmpty {
                await viewModel.loadNextPage()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.viewState {
        case .loading:
            LoadingView()
        case .empty:
            EmptyStateView()
        case .error(let message):
            ErrorView(message: message) {
                Task { await viewModel.loadNextPage() }
            }
        case .loaded:
            list
        }
    }

    private var list: some View {
        List {
            ForEach(viewModel.artworks) { artwork in
                NavigationLink(value: artwork) {
                    ArtworkRow(viewModel: ArtworkRowViewModel(artwork: artwork))
                }
                .onAppear { loadMoreIfNeeded(currentItem: artwork) }
            }

            if viewModel.isLoadingNextPage {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
    }

    /// Triggers the next page when the last row surfaces. The repository's
    /// in-flight guard absorbs the repeated `.onAppear` calls fast scrolling
    /// produces, so this stays naive.
    private func loadMoreIfNeeded(currentItem: ArtworkModel) {
        guard viewModel.canLoadMore,
              currentItem.id == viewModel.artworks.last?.id else { return }
        Task { await viewModel.loadNextPage() }
    }
}
