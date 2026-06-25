//
//  ArtworkRow.swift
//  Artwork
//
//  Created by Dima Starodubtsev on 6/24/26.
//
//  A single row in the artwork list: thumbnail plus title, artist, and date.
//  Driven entirely by ArtworkRowViewModel — the row never sees the model, so
//  it stays purely layout.
//

import SwiftUI

struct ArtworkRow: View {
    let viewModel: ArtworkRowViewModel

    var body: some View {
        HStack(spacing: 12) {
            thumbnail
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(viewModel.artist)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(viewModel.date)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(viewModel.accessibilityLabel)
    }

    @ViewBuilder
    private var thumbnail: some View {
        CachedAsyncImage(url: viewModel.imageURL) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            if viewModel.imageURL != nil {
                ProgressView()
            } else {
                // No image_id → neutral placeholder.
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 64, height: 64)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityHidden(true) // decorative; the row label conveys the content
    }
}

#Preview {
    List {
        ArtworkRow(viewModel: ArtworkRowViewModel(artwork: ArtworkModel(
            id: 1, title: "Water Lilies",
            artistDisplay: "Claude Monet", dateDisplay: "1906",
            imageId: "3c27b499-af56-f0d5-93b5-a7f2f1ad5813"
        )))
        ArtworkRow(viewModel: ArtworkRowViewModel(artwork: ArtworkModel(
            id: 2, title: nil, artistDisplay: nil, dateDisplay: nil, imageId: nil
        )))
    }
}
