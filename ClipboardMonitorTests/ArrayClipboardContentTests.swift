//
//  ArrayClipboardContentTests.swift
//  ClipboardMonitorTests
//

import XCTest
import UniformTypeIdentifiers
@testable import ClipboardMonitor

final class ArrayClipboardContentTests: XCTestCase {

    func test_primary_prefersKnownOverUnknown() {
        let unknownRep = TestFixtures.unknownRepresentation()
        let contents: [ClipboardContent] = [
            .unknown(unknownRep),
            .plainText("Hello", .utf8),
            .unknown(unknownRep)
        ]

        let primary = contents.primary

        if case .plainText(let text, _) = primary {
            XCTAssertEqual(text, "Hello")
        } else {
            XCTFail("Expected .plainText as primary, got: \(String(describing: primary))")
        }
    }

    func test_primary_returnsFirstKnown() {
        let contents: [ClipboardContent] = [
            .url(raw: "https://example.com", parsed: URL(string: "https://example.com")),
            .plainText("text", .utf8)
        ]

        let primary = contents.primary

        if case .url(let raw, _) = primary {
            XCTAssertEqual(raw, "https://example.com")
        } else {
            XCTFail("Expected .url as primary, got: \(String(describing: primary))")
        }
    }

    func test_primary_allUnknown_returnsFirst() {
        let rep1 = TestFixtures.unknownRepresentation(rawType: "type.a")
        let rep2 = TestFixtures.unknownRepresentation(rawType: "type.b")
        let contents: [ClipboardContent] = [.unknown(rep1), .unknown(rep2)]

        let primary = contents.primary

        if case .unknown(let raw) = primary {
            XCTAssertEqual(raw.rawType, "type.a")
        } else {
            XCTFail("Expected .unknown as primary, got: \(String(describing: primary))")
        }
    }

    func test_primary_empty_returnsNil() {
        let contents: [ClipboardContent] = []

        XCTAssertNil(contents.primary, "Expected nil for empty array")
    }
}
