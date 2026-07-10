//
//  ClipboardInspector.swift
//  ClipboardMonitor
//

import Foundation
import UniformTypeIdentifiers

/// All inspectors conform to this protocol
/// Inspector is a struct responsible for inspecting the incoming raw pasteboard representations and turning them into specific contents
///
protocol ClipboardInspector {
    var supportedTypes: Set<UTType> { get }
    var priority: Int { get }
    func inspect(_ representation: RawRepresentation) -> ClipboardContent?
}

extension ClipboardInspector {
    var priority: Int { 0 }
}

/// URL type inspector
///
struct URLClipboardInspector: ClipboardInspector {
    let priority: Int = 0
    var supportedTypes: Set<UTType> = [.url, .fileURL]

    func inspect(_ representation: RawRepresentation) -> ClipboardContent? {
        guard let string = String(data: representation.data, encoding: .utf8),
              let url = URL(string: string) else { return nil }
        return .url(url)
    }
}
/// Plain text type inspector
///
struct PlainTextInspector: ClipboardInspector {
    let priority: Int = 1
    var supportedTypes: Set<UTType> = [.text, .plainText, .utf8PlainText, .utf16PlainText, .utf16ExternalPlainText]

    private let typeEncodingMap: [UTType: String.Encoding] = [
        .plainText: String.Encoding.utf8,
        .utf8PlainText: String.Encoding.utf8,
        .utf16PlainText: String.Encoding.utf16,
        .utf16ExternalPlainText: String.Encoding.utf16BigEndian,
        .text: String.Encoding.utf8
    ]

    func inspect(_ representation: RawRepresentation) -> ClipboardContent? {
        guard let type = representation.type, let encoding = typeEncodingMap[type] else { return nil }
        guard let string = String(data: representation.data, encoding: encoding) else { return nil }
        print("Plain Text UTType: \(type)")
        return .plainText(string, encoding)
    }
}

/// Image type inspector
///
struct ImageClipboardInspector: ClipboardInspector {
    let priority: Int = 2
    var supportedTypes: Set<UTType> = [.png, .jpeg]

    func inspect(_ representation: RawRepresentation) -> ClipboardContent? {
        return .image(representation.data)
    }
}

/// Color type inspector
///
struct ColorClipboardInspector: ClipboardInspector {
    let priority: Int = 3
    let supportedTypes: Set<UTType> = [.appleColor]

    func inspect(_ representation: RawRepresentation) -> ClipboardContent? {
        return .color(representation.data)
    }
}

//struct HexColorTextInspector: ClipboardInspector {
//    let supportedTypes: Set<UTType> = [.plainText]
//    let priority = 5   // lower than ColorInspector, higher than PlainTextInspector
//
//    func inspect(_ representation: RawRepresentation) -> ClipboardContent? {
//        guard let string = String(data: representation.data, encoding: .utf8),
//              let color = NSColor(hexString: string.trimmingCharacters(in: .whitespaces))
//        else { return nil }
//        return .color(color)
//    }
//}
