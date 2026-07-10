//
//  ClipboardInspector.swift
//  ClipboardMonitor
//

import Foundation
import UniformTypeIdentifiers

/// Turns a raw pasteboard representation into typed `ClipboardContent`.
///
protocol ClipboardInspector {
    /// Human-readable name shown in the Overview facet.
    var displayName: String { get }

    var supportedTypes: Set<UTType> { get }
    var priority: Int { get }

    func inspect(_ representation: RawRepresentation) -> ClipboardContent?

    /// Facets this inspector can meaningfully show for a representation.
    func supportedFacets(for representation: RawRepresentation) -> [InspectorFacet]
}

extension ClipboardInspector {
    var priority: Int { 0 }

    /// Default facets: summary + raw bytes. Concrete inspectors override to add source/metadata.
    func supportedFacets(for representation: RawRepresentation) -> [InspectorFacet] {
        [.overview, .hex]
    }
}

// MARK: - URL

/// URL type inspector.
///
struct URLClipboardInspector: ClipboardInspector {
    let displayName = "URL Inspector"
    let priority: Int = 0
    var supportedTypes: Set<UTType> = [.url, .fileURL]

    func inspect(_ representation: RawRepresentation) -> ClipboardContent? {
        // Keep URL-typed payloads even when Foundation cannot parse them —
        // the monitor should still surface the declared type + raw text.
        guard let string = String(data: representation.data, encoding: .utf8),
              string.isEmpty == false else { return nil }
        return .url(raw: string, parsed: URL(string: string))
    }

    func supportedFacets(for representation: RawRepresentation) -> [InspectorFacet] {
        [.overview, .metadata, .hex]
    }
}

// MARK: - Plain text

/// Plain text type inspector.
///
struct PlainTextInspector: ClipboardInspector {
    let displayName = "Plain Text Inspector"
    let priority: Int = 1
    var supportedTypes: Set<UTType> = [.text, .plainText, .utf8PlainText, .utf16PlainText, .utf16ExternalPlainText]

    private let typeEncodingMap: [UTType: String.Encoding] = [
        .plainText: .utf8,
        .utf8PlainText: .utf8,
        .utf16PlainText: .utf16,
        .utf16ExternalPlainText: .utf16BigEndian,
        .text: .utf8
    ]

    func inspect(_ representation: RawRepresentation) -> ClipboardContent? {
        guard let type = representation.type, let encoding = typeEncodingMap[type] else { return nil }
        guard let string = String(data: representation.data, encoding: encoding) else { return nil }
        return .plainText(string, encoding)
    }

    func supportedFacets(for representation: RawRepresentation) -> [InspectorFacet] {
        [.overview, .metadata, .source, .hex]
    }
}

// MARK: - Image

/// Image type inspector.
///
struct ImageClipboardInspector: ClipboardInspector {
    let displayName = "Image Inspector"
    let priority: Int = 2
    var supportedTypes: Set<UTType> = [.png, .jpeg, .exr, .bmp, .tiff, .pdf, .svg]

    func inspect(_ representation: RawRepresentation) -> ClipboardContent? {
        .image(representation.data)
    }

    func supportedFacets(for representation: RawRepresentation) -> [InspectorFacet] {
        [.overview, .metadata]
    }
}

// MARK: - Color

/// Color type inspector.
///
struct ColorClipboardInspector: ClipboardInspector {
    let displayName = "Color Inspector"
    let priority: Int = 3
    let supportedTypes: Set<UTType> = [.appleColor]

    func inspect(_ representation: RawRepresentation) -> ClipboardContent? {
        .color(representation.data)
    }

    func supportedFacets(for representation: RawRepresentation) -> [InspectorFacet] {
        [.overview, .metadata, .hex]
    }
}
