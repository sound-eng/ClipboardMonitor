//
//  ClipboardInspector.swift
//  ClipboardMonitor
//

import Foundation
import UniformTypeIdentifiers

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

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

// MARK: - Plain text

/// Plain text type inspector.
///
struct PlainTextInspector: ClipboardInspector {
    let displayName = "Plain Text Inspector"
    let priority: Int = 0
    var supportedTypes: Set<UTType> = [.plainText, .utf8PlainText, .utf16PlainText, .utf16ExternalPlainText]

    func inspect(_ representation: RawRepresentation) -> ClipboardContent? {
        guard let type = representation.type else { return nil }
        guard let (string, encoding) = decode(representation.data, as: type) else { return nil }
        return .plainText(string, encoding)
    }

    func supportedFacets(for representation: RawRepresentation) -> [InspectorFacet] {
        [.overview, .metadata, .source, .hex]
    }

    // MARK: Decoding

    private func decode(_ data: Data, as type: UTType) -> (String, String.Encoding)? {
        switch type {
        case .plainText, .utf8PlainText, .text:
            guard let string = String(data: data, encoding: .utf8) else { return nil }
            return (string, .utf8)
        case .utf16PlainText:
            // Native-order UTF-16 with optional BOM.
            return decodeUTF16(data, externalByteOrder: false)
        case .utf16ExternalPlainText:
            // UTI: BOM if present, otherwise external (big-endian) — but many
            // pasteboard writers put LE with no BOM; sniff null-byte lanes to recover.
            return decodeUTF16(data, externalByteOrder: true)
        default:
            return nil
        }
    }

    private func decodeUTF16(_ data: Data, externalByteOrder: Bool) -> (String, String.Encoding)? {
        if hasUTF16BOM(data), let string = String(data: data, encoding: .utf16) {
            return (string, .utf16)
        }

        let preferred: String.Encoding
        let fallback: String.Encoding
        if let sniffed = sniffedUTF16Endianness(data) {
            preferred = sniffed
            fallback = sniffed == .utf16LittleEndian ? .utf16BigEndian : .utf16LittleEndian
        } else {
            // Spec default: external → BE, native plain → platform `.utf16`.
            preferred = externalByteOrder ? .utf16BigEndian : .utf16
            fallback = externalByteOrder ? .utf16LittleEndian : .utf16BigEndian
        }

        if let string = String(data: data, encoding: preferred) {
            return (string, preferred)
        }
        if let string = String(data: data, encoding: fallback) {
            return (string, fallback)
        }
        return nil
    }

    private func hasUTF16BOM(_ data: Data) -> Bool {
        guard data.count >= 2 else { return false }
        let b0 = data[data.startIndex]
        let b1 = data[data.index(after: data.startIndex)]
        return (b0 == 0xFE && b1 == 0xFF) || (b0 == 0xFF && b1 == 0xFE)
    }

    /// For BOM-less UTF-16, ASCII/Latin text has `00` on one lane of each code unit.
    /// LE: `41 00` (“A”); BE: `00 41`. Wrong endianness turns that into CJK-looking noise.
    private func sniffedUTF16Endianness(_ data: Data) -> String.Encoding? {
        guard data.count >= 4 else { return nil }
        var evenZeros = 0
        var oddZeros = 0
        var offset = data.startIndex
        while data.distance(from: offset, to: data.endIndex) >= 2 {
            if data[offset] == 0 { evenZeros += 1 }
            let next = data.index(after: offset)
            if data[next] == 0 { oddZeros += 1 }
            offset = data.index(offset, offsetBy: 2)
        }
        if oddZeros > evenZeros * 2 { return .utf16LittleEndian }
        if evenZeros > oddZeros * 2 { return .utf16BigEndian }
        return nil
    }
}

// MARK: - URL

/// URL type inspector.
///
struct URLClipboardInspector: ClipboardInspector {
    let displayName = "URL Inspector"
    let priority: Int = 1
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

// MARK: - Rich Text

/// RTF / RTFD inspector — parses pasteboard rich text into `AttributedString`.
///
struct RichTextInspector: ClipboardInspector {
    let displayName = "Rich Text Inspector"
    /// Above plain text so RTF wins when both are present; below image/color.
    let priority: Int = 2
    let supportedTypes: Set<UTType> = [.rtf, .rtfd, .flatRTF, .flatRTFD]

    func inspect(_ representation: RawRepresentation) -> ClipboardContent? {
        guard !representation.data.isEmpty else { return nil }
        let documentType = Self.documentType(for: representation)
        do {
            let nsAttributed = try NSAttributedString(
                data: representation.data,
                options: [.documentType: documentType],
                documentAttributes: nil
            )
            return .richText(AttributedString(nsAttributed))
        } catch {
            return nil
        }
    }

    func supportedFacets(for representation: RawRepresentation) -> [InspectorFacet] {
        [.overview, .source, .metadata, .hex]
    }

    private static func documentType(for representation: RawRepresentation) -> NSAttributedString.DocumentType {
        let raw = representation.rawType
        if representation.type == .rtfd
            || representation.type == .flatRTFD
            || raw.contains("rtfd") {
            return .rtfd
        }
        return .rtf
    }
}

// MARK: - HTML

/// HTML / XHTML inspector — keeps the markup source for Source/Metadata and Overview preview.
///
struct HTMLClipboardInspector: ClipboardInspector {
    let displayName = "HTML Inspector"
    /// Above rich/plain text so browser HTML wins as primary when siblings are present.
    let priority: Int = 3
    let supportedTypes: Set<UTType> = [.html]

    func inspect(_ representation: RawRepresentation) -> ClipboardContent? {
        guard let string = String(data: representation.data, encoding: .utf8),
              string.isEmpty == false else { return nil }
        return .html(string)
    }

    func supportedFacets(for representation: RawRepresentation) -> [InspectorFacet] {
        [.overview, .source, .metadata, .hex]
    }
}

// MARK: - Image

/// Image type inspector.
///
struct ImageClipboardInspector: ClipboardInspector {
    let displayName = "Image Inspector"
    let priority: Int = 4
    var supportedTypes: Set<UTType> = [.png, .jpeg, .exr, .bmp, .tiff, .pdf, .svg]

    func inspect(_ representation: RawRepresentation) -> ClipboardContent? {
        .image(representation.data)
    }

    func supportedFacets(for representation: RawRepresentation) -> [InspectorFacet] {
        [.overview, .metadata, .hex]
    }
}

// MARK: - Color

/// Color type inspector.
///
struct ColorClipboardInspector: ClipboardInspector {
    let displayName = "Color Inspector"
    let priority: Int = 5
    let supportedTypes: Set<UTType> = [.appleColor]

    func inspect(_ representation: RawRepresentation) -> ClipboardContent? {
        .color(representation.data)
    }

    func supportedFacets(for representation: RawRepresentation) -> [InspectorFacet] {
        [.overview, .metadata, .hex]
    }
}
