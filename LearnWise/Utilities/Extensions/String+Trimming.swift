import Foundation

extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Trims the ends and collapses runs of spaces/newlines into a single space.
    var collapsingWhitespace: String {
        split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    /// `nil` when the string is empty or only whitespace.
    var nilIfBlank: String? {
        trimmed.isEmpty ? nil : self
    }
}
