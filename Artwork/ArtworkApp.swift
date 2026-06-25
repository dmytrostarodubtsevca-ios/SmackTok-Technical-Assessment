//
//  ArtworkApp.swift
//  Artwork
//
//  Created by Dima Starodubtsev on 6/24/26.
//

import SwiftUI

@main
struct ArtworkApp: App {
    /// Composition root: the single place concrete types are assembled. The
    /// service is shared by the list (via the repository) and the detail screen.
    private let service = ArtworkService()

    var body: some Scene {
        WindowGroup {
            ArtworkListView(
                viewModel: ArtworkListViewModel(repository: ArtworkRepository(service: service)),
                makeDetailViewModel: { artwork in
                    ArtworkDetailViewModel(artwork: artwork, service: service)
                }
            )
        }
    }
}
