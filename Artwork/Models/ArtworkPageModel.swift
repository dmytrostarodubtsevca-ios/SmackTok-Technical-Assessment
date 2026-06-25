//
//  ArtworkPageModel.swift
//  Artwork
//
//  Created by Dima Starodubtsev on 6/24/26.
//

import Foundation

/// One page of artworks plus the pagination cursor reported by the API.
///
/// `currentPage` and `totalPages` come straight from the response's
/// `pagination` object, which lets the repository compute `canLoadMore`
/// without guessing.
struct ArtworkPageModel: Equatable {
    let items: [ArtworkModel]
    let currentPage: Int
    let totalPages: Int
}
