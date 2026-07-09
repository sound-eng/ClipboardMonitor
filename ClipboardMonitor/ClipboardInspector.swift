#if os(macOS)
import AppKit
#else
import UIKit
#endif
import UniformTypeIdentifiers


protocol ClipboardInspector {
    var supportedTypes: Set<UTType> { get }
    var priority: Int { get }
    func inspect(_ representation: RawRepresentation) -> ClipboardContent?
}

extension ClipboardInspector {
    var priority: Int { 0 }
}

extension Array where Element == ClipboardInspector {
    static var all: [ClipboardInspector] {
        [
            URLClipboardInspector(),
            PlainTextInspector(),
            ImageClipboardInspector(),
            ColorClipboardInspector()
        ]
    }
}

struct URLClipboardInspector: ClipboardInspector {
    let priority: Int = 0
    var supportedTypes: Set<UTType> { [.url, .fileURL] }

    func inspect(_ representation: RawRepresentation) -> ClipboardContent? {
        guard let string = String(data: representation.data, encoding: .utf8),
              let url = URL(string: string) else { return nil }
        return .url(url)
    }
}

struct PlainTextInspector: ClipboardInspector {
    let priority: Int = 1
    var supportedTypes: Set<UTType> { [.text, .plainText, .utf8PlainText, .utf16PlainText, .utf16ExternalPlainText] }

    let typeEncodingMap: [UTType: String.Encoding] = [
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

struct ImageClipboardInspector: ClipboardInspector {
    let priority: Int = 2
    var supportedTypes: Set<UTType> { [.png, .jpeg] }

    func inspect(_ representation: RawRepresentation) -> ClipboardContent? {
        guard let image = PlatformImage(data: representation.data) else { return nil }
        return .image(image)
    }
}

struct ColorClipboardInspector: ClipboardInspector {
    let priority: Int = 3
    let supportedTypes: Set<UTType> = [.appleColor]

    func inspect(_ representation: RawRepresentation) -> ClipboardContent? {
        #if os(macOS)
        guard let color = try? NSKeyedUnarchiver.unarchivedObject(
                ofClass: NSColor.self, from: representation.data
              ) else { return nil }
        #else
        guard let color = try? NSKeyedUnarchiver.unarchivedObject(
                ofClass: UIColor.self, from: representation.data
              ) else { return nil }
        #endif
        return .color(color)
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
