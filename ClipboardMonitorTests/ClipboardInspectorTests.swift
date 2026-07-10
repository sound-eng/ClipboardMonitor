//
//  ClipboardInspectorTests.swift
//  ClipboardMonitorTests
//

import XCTest
import UniformTypeIdentifiers
@testable import ClipboardMonitor

#if canImport(AppKit)
import AppKit
#elseif canImport(UIKit)
import UIKit
#endif

// MARK: - URLClipboardInspector Tests

final class URLClipboardInspectorTests: XCTestCase {

    private let inspector = URLClipboardInspector()

    func test_validURL_returnsURL() {
        let raw = "https://example.com/path?q=1"
        let rep = TestFixtures.representation(type: .url, string: raw)

        let result = inspector.inspect(rep)

        if case .url(let returnedRaw, let parsed) = result {
            XCTAssertEqual(returnedRaw, raw)
            XCTAssertEqual(parsed?.absoluteString, raw)
        } else {
            XCTFail("Expected .url, got: \(String(describing: result))")
        }
    }

    func test_nonCanonicalURL_preservesRawString() {
        // Pasteboard can advertise .url with a payload that isn't a clean absolute URL.
        // We still surface it as URL-typed content and keep the original bytes as text.
        let raw = "not a valid url"
        let rep = TestFixtures.representation(type: .url, string: raw)

        let result = inspector.inspect(rep)

        if case .url(let returnedRaw, let parsed) = result {
            XCTAssertEqual(returnedRaw, raw, "Raw pasteboard string must be preserved for display")
            // Foundation may percent-encode; parsed is optional convenience, not the display source.
            if let parsed {
                XCTAssertNotEqual(parsed.absoluteString, raw,
                                  "When Foundation rewrites the string, display should still use raw")
            }
        } else {
            XCTFail("Expected .url for URL-typed pasteboard content, got: \(String(describing: result))")
        }
    }

    func test_emptyData_returnsNil() {
        let rep = TestFixtures.representation(type: .url, data: Data())

        let result = inspector.inspect(rep)

        XCTAssertNil(result, "Expected nil for empty data")
    }
}

// MARK: - PlainTextInspector Tests

final class PlainTextInspectorTests: XCTestCase {

    private let inspector = PlainTextInspector()

    func test_utf8_decodesCorrectly() {
        let text = "Hello, world! 🌍"
        let rep = TestFixtures.representation(type: .utf8PlainText, string: text)

        let result = inspector.inspect(rep)

        if case .plainText(let decoded, let encoding) = result {
            XCTAssertEqual(decoded, text)
            XCTAssertEqual(encoding, .utf8)
        } else {
            XCTFail("Expected .plainText, got: \(String(describing: result))")
        }
    }

    func test_utf16_decodesCorrectly() {
        let text = "UTF-16 text"
        let data = text.data(using: .utf16)!
        let rep = TestFixtures.representation(type: .utf16PlainText, data: data)

        let result = inspector.inspect(rep)

        if case .plainText(let decoded, let encoding) = result {
            XCTAssertEqual(decoded, text)
            XCTAssertEqual(encoding, .utf16)
        } else {
            XCTFail("Expected .plainText, got: \(String(describing: result))")
        }
    }

    func test_utf16BigEndian_decodesCorrectly() {
        let text = "Big Endian"
        let data = text.data(using: .utf16BigEndian)!
        let rep = TestFixtures.representation(type: .utf16ExternalPlainText, data: data)

        let result = inspector.inspect(rep)

        if case .plainText(let decoded, let encoding) = result {
            XCTAssertEqual(decoded, text)
            XCTAssertEqual(encoding, .utf16BigEndian)
        } else {
            XCTFail("Expected .plainText, got: \(String(describing: result))")
        }
    }

    func test_utf16External_littleEndianWithoutBOM_doesNotLookChinese() {
        // Real pasteboards often store LE code units in the "external" UTI with no BOM.
        // Decoding that as BE yields CJK-looking garbage (e.g. 䠀攀…).
        let text = "Hello"
        let data = text.data(using: .utf16LittleEndian)!
        let rep = TestFixtures.representation(type: .utf16ExternalPlainText, data: data)

        let result = inspector.inspect(rep)

        if case .plainText(let decoded, let encoding) = result {
            XCTAssertEqual(decoded, text)
            XCTAssertEqual(encoding, .utf16LittleEndian)
        } else {
            XCTFail("Expected .plainText, got: \(String(describing: result))")
        }
    }

