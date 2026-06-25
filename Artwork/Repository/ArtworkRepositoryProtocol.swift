//
//  ArtworkRepositoryProtocol.swift
//  Artwork
//
//  Created by Dima Starodubtsev on 6/24/26.
//

import Foundation

/// Stateful source of truth for paginated artwork browsing.
///
/// Sits between the stateless `ArtworkServiceProtocol` and the view model. It
/// owns the accumulated list, the current page cursor, and whether the user is
/// browsing or searching — exposing intent-level calls instead of raw page
/// numbers. Abstracting it behind a protocol lets the view model be tested
/// against a mock with no network and no real pagination logic.
protocol ArtworkRepositoryProtocol {
    /// All artworks loaded so far, accumulated across pages.
    var artworks: [ArtworkModel] { get }

    /// Whether another page is available (`currentPage < totalPages`).
    var canLoadMore: Bool { get }

    /// Loads the next page and appends its items.
    ///
    /// With no pages loaded yet (`currentPage == 0`) this loads the first page,
    /// so it doubles as the initial load and the retry path. No-ops while a load
    /// is already in flight or once the last page has been reached.
    func loadNextPage() async throws

    /// Switches to search mode for `query`, resetting pagination to page 1 and
    /// clearing the accumulated list before loading the first page of results.
    /// An empty query returns to the browse listing.
    func search(_ query: String) async throws
}
