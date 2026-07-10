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
    /// URL-typed pasteboard payload.
    /// - `raw`: the exact UTF-8 string from the pasteboard (display fidelity).
    /// - `parsed`: Foundation's parse of that string, when it succeeds.
    case url(raw: String, parsed: URL?)
    case image(Data)
    case plainText(String, String.Encoding)
    case richText(AttributedString)
    /// Decoded HTML / XHTML markup (source string; preview renders separately).
    case html(String)
    case color(Data)

    /// Everything that doesn't fall into any known category above.
    case unknown(RawRepresentation)
}

extension ClipboardContent: CustomDebugStringConvertible {
    /// Short user-facing title for lists (sidebar, etc.).
    var displayTitle: String {
        switch self {
        case .url: "URL"
        case .image: "Image"
        case .plainText: "Plain text"
        case .richText: "Rich text"
        case .html: "HTML"
        case .color: "Color"
        case .unknown(let representation):
            Self.humanizedTypeName(representation.rawType)
        }
    }

    var debugDescription: String {
        switch self {
        case .url(let raw, let parsed):
            if let parsed, parsed.absoluteString != raw {
                return "URL: \(raw) (parsed: \(parsed.absoluteString))"
            }
            return "URL: \(raw)"
        case .image(let data):
            return "Image (\(data.count) bytes)"
        case .plainText(let text, let encoding):
            return "Plain Text: \(text) (Encoding: \(encoding))"
        case .richText(let attributedString):
            return "Rich text: \(attributedString)"
        case .html(let source):
            return "HTML: \(source)"
        case .color(let data):
            return "Color (\(data.count) bytes)"
        case .unknown(let rawRepresentation):
            return "Unknown: \(rawRepresentation)"
        }
    }

    /// Turn a UTI like `public.html` / `com.apple.flat-rtf` into a short label.
    private static func humanizedTypeName(_ rawType: String) -> String {
        let leaf = rawType.split(separator: ".").last.map(String.init) ?? rawType
        guard !leaf.isEmpty else { return "Unknown" }
        // Keep short acronyms (rtf, html, pdf) uppercase; otherwise capitalize.
        if leaf.count <= 4, leaf.allSatisfy(\.isLetter) {
            return leaf.uppercased()
        }
        return leaf.replacingOccurrences(of: "-", with: " ").capitalized
    }
}
