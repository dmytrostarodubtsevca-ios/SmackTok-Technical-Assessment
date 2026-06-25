//
//  ArtworkService.swift
//  Artwork
//
//  Created by Dima Starodubtsev on 6/24/26.
//

import Foundation

/// `URLSession`-backed implementation of `ArtworkServiceProtocol`.
///
/// Responsible only for building requests, performing them, validating the HTTP
/// status, and decoding into domain models. It holds no pagination state. The
/// `URLSession` is injected so tests can supply a `URLProtocol`-stubbed session
/// and run entirely offline.
struct ArtworkService: ArtworkServiceProtocol {
    private let session: URLSession
    private let baseURL = URL(string: "https://api.artic.edu/api/v1")!

    /// Fields requested from the API — matches the keys `ArtworkModel` decodes.
    private let fields = "id,title,artist_display,date_display,image_id"
    private let pageSize = 20

    init(session: URLSession = .shared) {
        self.session = session
    }

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    func fetchArtworks(page: Int) async throws -> ArtworkPageModel {
        let url = makeURL(path: "artworks", queryItems: [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(pageSize)),
            URLQueryItem(name: "fields", value: fields)
        ])
        return try await load(url)
    }

    func searchArtworks(query: String, page: Int) async throws -> ArtworkPageModel {
        let url = makeURL(path: "artworks/search", queryItems: [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: String(pageSize)),
            URLQueryItem(name: "fields", value: fields)
        ])
        return try await load(url)
    }

    // MARK: - Private

    private func makeURL(path: String, queryItems: [URLQueryItem]) -> URL {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = queryItems
        return components.url!
    }

    private func load(_ url: URL) async throws -> ArtworkPageModel {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw APIError.transport
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.badStatus(http.statusCode)
        }

        do {
            let dto = try Self.decoder.decode(ArtworkResponseDTO.self, from: data)
            return dto.toPage()
        } catch {
            throw APIError.decoding
        }
    }
}
