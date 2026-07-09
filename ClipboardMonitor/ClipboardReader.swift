//
//  PAsteboardReader.swift
//  ClipboardMonitor
//
//  Created by Oleh Naumenko on 08.07.2026.
//

import AppKit
import Foundation
import UniformTypeIdentifiers

struct PasteboardSnapshot {
    let items: [RawPasteboardItem]
}

struct RawPasteboardItem {
    let representations: [RawRepresentation]
}

struct RawRepresentation {
    let type: UTType
    let data: Data
}

protocol PasteboardReader {
    func readSnapshot() throws -> PasteboardSnapshot
}

@MainActor
final class ClipboardReader: PasteboardReader {

    private let pasteboard: NSPasteboard

    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    func readSnapshot() throws -> PasteboardSnapshot {
        let items = pasteboard.pasteboardItems ?? []
        return PasteboardSnapshot(
            items: items.map { item in
                RawPasteboardItem(
                    representations: item.types.compactMap { type in
                        guard let data = item.data(forType: type) else { return nil }
                        return RawRepresentation(type: UTType(type.rawValue) ?? .data, data: data)
                    }
                )
            }
        )
    }
}

@MainActor
final class FakePasteboardReader: PasteboardReader {
    var snapshotToReturn = PasteboardSnapshot(items: [])
    func readSnapshot() throws -> PasteboardSnapshot { snapshotToReturn }
}
