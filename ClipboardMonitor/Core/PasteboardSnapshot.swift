//
//  PasteboardSnapshot.swift
//  ClipboardMonitor
//

import Foundation
import UniformTypeIdentifiers

/// How the source app for a snapshot was determined.
enum PasteboardSourceAttribution: String, Hashable, Sendable {
    /// Non-empty `org.nspasteboard.source` bundle ID.
    case declared
    /// `org.nspasteboard.source` present but empty — source explicitly unknown.
    case unknown
    /// Inferred from the frontmost app when the marker type was absent.
    case frontmost
}

/// Best-effort originating application for a clipboard capture.
struct PasteboardSource: Hashable, Sendable {
    var bundleIdentifier: String?
    var displayName: String?
    var attribution: PasteboardSourceAttribution

    /// Short label for lists and overview.
    var label: String {
        switch attribution {
        case .declared, .frontmost:
            return displayName ?? bundleIdentifier ?? "Unknown app"
        case .unknown:
            return "Unknown app"
        }
    }
}

/// Snapshot of pasteboard state at a point in time.
///
struct PasteboardSnapshot: Identifiable, Hashable {
    let id: UUID
    let capturedAt: Date
    let items: [RawPasteboardItem]
    /// Originating app when known or inferred; `nil` on platforms that cannot attribute.
    let source: PasteboardSource?

    init(
        id: UUID = UUID(),
        capturedAt: Date = Date(),
        items: [RawPasteboardItem],
        source: PasteboardSource? = nil
    ) {
        self.id = id
        self.capturedAt = capturedAt
        self.items = items
        self.source = source
    }

    /// All representations across every pasteboard item, flattened.
    /// The inspector UI works on this flat list (see implementation plan).
    var representations: [RawRepresentation] {
        items.flatMap(\.representations)
    }

    /// Whether this snapshot carries the same clipboard payload as `other`.
    ///
    /// Ignores item boundaries, representation order, and resolved `UTType` —
    /// all of which can diverge between a live pasteboard read and a SwiftData
    /// round-trip (persistence flattens items and may re-resolve types).
    func hasSameClipboardContent(as other: PasteboardSnapshot) -> Bool {
        contentFingerprint == other.contentFingerprint
    }

    /// Stable identity over `(rawType, data)` pairs, sorted for order invariance.
    private var contentFingerprint: [ClipboardContentKey] {
        representations
            .map { ClipboardContentKey(rawType: $0.rawType, data: $0.data) }
            .sorted()
    }
}

/// Order- and structure-invariant key for consecutive-duplicate detection.
private struct ClipboardContentKey: Hashable, Comparable {
    let rawType: String
    let data: Data

    static func < (lhs: ClipboardContentKey, rhs: ClipboardContentKey) -> Bool {
        if lhs.rawType != rhs.rawType { return lhs.rawType < rhs.rawType }
        return lhs.data.lexicographicallyPrecedes(rhs.data)
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
