//
//  ViewState.swift
//  Artwork
//
//  Created by Dima Starodubtsev on 6/24/26.
//

import Foundation

/// The mutually-exclusive states the list screen can be in.
///
/// Modeling these as one enum (rather than separate `isLoading` / `error`
/// booleans) makes invalid combinations unrepresentable — the UI switches over
/// exactly one case and can never show, e.g., a spinner and an error at once.
///
/// Note: this drives the *full-screen* state. Loading additional pages during
/// infinite scroll is tracked separately (`isLoadingNextPage`) so it shows a
/// footer spinner without replacing the already-visible list.
enum ViewState: Equatable {
    /// Initial load in progress, nothing to show yet.
    case loading
    /// At least one artwork is available.
    case loaded
    /// The request succeeded but returned no artworks.
    case empty
    /// The request failed; carries a user-facing message.
    case error(String)
}
