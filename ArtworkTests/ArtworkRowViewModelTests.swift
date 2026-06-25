//
//  ArtworkRowViewModelTests.swift
//  ArtworkTests
//
//  Created by Dima Starodubtsev on 6/24/26.
//
//  Verifies the row view model's display mapping: real values pass through,
//  missing values fall back to readable placeholders, and the image URL is nil
//  when there's no image_id.
//

import Foundation
import Testing
@testable import Artwork

struct ArtworkRowViewModelTests {

    @Test func passesThroughPresentValues() {
        let sut = ArtworkRowViewModel(artwork: ArtworkModel(
            id: 1, title: "Water Lilies",
            artistDisplay: "Claude Monet", dateDisplay: "1906",
            imageId: "abc"
        ))

        #expect(sut.title == "Water Lilies")
        #expect(sut.artist == "Claude Monet")
        #expect(sut.date == "1906")
    }

    @Test func fallsBackWhenFieldsAreNil() {
        let sut = ArtworkRowViewModel(artwork: ArtworkModel(
            id: 1, title: nil, artistDisplay: nil, dateDisplay: nil, imageId: nil
        ))

        #expect(sut.title == Strings.Artwork.untitled)
        #expect(sut.artist == Strings.Artwork.unknownArtist)
        #expect(sut.date == Strings.Artwork.unknownDate)
    }

    @Test func buildsImageURLWhenImageIdPresent() {
        let sut = ArtworkRowViewModel(artwork: Fixtures.artwork(imageId: "abc"))

        #expect(sut.imageURL == URL(string: "https://www.artic.edu/iiif/2/abc/full/400,/0/default.jpg"))
    }

    @Test func imageURLIsNilWhenImageIdMissing() {
        let sut = ArtworkRowViewModel(artwork: Fixtures.artwork(imageId: nil))

        #expect(sut.imageURL == nil)
    }

    @Test func accessibilityLabelCombinesFields() {
        let sut = ArtworkRowViewModel(artwork: ArtworkModel(
            id: 1, title: "Water Lilies",
            artistDisplay: "Claude Monet", dateDisplay: "1906", imageId: nil
        ))

        #expect(sut.accessibilityLabel == "Water Lilies, Claude Monet, 1906")
    }
}
