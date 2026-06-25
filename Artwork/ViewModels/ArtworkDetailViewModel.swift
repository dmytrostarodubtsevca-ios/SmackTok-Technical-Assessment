//
//  ArtworkDetailViewModel.swift
//  Artwork
//
//  Created by Dima Starodubtsev on 6/24/26.
//
//  Display mapping for the detail screen. Built from the ArtworkModel already
//  held by the list, so opening detail needs no extra network call. Requests a
//  larger IIIF rendition than the row thumbnail.
//

import Foundation

struct ArtworkDetailViewModel: Equatable {
    let title: String
    let artist: String
    let date: String
    let imageURL: URL?

    init(artwork: ArtworkModel) {
        title = artwork.title ?? Strings.Artwork.untitled
        artist = artwork.artistDisplay ?? Strings.Artwork.unknownArtist
        date = artwork.dateDisplay ?? Strings.Artwork.unknownDate
        imageURL = ImageURLBuilder.url(imageId: artwork.imageId, width: ImageURLBuilder.detailWidth)
    }
}
