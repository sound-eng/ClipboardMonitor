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

    /// Cascade: deleting a snapshot removes its representations.
    @Relationship(deleteRule: .cascade, inverse: \PersistedRepresentation.snapshot)
    var representations: [PersistedRepresentation]

    init(id: UUID, capturedAt: Date, representations: [PersistedRepresentation] = []) {
        self.id = id
        self.capturedAt = capturedAt
        self.representations = representations
    }
}
