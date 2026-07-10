//
//  ClipboardClassifierOrderingTests.swift
//  ClipboardMonitorTests
//

import XCTest
import UniformTypeIdentifiers
@testable import ClipboardMonitor

final class ClipboardClassifierOrderingTests: XCTestCase {
    private let classifier = ClipboardClassifier.default

    func test_primaryRepresentation_prefersMetadataBearingType() {
        let text = TestFixtures.representation(type: .utf8PlainText, string: "https://example.com")
        let url = TestFixtures.representation(type: .url, string: "https://example.com")

        // Text has higher inspector priority, but URL exposes Metadata — URL wins.
        let primary = classifier.primaryRepresentation(in: [text, url])

        XCTAssertEqual(primary?.rawType, UTType.url.identifier)
    }

    func test_primaryRepresentation_prefersHigherPriorityAmongMetadataTypes() {
        let text = TestFixtures.representation(type: .utf8PlainText, string: "hello")
        let image = TestFixtures.representation(type: .png, data: Data([0x89, 0x50, 0x4E, 0x47]))
        let unknown = TestFixtures.unknownRepresentation()

        let primary = classifier.primaryRepresentation(in: [text, unknown, image])

        XCTAssertEqual(primary?.rawType, UTType.png.identifier)
    }

    func test_orderedRepresentations_metadataFirstThenPriorityThenUnknown() {
        let text = TestFixtures.representation(type: .utf8PlainText, string: "hello")
        let url = TestFixtures.representation(type: .url, string: "https://example.com")
        let unknown = TestFixtures.unknownRepresentation()
        let image = TestFixtures.representation(type: .png, data: Data([0x89, 0x50, 0x4E, 0x47]))

        let ordered = classifier.orderedRepresentations([unknown, text, url, image])

        // Image + URL have metadata (image higher priority); text does not; unknown last.
        XCTAssertEqual(
            ordered.map(\.rawType),
            [
                UTType.png.identifier,
                UTType.url.identifier,
                UTType.utf8PlainText.identifier,
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
