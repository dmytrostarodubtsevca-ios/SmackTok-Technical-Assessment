//
//  ImageCacheTests.swift
//  ArtworkTests
//
//  Created by Dima Starodubtsev on 6/24/26.
//
//  Verifies the in-memory cache stores and retrieves images by URL.
//

import UIKit
import Testing
@testable import Artwork

struct ImageCacheTests {

    private let url = URL(string: "https://example.com/a.jpg")!

    @Test func missReturnsNil() {
        let sut = ImageCache()
        #expect(sut.image(for: url) == nil)
    }

    @Test func insertThenRetrieveReturnsSameImage() {
        let sut = ImageCache()
        let image = UIImage(systemName: "photo")!

        sut.insert(image, for: url)

        #expect(sut.image(for: url) === image)
    }

    @Test func differentURLsAreIndependent() {
        let sut = ImageCache()
        let other = URL(string: "https://example.com/b.jpg")!
        sut.insert(UIImage(systemName: "photo")!, for: url)

        #expect(sut.image(for: other) == nil)
    }
}
