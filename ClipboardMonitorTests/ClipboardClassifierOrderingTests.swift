//
//  ClipboardClassifierOrderingTests.swift
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

final class ClipboardClassifierOrderingTests: XCTestCase {
    private let classifier = ClipboardClassifier.default

    func test_primaryRepresentation_prefersRichTextOverPlainText() throws {
        let text = TestFixtures.representation(type: .utf8PlainText, string: "Hello")
        let ns = NSAttributedString(string: "Hello")
        let rtfData = try ns.data(
            from: NSRange(location: 0, length: ns.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
        let rtf = TestFixtures.representation(type: .rtf, data: rtfData)

        // Both supported with metadata; RTF has higher inspector priority.
        let primary = classifier.primaryRepresentation(in: [text, rtf])

        XCTAssertEqual(primary?.rawType, UTType.rtf.identifier)
    }

    func test_primaryRepresentation_prefersHTMLOverRichText() throws {
        let html = TestFixtures.representation(type: .html, string: "<b>Hello</b>")
        let ns = NSAttributedString(string: "Hello")
        let rtfData = try ns.data(
            from: NSRange(location: 0, length: ns.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
        let rtf = TestFixtures.representation(type: .rtf, data: rtfData)

        let primary = classifier.primaryRepresentation(in: [rtf, html])

        XCTAssertEqual(primary?.rawType, UTType.html.identifier)
    }

    func test_primaryRepresentation_prefersHigherPriorityAmongMetadataTypes() {
        let text = TestFixtures.representation(type: .utf8PlainText, string: "hello")
        let image = TestFixtures.representation(type: .png, data: Data([0x89, 0x50, 0x4E, 0x47]))
        let unknown = TestFixtures.unknownRepresentation()

        let primary = classifier.primaryRepresentation(in: [text, unknown, image])

        XCTAssertEqual(primary?.rawType, UTType.png.identifier)
    }

    func test_orderedRepresentations_byPriorityThenUnknown() {
        let text = TestFixtures.representation(type: .utf8PlainText, string: "hello")
        let url = TestFixtures.representation(type: .url, string: "https://example.com")
        let unknown = TestFixtures.unknownRepresentation()
        let image = TestFixtures.representation(type: .png, data: Data([0x89, 0x50, 0x4E, 0x47]))

        let ordered = classifier.orderedRepresentations([unknown, text, url, image])

        // All three known types expose metadata; order is inspector priority.
        XCTAssertEqual(
            ordered.map(\.rawType),
            [
                UTType.png.identifier,
                UTType.utf8PlainText.identifier,
                UTType.url.identifier,
                unknown.rawType
            ]
        )
    }

    func test_primaryRepresentation_fallsBackToFirstWhenAllUnknown() {
        let a = TestFixtures.unknownRepresentation(rawType: "type.a")
        let b = TestFixtures.unknownRepresentation(rawType: "type.b")

        let primary = classifier.primaryRepresentation(in: [a, b])

        XCTAssertEqual(primary?.rawType, "type.a")
    }
}
