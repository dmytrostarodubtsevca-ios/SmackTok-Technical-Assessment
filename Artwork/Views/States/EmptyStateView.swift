//
//  EmptyStateView.swift
//  Artwork
//
//  Created by Dima Starodubtsev on 6/24/26.
//
//  Shown when a request succeeds but returns no artworks.
//

import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        ContentUnavailableView {
            Label(Strings.Empty.title, systemImage: "magnifyingglass")
        } description: {
            Text(Strings.Empty.message)
        }
    }
}

#Preview {
    EmptyStateView()
}
