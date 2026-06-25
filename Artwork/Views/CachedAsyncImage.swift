//
//  CachedAsyncImage.swift
//  Artwork
//
//  Created by Dima Starodubtsev on 6/24/26.
//
//  An AsyncImage-style view backed by an injectable ImageCaching. On a cache
//  hit it renders immediately; otherwise it downloads, stores, and displays.
//  The download is driven by `.task(id:)`, so it cancels automatically when the
//  URL changes or the view disappears.
//

import SwiftUI

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    private let url: URL?
    private let cache: any ImageCaching
    private let content: (Image) -> Content
    private let placeholder: () -> Placeholder

    @State private var uiImage: UIImage?

    init(
        url: URL?,
        cache: any ImageCaching = ImageCache.shared,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.cache = cache
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let uiImage {
                content(Image(uiImage: uiImage))
            } else {
                placeholder()
            }
        }
        .task(id: url) { await load() }
    }

    private func load() async {
        guard let url else { return }

        if let cached = cache.image(for: url) {
            uiImage = cached
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard !Task.isCancelled, let image = UIImage(data: data) else { return }
            cache.insert(image, for: url)
            uiImage = image
        } catch {
            // Leave the placeholder in place on failure.
        }
    }
}
