//
//  PasteboardSnapshot.swift
//  ClipboardMonitor
//

import Foundation
import UniformTypeIdentifiers

/// Keeps snapshot of platform pasteboard state for further processing
///
struct PasteboardSnapshot {
    let items: [RawPasteboardItem]
}

/// Single pasteboard item with all available representations
///
struct RawPasteboardItem {
    let representations: [RawRepresentation]
}

/// Single data type representation available for classification and parsing to a concrete type (Image, String, URL, e t.c.)
///
struct RawRepresentation {
    // We want to use UTType whenever we can, sometimes wall we have is a raw type identifier. So we keep both for now.
    let rawType: String
    let type: UTType?
    let data: Data
}

extension RawRepresentation: CustomDebugStringConvertible {
    var debugDescription: String {
        return "Raw type = \(self.rawType), type = \(self.type ?? UTType(importedAs: "com.wearedevx.ClipboardMonitor.unknown")), data.count = \(self.data.count)"
    }
}
