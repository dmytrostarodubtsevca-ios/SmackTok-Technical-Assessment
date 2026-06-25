//
//  LoadingView.swift
//  Artwork
//
//  Created by Dima Starodubtsev on 6/24/26.
//
//  Full-screen loading state shown during the initial fetch.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text(Strings.Loading.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    LoadingView()
}
