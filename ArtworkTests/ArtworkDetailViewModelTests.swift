//
//  ArtworkDetailViewModelTests.swift
//  ArtworkTests
//
//  Created by Dima Starodubtsev on 6/24/26.
//
//  Verifies the detail view model's display mapping and that it requests the
//  larger detail-width IIIF rendition.
//

import Foundation
import Testing
@testable import Artwork

struct ArtworkDetailViewModelTests {

    @Test func fallsBackWhenFieldsAreNil() {
        let sut = ArtworkDetailViewModel(artwork: ArtworkModel(
            id: 1, title: nil, artistDisplay: nil, dateDisplay: nil, imageId: nil
        ))

        #expect(sut.title == Strings.Artwork.untitled)
        #expect(sut.artist == Strings.Artwork.unknownArtist)
        #expect(sut.date == Strings.Artwork.unknownDate)
        #expect(sut.imageURL == nil)
    }

    @Test func usesDetailWidthForImage() {
        let sut = ArtworkDetailViewModel(artwork: Fixtures.artwork(imageId: "abc"))

        #expect(sut.imageURL == URL(string: "https://www.artic.edu/iiif/2/abc/full/843,/0/default.jpg"))
    }
}
