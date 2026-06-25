//
//  ArtworkApp.swift
//  Artwork
//
//  Created by Dima Starodubtsev on 6/24/26.
//

import SwiftUI

@main
struct ArtworkApp: App {
    var body: some Scene {
        WindowGroup {
            ArtworkListView(viewModel: makeListViewModel())
        }
    }

    /// Composition root: wires the concrete service → repository → view model.
    /// The only place concrete types are assembled; everything below depends on
    /// protocols.
    @MainActor
    private func makeListViewModel() -> ArtworkListViewModel {
        let service = ArtworkService()
        let repository = ArtworkRepository(service: service)
        return ArtworkListViewModel(repository: repository)
    }
}
