//
//  ClipboardClassifierTests.swift
//  ClipboardMonitorTests
//

import XCTest
import UniformTypeIdentifiers
@testable import ClipboardMonitor

final class ClipboardClassifierTests: XCTestCase {

    // Use the default classifier for most tests — it packs all four inspectors.
    private let classifier = ClipboardClassifier.default

    // MARK: - 1.1 Basic classification

    func test_classify_plainText_utf8() {
        let rep = TestFixtures.representation(type: .utf8PlainText, string: "Hello, world!")
        let item = TestFixtures.item(rep)

        let contents = classifier.classify(item)

        XCTAssertTrue(contents.contains(where: {
            if case .plainText(let text, let encoding) = $0 {
                return text == "Hello, world!" && encoding == .utf8
            }
            return false
        }), "Expected .plainText with UTF-8 encoding, got: \(contents)")
    }

    func test_classify_plainText_utf16() {
        let text = "Привет"
        let data = text.data(using: .utf16)!
        let rep = TestFixtures.representation(type: .utf16PlainText, data: data)
        let item = TestFixtures.item(rep)

        let contents = classifier.classify(item)

        XCTAssertTrue(contents.contains(where: {
            if case .plainText(let decoded, let encoding) = $0 {
                return decoded == text && encoding == .utf16
            }
            return false
        }), "Expected .plainText with UTF-16 encoding, got: \(contents)")
    }

    func test_classify_url() {
        let urlString = "https://example.com/page?q=1"
        let rep = TestFixtures.representation(type: .url, string: urlString)
        let item = TestFixtures.item(rep)

        let contents = classifier.classify(item)

        XCTAssertTrue(contents.contains(where: {
            if case .url(let raw, let parsed) = $0 {
                return raw == urlString && parsed?.absoluteString == urlString
            }
            return false
        }), "Expected .url, got: \(contents)")
    }

    func test_classify_fileURL() {
        let fileURLString = "file:///Users/test/document.txt"
        let rep = TestFixtures.representation(type: .fileURL, string: fileURLString)
        let item = TestFixtures.item(rep)

        let contents = classifier.classify(item)

        XCTAssertTrue(contents.contains(where: {
            if case .url(let raw, let parsed) = $0 {
                return raw == fileURLString && parsed?.isFileURL == true
            }
            return false
        }), "Expected .url with isFileURL, got: \(contents)")
    }

    func test_classify_image_png() {
        let fakeData = Data([0x89, 0x50, 0x4E, 0x47]) // PNG magic bytes
        let rep = TestFixtures.representation(type: .png, data: fakeData)
        let item = TestFixtures.item(rep)

        let contents = classifier.classify(item)

        XCTAssertTrue(contents.contains(where: {
            if case .image(let data) = $0 {
                return data == fakeData
            }
            return false
        }), "Expected .image with matching data, got: \(contents)")
    }

    func test_classify_image_jpeg() {
        let fakeData = Data([0xFF, 0xD8, 0xFF]) // JPEG magic bytes
        let rep = TestFixtures.representation(type: .jpeg, data: fakeData)
        let item = TestFixtures.item(rep)

        let contents = classifier.classify(item)

        XCTAssertTrue(contents.contains(where: {
            if case .image(let data) = $0 {
                return data == fakeData
            }
            return false
        }), "Expected .image with matching data, got: \(contents)")
    }

    func test_classify_color() {
        let colorData = Data([0x01, 0x02, 0x03, 0x04])
        let rep = TestFixtures.representation(type: .appleColor, data: colorData)
        let item = TestFixtures.item(rep)

        let contents = classifier.classify(item)

        XCTAssertTrue(contents.contains(where: {
            if case .color(let data) = $0 {
                return data == colorData
            }
            return false
        }), "Expected .color with matching data, got: \(contents)")
    }

    // MARK: - 1.2 Unknown / fallback

    func test_classify_unknownType_returnsUnknown() {
        let rep = TestFixtures.unknownRepresentation()
        let item = TestFixtures.item(rep)

        let contents = classifier.classify(item)

        XCTAssertEqual(contents.count, 1)
        if case .unknown(let raw) = contents.first {
            XCTAssertEqual(raw.rawType, "com.example.unknown-type")
        } else {
            XCTFail("Expected .unknown, got: \(contents)")
        }
    }

    func test_classify_emptyItem_returnsEmpty() {
        let item = TestFixtures.item([])

        let contents = classifier.classify(item)

        XCTAssertTrue(contents.isEmpty, "Expected empty result for empty item, got: \(contents)")
    }

    // MARK: - 1.3 Don't hide representations
    //
    // The product is a clipboard debugger (Finder/Xcode-like): every advertised
    // pasteboard type stays independently visible. A "richer" sibling must never
    // suppress plain text / unknown / other types — that's how you answer
    // "why did my app paste plain text instead of HTML?"

    func test_classify_keepsAllSiblingRepresentations() {
        let urlRep = TestFixtures.representation(type: .url, string: "https://example.com")
        let textRep = TestFixtures.representation(type: .utf8PlainText, string: "Example")
        let imageRep = TestFixtures.representation(type: .png, data: Data([0x89, 0x50, 0x4E, 0x47]))
        let item = TestFixtures.item([urlRep, textRep, imageRep])

        let contents = classifier.classify(item)

        XCTAssertEqual(contents.count, 3, "Expected one content per representation, got: \(contents)")
        XCTAssertTrue(contents.contains(where: { if case .url = $0 { return true }; return false }),
                      "URL representation must stay visible")
        XCTAssertTrue(contents.contains(where: { if case .plainText = $0 { return true }; return false }),
                      "Plain text representation must stay visible alongside richer siblings")
        XCTAssertTrue(contents.contains(where: { if case .image = $0 { return true }; return false }),
                      "Image representation must stay visible")
    }

    func test_classify_richerSiblingDoesNotHidePlainText() {
        // Classic pasteboard shape: URL + plain-text fallback. Both must remain
        // independently inspectable — never collapse to "just the URL."
        let urlRep = TestFixtures.representation(type: .url, string: "https://example.com")
        let textRep = TestFixtures.representation(type: .utf8PlainText, string: "https://example.com")
        let item = TestFixtures.item([urlRep, textRep])

        let contents = classifier.classify(item)

        let hasURL = contents.contains(where: { if case .url = $0 { return true }; return false })
        let hasText = contents.contains(where: { if case .plainText = $0 { return true }; return false })

        XCTAssertTrue(hasURL, "Expected .url content")
        XCTAssertTrue(hasText, "Expected .plainText content — do not hide the text fallback")
    }

    func test_classify_mixedKnownAndUnknown() {
        let knownRep = TestFixtures.representation(type: .png, data: Data([0x89]))
        let unknownRep = TestFixtures.unknownRepresentation()
        let item = TestFixtures.item([knownRep, unknownRep])

        let contents = classifier.classify(item)

        let hasImage = contents.contains(where: { if case .image = $0 { return true }; return false })
        let hasUnknown = contents.contains(where: { if case .unknown = $0 { return true }; return false })

        XCTAssertTrue(hasImage, "Expected a .image content")
        XCTAssertTrue(hasUnknown, "Expected an .unknown content — unknown types stay listed")
    }
}
