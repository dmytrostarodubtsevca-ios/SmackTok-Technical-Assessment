//
//  ImageCache.swift
//  Artwork
//
//  Created by Dima Starodubtsev on 6/24/26.
//
//  A small in-memory image cache behind a protocol, so the image view can be
//  given a real cache in the app and a stub in tests. Backed by NSCache, which
//  is thread-safe and evicts under memory pressure.
//

internal import UIKit

protocol ImageCaching: Sendable {
    func image(for url: URL) -> UIImage?
    func insert(_ image: UIImage, for url: URL)
}

final class ImageCache: ImageCaching, @unchecked Sendable {
    /// Shared instance used by the app; tests inject their own.
    static let shared = ImageCache()

    private let cache = NSCache<NSURL, UIImage>()

    func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    func insert(_ image: UIImage, for url: URL) {
        cache.setObject(image, forKey: url as NSURL)
    }
}
