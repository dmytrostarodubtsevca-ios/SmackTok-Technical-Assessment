//
//  ArtworkListViewModelProtocol.swift
//  Artwork
//
//  Created by Dima Starodubtsev on 6/24/26.
//

import Foundation

/// Presentation-facing contract for the artwork list screen.
///
/// Exposes only what the view needs: the items to render, the full-screen
/// `viewState`, a separate pagination flag for the footer spinner, and the two
/// user intents (scroll-to-load-more, search). Page numbers, URLs, and decoding
/// stay below this boundary. `@MainActor` guarantees all published mutations
/// happen on the main thread; `ObservableObject` lets SwiftUI observe them.
@MainActor
protocol ArtworkListViewModelProtocol: ObservableObject {
    /// Artworks to display, accumulated across pages.
    var artworks: [ArtworkModel] { get }

    /// Drives the full-screen state (loading / loaded / empty / error).
    var viewState: ViewState { get }

    /// Whether a subsequent page is currently being fetched. Drives the footer
    /// spinner during infinite scroll — distinct from `viewState == .loading`,
    /// which is the initial full-screen load.
    var isLoadingNextPage: Bool { get }

    /// Whether more pages remain to load.
    var canLoadMore: Bool { get }

    /// Loads the next page (or the first page on initial appearance / retry).
    func loadNextPage() async

    /// Updates the search query. Implementations debounce and cancel in-flight
    /// work so only the latest query's results are applied.
    func search(_ query: String)
}
