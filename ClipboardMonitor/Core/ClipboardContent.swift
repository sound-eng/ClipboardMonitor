//
//  ClipboardContent.swift
//  ClipboardMonitor
//

import Foundation

/// Describes a content in a Pasteboard.
/// Has every content type we support, plus, unknown type (something we do not support, but it pops up).
/// Carries the contents data so we can parse the appropriate content item (Image, text, color) later.
///
enum ClipboardContent {
    case url(URL)
    case image(Data)
    case plainText(String, String.Encoding)
    case color(Data)

    /// Everything that doesn't fall into any known category above.
    case unknown(RawRepresentation)
}

extension ClipboardContent: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .url(let url):
            return "URL: \(url)"
        case .image(let data):
            return "Image (\(data.count) bytes)"
        case .plainText(let text, let encoding):
            return "Plain Text: \(text) (Encoding: \(encoding))"
        case .color(let data):
            return "Color (\(data.count) bytes)"
        case .unknown(let rawRepresentation):
            return "Unknown: \(rawRepresentation)"
        }
    }
}
