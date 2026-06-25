//
//  ArtworkRowViewModel.swift
//  Artwork
//
//  Created by Dima Starodubtsev on 6/24/26.
//
//  Maps an ArtworkModel into the display-ready strings and image URL a row
//  renders. A plain value type with no state, so the nil-fallback logic is
//  unit-testable without touching SwiftUI.
//

import Foundation

struct ArtworkRowViewModel: Equatable {
    let title: String
    let artist: String
    let date: String
    let imageURL: URL?

    init(artwork: ArtworkModel) {
        title = artwork.title ?? Strings.Artwork.untitled
        artist = artwork.artistDisplay ?? Strings.Artwork.unknownArtist
        date = artwork.dateDisplay ?? Strings.Artwork.unknownDate
        imageURL = ImageURLBuilder.url(imageId: artwork.imageId)
    }
}
