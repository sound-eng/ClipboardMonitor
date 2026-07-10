//
//  DataTypeTests.swift
//  ClipboardMonitorTests
//

import XCTest
import UniformTypeIdentifiers
@testable import ClipboardMonitor

// MARK: - RawRepresentation Tests

final class RawRepresentationTests: XCTestCase {

    func test_debugDescription_includesTypeAndSize() {
        let rep = TestFixtures.representation(type: .plainText, string: "Hello")

        let description = rep.debugDescription

        XCTAssertTrue(description.contains("public.plain-text"),
                      "Expected debug description to contain the raw type identifier")
        XCTAssertTrue(description.contains("5"),
                      "Expected debug description to contain data byte count")
    }
}

// MARK: - ClipboardContent Debug Description Tests

final class ClipboardContentDebugDescriptionTests: XCTestCase {

    func test_debugDescription_url() {
        let content = ClipboardContent.url(raw: "https://example.com", parsed: URL(string: "https://example.com"))

        let desc = content.debugDescription

        XCTAssertTrue(desc.contains("https://example.com"),
                      "Expected URL in debug description, got: \(desc)")
    }

    func test_debugDescription_url_preservesRawWhenParsedDiffers() {
        let raw = "not a valid url"
        let content = ClipboardContent.url(raw: raw, parsed: URL(string: raw))

        let desc = content.debugDescription

        XCTAssertTrue(desc.contains(raw),
                      "Expected raw pasteboard string in debug description, got: \(desc)")
    }

    func test_debugDescription_image() {
        let content = ClipboardContent.image(Data(repeating: 0, count: 42))

        let desc = content.debugDescription

        XCTAssertTrue(desc.contains("42"),
                      "Expected byte count in debug description, got: \(desc)")
    }

    func test_debugDescription_plainText() {
        let content = ClipboardContent.plainText("sample text", .utf8)

        let desc = content.debugDescription

        XCTAssertTrue(desc.contains("sample text"),
                      "Expected text in debug description, got: \(desc)")
    }

    func test_debugDescription_color() {
        let content = ClipboardContent.color(Data(repeating: 0xFF, count: 8))

        let desc = content.debugDescription

        XCTAssertTrue(desc.contains("8"),
                      "Expected byte count in debug description, got: \(desc)")
    }

    func test_debugDescription_unknown() {
        let rep = TestFixtures.unknownRepresentation(rawType: "com.example.mystery")
        let content = ClipboardContent.unknown(rep)

        let desc = content.debugDescription

        XCTAssertTrue(desc.contains("com.example.mystery") || desc.contains("Unknown"),
                      "Expected unknown type info in debug description, got: \(desc)")
    }
}

// MARK: - ClipboardContent Display Title Tests

final class ClipboardContentDisplayTitleTests: XCTestCase {

    func test_displayTitle_knownTypes() {
        XCTAssertEqual(ClipboardContent.url(raw: "https://a.com", parsed: nil).displayTitle, "URL")
        XCTAssertEqual(ClipboardContent.image(Data()).displayTitle, "Image")
        XCTAssertEqual(ClipboardContent.plainText("x", .utf8).displayTitle, "Plain text")
        XCTAssertEqual(ClipboardContent.color(Data()).displayTitle, "Color")
    }

    func test_displayTitle_unknown_humanizesUTI() {
        let html = ClipboardContent.unknown(
            TestFixtures.unknownRepresentation(rawType: "public.html")
        )
        XCTAssertEqual(html.displayTitle, "HTML")

        let rtf = ClipboardContent.unknown(
            TestFixtures.unknownRepresentation(rawType: "com.apple.flat-rtf")
        )
        XCTAssertEqual(rtf.displayTitle, "Flat Rtf")
    }
}

// MARK: - UTType+Raw Tests

final class UTTypeRawTests: XCTestCase {

    func test_appleColor_identifier() {
        XCTAssertEqual(
            UTType.appleColor.identifier,
            "com.apple.cocoa.pasteboard.color",
            "UTType.appleColor should map to the Apple color pasteboard type"
        )
    }
}
