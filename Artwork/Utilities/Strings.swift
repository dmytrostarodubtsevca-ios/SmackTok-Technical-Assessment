//
//  Strings.swift
//  Artwork
//
//  Created by Dima Starodubtsev on 6/24/26.
//
//  Centralized user-facing copy. Keeping strings in one namespace avoids
//  scattering literals through the code and gives a single place to adjust
//  wording (or later, to swap in NSLocalizedString for localization).
//

import Foundation

enum Strings {

    /// Fallbacks for missing artwork metadata.
    enum Artwork {
        static let untitled = "Untitled"
        static let unknownArtist = "Unknown artist"
        static let unknownDate = "Date unknown"
    }

    enum List {
        static let title = "Artworks"
        static let searchPrompt = "Search artworks"
    }

    enum Loading {
        static let message = "Loading artworks…"
    }

    enum Empty {
        static let title = "No artworks found"
        static let message = "Try a different search."
    }

    enum Error {
        static let title = "Something went wrong"
        static let retry = "Try Again"
    }

    enum Detail {
        static let type = "Type"
        static let medium = "Medium"
        static let dimensions = "Dimensions"
        static let origin = "Origin"
        static let department = "Department"
        static let credit = "Credit"
        static let about = "About:"
        static let detailsUnavailable = "Couldn't load more details."
    }
}
