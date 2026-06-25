//
//  ArtworkDetailView.swift
//  Artwork
//
//  Created by Dima Starodubtsev on 6/24/26.
//
//  Full artwork detail: large IIIF image and headline fields render instantly
//  from the list data, while the richer metadata (facts + description) is
//  fetched by id and filled in with its own loading/failed handling.
//

import SwiftUI

struct ArtworkDetailView: View {
    @StateObject private var viewModel: ArtworkDetailViewModel

    init(viewModel: ArtworkDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                image
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.title).font(.title2.bold())
                    Text(viewModel.artist).font(.headline).foregroundStyle(.secondary)
                    Text(viewModel.date).font(.subheadline).foregroundStyle(.tertiary)
                }
                details
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }

    @ViewBuilder
    private var details: some View {
        switch viewModel.loadState {
        case .loading:
            ProgressView().frame(maxWidth: .infinity).padding(.top)
        case .failed:
            Text(Strings.Detail.detailsUnavailable)
                .font(.footnote)
                .foregroundStyle(.secondary)
        case .loaded:
            VStack(alignment: .leading, spacing: 16) {
                if !viewModel.facts.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.facts) { fact in
                            factRow(fact)
                        }
                    }
                }
                if let about = viewModel.about {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Strings.Detail.about).font(.headline)
                        Text(about)
                    }
                }
            }
        }
    }

    private func factRow(_ fact: DetailFact) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(fact.label)
                .font(.subheadline.bold())
                .frame(width: 96, alignment: .leading)
            Text(fact.value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var image: some View {
        CachedAsyncImage(url: viewModel.imageURL) { phase in
            switch phase {
            case .loading:
                ProgressView().frame(height: 240)
            case .success(let image):
                image.resizable().scaledToFit()
            case .failure:
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
