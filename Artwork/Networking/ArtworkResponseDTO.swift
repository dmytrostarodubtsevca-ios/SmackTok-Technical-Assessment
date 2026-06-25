//
//  ArtworkResponseDTO.swift
//  Artwork
//
//  Created by Dima Starodubtsev on 6/24/26.
//

import Foundation

/// Wire shape of a list/search response, decoded straight from JSON.
///
/// Items decode directly into `ArtworkModel` (which is `Codable`), so no
/// per-item DTO is needed. This wrapper exists only to pull the surrounding
/// `pagination` cursor and `config.iiif_url` out of the envelope. Fields we
/// don't declare (`info`, `preference`, per-item `score`) are ignored.
///
/// Decoded with `JSONDecoder.keyDecodingStrategy = .convertFromSnakeCase`, so
/// `current_page` → `currentPage`, `total_pages` → `totalPages`, etc.
struct ArtworkResponseDTO: Decodable {
    let data: [ArtworkModel]
    let pagination: Pagination
    let config: Config

    struct Pagination: Decodable {
        let currentPage: Int
        let totalPages: Int
    }

    struct Config: Decodable {
        let iiifUrl: String
    }

    /// Flattens the envelope into the domain page model.
    func toPage() -> ArtworkPageModel {
        ArtworkPageModel(
            items: data,
            currentPage: pagination.currentPage,
            totalPages: pagination.totalPages
        )
    }
}

/// Wire shape of a single-artwork response, where `data` is one object.
struct ArtworkDetailResponseDTO: Decodable {
    let data: ArtworkDetailModel
}
