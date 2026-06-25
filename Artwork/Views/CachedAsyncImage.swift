//
//  CachedAsyncImage.swift
//  Artwork
//
//  Created by Dima Starodubtsev on 6/24/26.
//
//  An AsyncImage-style view backed by an injectable ImageCaching. On a cache
//  hit it renders immediately; otherwise it downloads (with a request timeout),
//  stores, and displays. Exposes a loading/success/failure phase so callers can
//  distinguish "still loading" from "failed" — a plain placeholder can't, which
//  otherwise leaves a spinner spinning forever on a slow or failed download.
//  The download is driven by `.task(id:)`, so it cancels when the URL changes
//  or the view disappears.
//

import SwiftUI

/// Load state passed to a `CachedAsyncImage` content builder. Declared at file
/// scope (not nested in the generic) so the builder's parameter type doesn't
/// depend on `Content`, which would make `Content` impossible to infer.
enum CachedImagePhase {
    case loading
    case success(Image)
    case failure
}

/// Shared session for image downloads. Lives outside the generic view because
/// Swift doesn't allow static stored properties in generic types. The bounded
/// timeout ensures a stalled request fails (and shows a placeholder) instead of
/// hanging indefinitely.
private enum ImageLoader {
    static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        return URLSession(configuration: config)
    }()
}

struct CachedAsyncImage<Content: View>: View {
    private let url: URL?
    private let cache: any ImageCaching
    private let content: (CachedImagePhase) -> Content

    @State private var phase: CachedImagePhase = .loading

    init(
        url: URL?,
        cache: any ImageCaching = ImageCache.shared,
        @ViewBuilder content: @escaping (CachedImagePhase) -> Content
    ) {
        self.url = url
        self.cache = cache
        self.content = content
    }

    var body: some View {
        content(phase)
            .task(id: url) { await load() }
    }

    private func load() async {
        // No URL (e.g. missing image_id) → failure placeholder, no spinner.
        guard let url else {
            phase = .failure
            return
        }

        if let cached = cache.image(for: url) {
            phase = .success(Image(uiImage: cached))
            return
        }

        phase = .loading
        do {
            let (data, _) = try await ImageLoader.session.data(from: url)
            guard !Task.isCancelled, let image = UIImage(data: data) else {
                if !Task.isCancelled { phase = .failure }
                return
            }
            cache.insert(image, for: url)
            phase = .success(Image(uiImage: image))
        } catch {
            if !Task.isCancelled { phase = .failure }
        }
    }
}
