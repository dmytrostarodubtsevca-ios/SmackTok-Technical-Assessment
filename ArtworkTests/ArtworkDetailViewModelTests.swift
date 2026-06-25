//
//  ArtworkDetailViewModelTests.swift
//  ArtworkTests
//
//  Created by Dima Starodubtsev on 6/24/26.
//
//  Verifies the detail view model: immediate headline fields, the detail fetch
//  building ordered fact rows + stripped description, and failure handling.
//

import Foundation
import Testing
@testable import Artwork

@MainActor
struct ArtworkDetailViewModelTests {

    private func detail(
        medium: String? = "Oil on canvas",
        dimensions: String? = "89.9 × 94.1 cm",
        origin: String? = "France",
        credit: String? = "Ryerson Collection",
        department: String? = "European Painting",
        type: String? = "Painting",
        description: String? = "<p>A water garden <em>obsession</em>.</p>"
    ) -> ArtworkDetailModel {
        ArtworkDetailModel(
            id: 1, title: "Water Lilies", artistDisplay: "Monet", dateDisplay: "1906",
            imageId: "abc", mediumDisplay: medium, dimensions: dimensions,
            placeOfOrigin: origin, creditLine: credit, departmentTitle: department,
            artworkTypeTitle: type, description: description
        )
    }

    @Test func headlineFieldsAvailableImmediately() {
        let sut = ArtworkDetailViewModel(
            artwork: ArtworkModel(id: 1, title: nil, artistDisplay: nil, dateDisplay: nil, imageId: nil),
            service: MockArtworkService()
        )

        #expect(sut.title == Strings.Artwork.untitled)
        #expect(sut.artist == Strings.Artwork.unknownArtist)
        #expect(sut.imageURL == nil)
        #expect(sut.loadState == .loading)
    }

    @Test func loadBuildsFactsAndStripsDescription() async {
        let service = MockArtworkService(detailResult: .success(detail()))
        let sut = ArtworkDetailViewModel(artwork: Fixtures.artwork(), service: service)

        await sut.load()

        #expect(sut.loadState == .loaded)
        #expect(sut.facts.map(\.label) == [
            Strings.Detail.type, Strings.Detail.medium, Strings.Detail.dimensions,
            Strings.Detail.origin, Strings.Detail.department, Strings.Detail.credit
        ])
        let aboutText = sut.about.map {
            String($0.characters).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        #expect(aboutText == "A water garden obsession.")
    }

    @Test func loadSkipsMissingFields() async {
        let service = MockArtworkService(detailResult: .success(
            detail(dimensions: nil, origin: nil, credit: nil, department: nil, description: nil)
        ))
        let sut = ArtworkDetailViewModel(artwork: Fixtures.artwork(), service: service)

        await sut.load()

        #expect(sut.facts.map(\.label) == [Strings.Detail.type, Strings.Detail.medium])
        #expect(sut.about == nil)
    }

    @Test func loadFailureSetsFailedState() async {
        let service = MockArtworkService(detailResult: .failure(APIError.transport))
        let sut = ArtworkDetailViewModel(artwork: Fixtures.artwork(), service: service)

        await sut.load()

        #expect(sut.loadState == .failed)
        #expect(sut.facts.isEmpty)
    }
}
