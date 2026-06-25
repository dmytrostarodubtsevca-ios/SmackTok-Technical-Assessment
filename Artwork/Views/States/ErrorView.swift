//
//  ErrorView.swift
//  Artwork
//
//  Created by Dima Starodubtsev on 6/24/26.
//
//  Full-screen error state with a retry action. The message is supplied by the
//  view model (mapped from APIError); retry is a closure the caller wires to a
//  reload.
//

import SwiftUI

struct ErrorView: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(Strings.Error.title, systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button(Strings.Error.retry, action: retry)
                .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    ErrorView(message: APIError.transport.message) {}
}
