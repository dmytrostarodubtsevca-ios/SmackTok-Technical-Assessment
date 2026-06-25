//
//  ArtworkServiceTests.swift
//  ArtworkTests
//
//  Created by Dima Starodubtsev on 6/24/26.
//
//  Exercises the real ArtworkService end-to-end (URL building → URLSession →
//  status validation → decoding) against URLProtocolStub, with no network.
//
//  Serialized: the stub stores its canned response in process-global state, so
//  the suite must not run its cases in parallel.
//

import Foundation
import Testing
@testable import Artwork

@Suite(.serialized)
struct ArtworkServiceTests {

    private func makeSUT() -> ArtworkService {
        URLProtocolStub.reset()
        return ArtworkService(session: URLProtocolStub.makeSession())
    }

    private func queryItems(of url: URL) -> [String: String] {
        let comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        return Dictionary(uniqueKeysWithValues: (comps?.queryItems ?? []).map { ($0.name, $0.value ?? "") })
    }

    // MARK: - Decoding

    @Test func fetchDecodesItemsAndPagination() async throws {
        let sut = makeSUT()
        URLProtocolStub.stub(data: Fixtures.data(Fixtures.listJSON))

        let page = try await sut.fetchArtworks(page: 1)

        #expect(page.items.count == 2)
        #expect(page.currentPage == 1)
        #expect(page.totalPages == 50)
        #expect(page.items.first?.id == 80487)
        #expect(page.items.first?.title == "Arbor Day")
    }

    @Test func searchIgnoresScoreAndPreferenceNoise() async throws {
        let sut = makeSUT()
        URLProtocolStub.stub(data: Fixtures.data(Fixtures.searchJSON))

        let page = try await sut.searchArtworks(query: "monet", page: 1)

        #expect(page.items.count == 1)
        #expect(page.items.first?.title == "Water Lilies")
    }

    @Test func nullImageIdDecodesToNil() async throws {
        let sut = makeSUT()
        URLProtocolStub.stub(data: Fixtures.data(Fixtures.nullImageJSON))

        let page = try await sut.fetchArtworks(page: 1)

        #expect(page.items.first?.imageId == nil)
        #expect(page.items.first?.title == "Jug")
    }

    @Test func emptyDataDecodesToEmptyPage() async throws {
        let sut = makeSUT()
        URLProtocolStub.stub(data: Fixtures.data(Fixtures.emptyJSON))

        let page = try await sut.fetchArtworks(page: 1)

        #expect(page.items.isEmpty)
    }

    @Test func fetchArtworkDecodesRichFields() async throws {
        let sut = makeSUT()
        URLProtocolStub.stub(data: Fixtures.data(Fixtures.detailJSON))

        let detail = try await sut.fetchArtwork(id: 16568)

        #expect(detail.id == 16568)
        #expect(detail.mediumDisplay == "Oil on canvas")
        #expect(detail.placeOfOrigin == "France")
        #expect(detail.creditLine == "Ryerson Collection")
        #expect(detail.description?.contains("<em>") == true)
    }

    @Test func fetchArtworkBuildsByIDPath() async throws {
        let sut = makeSUT()
        URLProtocolStub.stub(data: Fixtures.data(Fixtures.detailJSON))

        _ = try await sut.fetchArtwork(id: 16568)

        let url = try #require(URLProtocolStub.requestedURLs.last)
        #expect(url.path.hasSuffix("/artworks/16568"))
    }

    // MARK: - Errors

    @Test func httpClientErrorThrowsBadStatus() async throws {
        let sut = makeSUT()
        URLProtocolStub.stub(data: Data("{}".utf8), statusCode: 404)

        await #expect(throws: APIError.badStatus(404)) {
            _ = try await sut.fetchArtworks(page: 1)
        }
    }

    @Test func httpServerErrorThrowsBadStatus() async throws {
        let sut = makeSUT()
        URLProtocolStub.stub(data: Data("{}".utf8), statusCode: 500)

        await #expect(throws: APIError.badStatus(500)) {
            _ = try await sut.fetchArtworks(page: 1)
        }
    }

    @Test func transportFailureThrowsTransport() async throws {
        let sut = makeSUT()
        URLProtocolStub.stub(error: URLError(.notConnectedToInternet))

        await #expect(throws: APIError.transport) {
            _ = try await sut.fetchArtworks(page: 1)
        }
    }

    @Test func malformedBodyThrowsDecoding() async throws {
        let sut = makeSUT()
        URLProtocolStub.stub(data: Fixtures.data(Fixtures.malformedJSON))

        await #expect(throws: APIError.decoding) {
            _ = try await sut.fetchArtworks(page: 1)
        }
    }

    @Test func nonHTTPResponseThrowsInvalidResponse() async throws {
        let sut = makeSUT()
        URLProtocolStub.stubNonHTTPResponse(data: Fixtures.data(Fixtures.listJSON))

        await #expect(throws: APIError.invalidResponse) {
            _ = try await sut.fetchArtworks(page: 1)
        }
    }

    // MARK: - Request building

    @Test func fetchBuildsCorrectQueryItems() async throws {
        let sut = makeSUT()
        URLProtocolStub.stub(data: Fixtures.data(Fixtures.listJSON))

        _ = try await sut.fetchArtworks(page: 2)

        let url = try #require(URLProtocolStub.requestedURLs.last)
        let items = queryItems(of: url)
        #expect(url.path.hasSuffix("/artworks"))
        #expect(items["page"] == "2")
        #expect(items["limit"] == "20")
        #expect(items["fields"] == "id,title,artist_display,date_display,image_id")
    }

    @Test func searchBuildsCorrectQueryItems() async throws {
        let sut = makeSUT()
        URLProtocolStub.stub(data: Fixtures.data(Fixtures.searchJSON))

        _ = try await sut.searchArtworks(query: "monet", page: 3)

        let url = try #require(URLProtocolStub.requestedURLs.last)
        let items = queryItems(of: url)
        #expect(url.path.hasSuffix("/artworks/search"))
        #expect(items["q"] == "monet")
        #expect(items["page"] == "3")
    }
}