    func test_utf16External_respectsBOM() {
        let text = "Hello"
        let data = text.data(using: .utf16)!
        let rep = TestFixtures.representation(type: .utf16ExternalPlainText, data: data)

        let result = inspector.inspect(rep)

        if case .plainText(let decoded, _) = result {
            XCTAssertEqual(decoded, text)
        } else {
            XCTFail("Expected .plainText, got: \(String(describing: result))")
        }
    }

    func test_unsupportedType_returnsNil() {
        // .png is not in the PlainTextInspector's supported types
        let rep = TestFixtures.representation(type: .png, data: Data([0x89]))

        let result = inspector.inspect(rep)

        XCTAssertNil(result, "Expected nil for unsupported type")
    }

    func test_corruptData_returnsNil() {
        // Invalid UTF-8 sequence: a continuation byte without a leading byte
        let corruptData = Data([0x80, 0x81, 0x82, 0x83])
        let rep = TestFixtures.representation(type: .utf8PlainText, data: corruptData)

        let result = inspector.inspect(rep)

        XCTAssertNil(result, "Expected nil for corrupt UTF-8 data")
    }
}

// MARK: - ImageClipboardInspector Tests

final class ImageClipboardInspectorTests: XCTestCase {

    private let inspector = ImageClipboardInspector()

    func test_pngData_returnsImage() {
        let pngData = Data([0x89, 0x50, 0x4E, 0x47])
        let rep = TestFixtures.representation(type: .png, data: pngData)

        let result = inspector.inspect(rep)

        if case .image(let data) = result {
            XCTAssertEqual(data, pngData)
        } else {
            XCTFail("Expected .image, got: \(String(describing: result))")
        }
    }

    func test_jpegData_returnsImage() {
        let jpegData = Data([0xFF, 0xD8, 0xFF, 0xE0])
        let rep = TestFixtures.representation(type: .jpeg, data: jpegData)

        let result = inspector.inspect(rep)

        if case .image(let data) = result {
            XCTAssertEqual(data, jpegData)
        } else {
            XCTFail("Expected .image, got: \(String(describing: result))")
        }
    }
}

// MARK: - RichTextInspector Tests

final class RichTextInspectorTests: XCTestCase {

    private let inspector = RichTextInspector()

    func test_rtf_returnsRichText() throws {
        let ns = NSAttributedString(string: "Hello RTF")
        let data = try ns.data(
            from: NSRange(location: 0, length: ns.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
        let rep = TestFixtures.representation(type: .rtf, data: data)

        let result = inspector.inspect(rep)

        guard case .richText(let attributed) = result else {
            return XCTFail("Expected .richText, got: \(String(describing: result))")
        }
        XCTAssertEqual(String(attributed.characters), "Hello RTF")
    }

    func test_flatRTF_returnsRichText() throws {
        let ns = NSAttributedString(string: "Flat")
        let data = try ns.data(
            from: NSRange(location: 0, length: ns.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
        let rep = TestFixtures.representation(type: .flatRTF, data: data)

        let result = inspector.inspect(rep)

        guard case .richText(let attributed) = result else {
            return XCTFail("Expected .richText, got: \(String(describing: result))")
        }
        XCTAssertEqual(String(attributed.characters), "Flat")
    }

    func test_emptyData_returnsNil() {
        let rep = TestFixtures.representation(type: .rtf, data: Data())
        XCTAssertNil(inspector.inspect(rep))
    }

    func test_corruptData_returnsNil() {
        let rep = TestFixtures.representation(type: .rtf, data: Data([0x00, 0x01, 0x02]))
        XCTAssertNil(inspector.inspect(rep))
    }
}

// MARK: - ColorClipboardInspector Tests

final class ColorClipboardInspectorTests: XCTestCase {

    private let inspector = ColorClipboardInspector()

    func test_colorData_returnsColor() {
        let colorData = Data([0x01, 0x02, 0x03, 0x04])
        let rep = TestFixtures.representation(type: .appleColor, data: colorData)

        let result = inspector.inspect(rep)

        if case .color(let data) = result {
            XCTAssertEqual(data, colorData)
        } else {
            XCTFail("Expected .color, got: \(String(describing: result))")
        }
    }
}
