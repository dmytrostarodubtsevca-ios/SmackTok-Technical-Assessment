//
//  ArtworkDetailModel.swift
//  Artwork
//
//  Created by Dima Starodubtsev on 6/24/26.
//
//  The fuller artwork record returned by /artworks/{id}. Every field beyond
//  `id` is optional — detail responses routinely omit metadata. `description`
//  arrives as HTML and is sanitized for display by the view model.
//

import Foundation

struct ArtworkDetailModel: Equatable, Codable {
    let id: Int
    let title: String?
    let artistDisplay: String?
    let dateDisplay: String?
    let imageId: String?
    let mediumDisplay: String?
    let dimensions: String?
    let placeOfOrigin: String?
    let creditLine: String?
    let departmentTitle: String?
    let artworkTypeTitle: String?
    let description: String?
}
