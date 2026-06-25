//
//  String+HTML.swift
//  Artwork
//
//  Created by Dima Starodubtsev on 6/24/26.
//
//  Renders the artwork `description` HTML (it arrives wrapped in <p>/<em> tags)
//  into an AttributedString via NSAttributedString's HTML importer, so basic
//  formatting like emphasis is preserved in the detail view.
//

import Foundation
internal import UIKit

extension String {
    /// Parses this HTML string into an `AttributedString`, preserving inline
    /// formatting such as emphasis. Returns `nil` if the string can't be encoded
    /// or the importer fails. Must be called on the main thread.
    var attributedHTML: AttributedString? {
        do {
            guard let data = self.data(using: .unicode) else {
                return nil
            }
            let attributed = try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
            return AttributedString(attributed)
        } catch {
            return nil
        }
    }
}
