//
//  TestHelpers.swift
//  ClipboardMonitorTests
//

import Foundation
import UniformTypeIdentifiers
@testable import ClipboardMonitor

/// Factory helpers to build test fixtures without touching a real pasteboard.
///
enum TestFixtures {

    /// Build a `RawRepresentation` from a UTType and raw bytes.
    ///
    static func representation(
        type: UTType,
        data: Data
    ) -> RawRepresentation {
        RawRepresentation(rawType: type.identifier, type: type, data: data)
    }

    /// Convenience: build a representation from a UTType and a UTF-8 string.
    ///
    static func representation(
        type: UTType,
        string: String
    ) -> RawRepresentation {
        representation(type: type, data: Data(string.utf8))
    }

    /// Build a representation with a custom raw-type identifier that has no known UTType.
    ///
    static func unknownRepresentation(
        rawType: String = "com.example.unknown-type",
        data: Data = Data([0xDE, 0xAD])
    ) -> RawRepresentation {
        RawRepresentation(rawType: rawType, type: nil, data: data)
    }

    /// Wrap representations into a `RawPasteboardItem`.
    ///
    static func item(_ representations: [RawRepresentation]) -> RawPasteboardItem {
        RawPasteboardItem(representations: representations)
    }

    /// Single-representation item shorthand.
    ///
    static func item(_ representation: RawRepresentation) -> RawPasteboardItem {
        item([representation])
    }
}
