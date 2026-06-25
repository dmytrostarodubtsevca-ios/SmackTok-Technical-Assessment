//
//  ArtworkDetailViewModel.swift
//  Artwork
//
//  Created by Dima Starodubtsev on 6/24/26.
//
//  Drives the detail screen. The headline fields (title/artist/date/image) are
//  available immediately from the ArtworkModel the list already holds, so the
//  screen renders instantly; the richer record is fetched by id and fills in the
//  fact rows and description, with its own loading/loaded/failed state.
//

import Foundation
import Combine

/// A labelled metadata row (e.g. "Medium" → "Oil on canvas").
struct DetailFact: Identifiable, Equatable {
    var id: String { label }
    let label: String
    let value: String
}

@MainActor
final class ArtworkDetailViewModel: ObservableObject {

    enum LoadState: Equatable {
        case loading
        case loaded
        case failed
    }

    // Immediately available from the list model.
    let title: String
    let artist: String
    let date: String
    let imageURL: URL?

    // Filled in by the detail fetch.
    @Published private(set) var loadState: LoadState = .loading
    @Published private(set) var facts: [DetailFact] = []
    @Published private(set) var about: AttributedString?

    private let id: Int
    private let service: any ArtworkServiceProtocol

    init(artwork: ArtworkModel, service: any ArtworkServiceProtocol) {
        id = artwork.id
        title = artwork.title ?? Strings.Artwork.untitled
        artist = artwork.artistDisplay ?? Strings.Artwork.unknownArtist
        date = artwork.dateDisplay ?? Strings.Artwork.unknownDate
        imageURL = ImageURLBuilder.url(imageId: artwork.imageId, width: ImageURLBuilder.detailWidth)
        self.service = service
    }

    func load() async {
        loadState = .loading
        do {
            let detail = try await service.fetchArtwork(id: id)
            facts = Self.makeFacts(from: detail)
            about = detail.description?.attributedHTML
            loadState = .loaded
        } catch {
            loadState = .failed
        }
    }

    /// Builds the ordered fact rows, skipping any field the API omitted.
    private static func makeFacts(from detail: ArtworkDetailModel) -> [DetailFact] {
        var facts: [DetailFact] = []
        func add(_ label: String, _ value: String?) {
            guard let value, !value.isEmpty else { return }
            facts.append(DetailFact(label: label, value: value))
        }
        add(Strings.Detail.type, detail.artworkTypeTitle)
        add(Strings.Detail.medium, detail.mediumDisplay)
        add(Strings.Detail.dimensions, detail.dimensions)
        add(Strings.Detail.origin, detail.placeOfOrigin)
        add(Strings.Detail.department, detail.departmentTitle)
        add(Strings.Detail.credit, detail.creditLine)
        return facts
    }
}
