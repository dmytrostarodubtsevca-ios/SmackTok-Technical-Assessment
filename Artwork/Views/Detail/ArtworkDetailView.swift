//
//  ArtworkDetailView.swift
//  Artwork
//
//  Created by Dima Starodubtsev on 6/24/26.
//
//  Full artwork detail: large IIIF image (or placeholder when there's no
//  image_id) above the title, artist, and date.
//

import SwiftUI

struct ArtworkDetailView: View {
    let viewModel: ArtworkDetailViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                image
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.title)
                        .font(.title2.bold())
                    Text(viewModel.artist)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text(viewModel.date)
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var image: some View {
        AsyncImage(url: viewModel.imageURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFit()
            case .empty where viewModel.imageURL != nil:
                ProgressView().frame(height: 240)
            default:
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 240)
                    .background(Color(.secondarySystemBackground))
            }
        }
        .accessibilityElement()
        .accessibilityLabel(viewModel.title)
        .accessibilityAddTraits(.isImage)
    }
}

#Preview {
    NavigationStack {
        ArtworkDetailView(viewModel: ArtworkDetailViewModel(artwork: ArtworkModel(
            id: 16568, title: "Water Lilies",
            artistDisplay: "Claude Monet", dateDisplay: "1906",
            imageId: "3c27b499-af56-f0d5-93b5-a7f2f1ad5813"
        )))
    }
}
