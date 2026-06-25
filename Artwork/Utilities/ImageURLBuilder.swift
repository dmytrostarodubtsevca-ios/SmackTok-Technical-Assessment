//
//  ImageURLBuilder.swift
//  Artwork
//
//  Created by Dima Starodubtsev on 6/24/26.
//

import Foundation

/// Builds IIIF image URLs for an artwork.
///
/// Format (per the AIC API): `{iiifBase}/{imageId}/full/{size}/0/default.jpg`.
/// `iiifBase` comes from the response's `config.iiif_url` rather than being
/// hardcoded, so it tracks the contract. Returns `nil` when the artwork has no
/// `imageId`, which callers use to show a placeholder instead of a broken image.
enum ImageURLBuilder {
    /// Default rendition width requested from the IIIF server.
    static let defaultWidth = 400

    static func url(imageId: String?, iiifBase: String, width: Int = defaultWidth) -> URL? {
        guard let imageId, !imageId.isEmpty else { return nil }
        return URL(string: "\(iiifBase)/\(imageId)/full/\(width),/0/default.jpg")
    }
}
