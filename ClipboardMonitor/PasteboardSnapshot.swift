//
//  PasteboardSnapshot.swift
//  ClipboardMonitor
//
//  Created by Oleh Naumenko on 09.07.2026.
//

import Foundation
import UniformTypeIdentifiers

struct PasteboardSnapshot {
    let items: [RawPasteboardItem]
}

struct RawPasteboardItem {
    let representations: [RawRepresentation]
}

struct RawRepresentation {
    let rawType: String
    let type: UTType?
    let data: Data
}

extension RawRepresentation: CustomDebugStringConvertible {
    var debugDescription: String {
        return "Raw type = \(self.rawType), type = \(self.type ?? UTType(importedAs: "com.wearedevx.ClipboardMonitor.unknown")), data.count = \(self.data.count)"
    }
}
