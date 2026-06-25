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
}
