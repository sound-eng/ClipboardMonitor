//
//  PasteboardSnapshot.swift
//  ClipboardMonitor
//

import Foundation
import UniformTypeIdentifiers

/// Snapshot of pasteboard state at a point in time.
///
struct PasteboardSnapshot: Identifiable, Hashable {
    let id: UUID
    let capturedAt: Date
    let items: [RawPasteboardItem]

    init(id: UUID = UUID(), capturedAt: Date = Date(), items: [RawPasteboardItem]) {
        self.id = id
        self.capturedAt = capturedAt
        self.items = items
    }

    /// All representations across every pasteboard item, flattened.
    /// The inspector UI works on this flat list (see implementation plan).
    var representations: [RawRepresentation] {
        items.flatMap(\.representations)
    }
}

/// Single pasteboard item with all available representations.
///
struct RawPasteboardItem: Hashable {
    let representations: [RawRepresentation]
}

/// Single data-type representation available for classification.
///
struct RawRepresentation: Identifiable, Hashable {
    /// Stable within a snapshot; identical copies share an id, which is fine for list selection.
    var id: Int {
        var hasher = Hasher()
        hasher.combine(rawType)
        hasher.combine(data)
        return hasher.finalize()
    }

    /// We prefer `UTType` when resolvable; some pasteboard types only exist as raw identifiers.
    let rawType: String
    let type: UTType?
    let data: Data
}

extension RawRepresentation: CustomDebugStringConvertible {
    var debugDescription: String {
        "Raw type = \(rawType), type = \(type?.identifier ?? "nil"), data.count = \(data.count)"
    }
}
