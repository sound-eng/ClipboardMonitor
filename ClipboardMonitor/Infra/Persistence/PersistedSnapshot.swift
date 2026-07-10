//
//  PersistedSnapshot.swift
//  ClipboardMonitor
//

import Foundation
import SwiftData

/// SwiftData mirror of `PasteboardSnapshot`.
/// Lives in Infra so Core stays free of SwiftData.
@Model
final class PersistedSnapshot {
    @Attribute(.unique) var id: UUID
    var capturedAt: Date
    var sourceBundleIdentifier: String?
    var sourceDisplayName: String?
    /// Raw value of `PasteboardSourceAttribution`; nil for legacy rows.
    var sourceAttribution: String?

    /// Cascade: deleting a snapshot removes its representations.
    @Relationship(deleteRule: .cascade, inverse: \PersistedRepresentation.snapshot)
    var representations: [PersistedRepresentation]

    init(
        id: UUID,
        capturedAt: Date,
        sourceBundleIdentifier: String? = nil,
        sourceDisplayName: String? = nil,
        sourceAttribution: String? = nil,
        representations: [PersistedRepresentation] = []
    ) {
        self.id = id
        self.capturedAt = capturedAt
        self.sourceBundleIdentifier = sourceBundleIdentifier
        self.sourceDisplayName = sourceDisplayName
        self.sourceAttribution = sourceAttribution
        self.representations = representations
    }
}
