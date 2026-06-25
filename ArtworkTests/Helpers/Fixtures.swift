//
//  Fixtures.swift
//  ArtworkTests
//
//  Created by Dima Starodubtsev on 6/24/26.
//
//  Shared test data: model factories plus real JSON captured from the live
//  Art Institute of Chicago API (trimmed to the fields we request). Using real
//  payloads — including the `_score`/`info`/`config` noise and a null image_id —
//  keeps the decode tests honest about the actual contract.
//

import Foundation
@testable import Artwork

enum Fixtures {

    // MARK: - Model factories

    static func artwork(
        id: Int = 1,
        title: String? = "Untitled",
        artistDisplay: String? = "Some Artist",
        dateDisplay: String? = "1900",
        imageId: String? = "img-\(UUID().uuidString)"
    ) -> ArtworkModel {
        ArtworkModel(
            id: id,
            title: title,
            artistDisplay: artistDisplay,
            dateDisplay: dateDisplay,
            imageId: imageId
        )
    }

    static func page(
        count: Int = 3,
        currentPage: Int = 1,
        totalPages: Int = 5,
        startingAt start: Int = 1
    ) -> ArtworkPageModel {
        let items = (start..<(start + count)).map { artwork(id: $0) }
        return ArtworkPageModel(items: items, currentPage: currentPage, totalPages: totalPages)
    }

    // MARK: - Raw JSON (real API shapes)

    /// A normal list page: pagination cursor + two items + config.
    static let listJSON = """
    {
      "pagination": { "total": 100, "limit": 2, "offset": 0, "total_pages": 50, "current_page": 1 },
      "data": [
        { "id": 80487, "title": "Arbor Day", "date_display": "1920",
          "artist_display": "Eugene Francis Savage (American, 1883–1966)",
          "image_id": "9157e82e-0ef5-329d-85a8-696dfe3b045e" },
        { "id": 65151, "title": "Linear", "date_display": "1950s",
          "artist_display": "Joseph R. Bobrowicz", "image_id": "f3cf108f-2d2c-37d2-1ff3-f8d34f232e62" }
      ],
      "config": { "iiif_url": "https://www.artic.edu/iiif/2" }
    }
    """

    /// Search shape: carries top-level `preference` and per-item `_score` that
    /// our decoder must ignore.
    static let searchJSON = """
    {
      "preference": null,
      "pagination": { "total": 100, "limit": 1, "offset": 0, "total_pages": 50, "current_page": 1 },
      "data": [
        { "_score": 119.66, "id": 16568, "title": "Water Lilies", "date_display": "1906",
          "artist_display": "Claude Monet", "image_id": "3c27b499-af56-f0d5-93b5-a7f2f1ad5813" }
      ],
      "config": { "iiif_url": "https://www.artic.edu/iiif/2" }
    }
    """

    /// An item with `image_id: null` — must decode to `nil`, not crash.
    static let nullImageJSON = """
    {
      "pagination": { "total": 1, "limit": 1, "offset": 0, "total_pages": 1, "current_page": 1 },
      "data": [
        { "id": 67428, "title": "Jug", "date_display": null, "artist_display": null, "image_id": null }
      ],
      "config": { "iiif_url": "https://www.artic.edu/iiif/2" }
    }
    """

    /// A successful response with no results — drives the empty state.
    static let emptyJSON = """
    {
      "pagination": { "total": 0, "limit": 20, "offset": 0, "total_pages": 0, "current_page": 1 },
      "data": [],
      "config": { "iiif_url": "https://www.artic.edu/iiif/2" }
    }
    """

    /// Single-artwork detail response: `data` is one object with rich fields,
    /// and `description` carries HTML.
    static let detailJSON = """
    {
      "data": {
        "id": 16568, "title": "Water Lilies", "date_display": "1906",
        "artist_display": "Claude Monet", "place_of_origin": "France",
        "description": "<p>A water garden <em>obsession</em>.</p>",
        "dimensions": "89.9 × 94.1 cm", "medium_display": "Oil on canvas",
        "credit_line": "Ryerson Collection", "artwork_type_title": "Painting",
        "department_title": "Painting and Sculpture of Europe",
        "image_id": "3c27b499-af56-f0d5-93b5-a7f2f1ad5813"
      },
      "config": { "iiif_url": "https://www.artic.edu/iiif/2" }
    }
    """

    /// Structurally invalid for our model (missing `pagination`) — decode error.
    static let malformedJSON = """
    { "data": "not-an-array" }
    """

    static func data(_ json: String) -> Data { Data(json.utf8) }
}
