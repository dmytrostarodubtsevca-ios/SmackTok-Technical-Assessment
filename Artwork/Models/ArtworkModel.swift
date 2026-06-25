//
//  ArtworkModel.swift
//  Artwork
//
//  Created by Dima Starodubtsev on 6/24/26.
//

import Foundation

/// A single artwork from the Art Institute of Chicago collection.
///
/// Only `id` is guaranteed by the API; every descriptive field is optional
/// because the collection contains records with missing metadata. The UI is
/// responsible for rendering sensible fallbacks (e.g. "Unknown artist").
struct ArtworkModel: Identifiable, Equatable, Codable {
    let id: Int
    let title: String?
    let artistDisplay: String?
    let dateDisplay: String?
    let imageId: String?
}
