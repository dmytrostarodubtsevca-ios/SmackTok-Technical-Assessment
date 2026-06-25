//
//  ArtworkServiceProtocol.swift
//  Artwork
//
//  Created by Dima Starodubtsev on 6/24/26.
//

import Foundation

/// Stateless gateway to the Art Institute of Chicago API.
///
/// Each call fetches exactly one page and returns a decoded `ArtworkPageModel`.
/// The service knows nothing about accumulation, the "current" page, or browse
/// vs. search mode — that pagination state lives in the repository. Abstracting
/// it behind a protocol lets the repository be tested against a mock with no
/// live network.
protocol ArtworkServiceProtocol {
    /// Fetches a page from the browse endpoint (`/artworks`).
    /// - Parameter page: 1-based page index.
    func fetchArtworks(page: Int) async throws -> ArtworkPageModel

    /// Fetches a page from the search endpoint (`/artworks/search`).
    /// - Parameters:
    ///   - query: The user's search text.
    ///   - page: 1-based page index.
    func searchArtworks(query: String, page: Int) async throws -> ArtworkPageModel
}
