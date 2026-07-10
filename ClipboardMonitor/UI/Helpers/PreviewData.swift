//
//  PreviewData.swift
//  ClipboardMonitor
//

import Foundation
import UniformTypeIdentifiers

/// Sample snapshots for SwiftUI previews.
enum PreviewData {
    static var snapshots: [PasteboardSnapshot] {
        let text = RawRepresentation(
            rawType: UTType.utf8PlainText.identifier,
            type: .utf8PlainText,
            data: Data("Hello from the clipboard".utf8)
        )
        let url = RawRepresentation(
            rawType: UTType.url.identifier,
            type: .url,
            data: Data("https://example.com".utf8)
        )
        return [
            PasteboardSnapshot(
                capturedAt: Date().addingTimeInterval(-12),
                items: [RawPasteboardItem(representations: [text, url])]
            ),
            PasteboardSnapshot(
                capturedAt: Date().addingTimeInterval(-120),
                items: [RawPasteboardItem(representations: [url])]
            )
        ]
    }
}
