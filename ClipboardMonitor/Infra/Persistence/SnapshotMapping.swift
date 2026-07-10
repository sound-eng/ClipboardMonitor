//
//  SnapshotMapping.swift
//  ClipboardMonitor
//

import Foundation
import UniformTypeIdentifiers

extension PersistedSnapshot {
    /// Convert persisted model → Core value type.
    ///
    /// Item boundaries are not persisted (plan flattens representations), so we
    /// rehydrate as a single `RawPasteboardItem` containing every representation.
    func toDomain() -> PasteboardSnapshot {
        let reps = representations.map { $0.toDomain() }
        return PasteboardSnapshot(
            id: id,
            capturedAt: capturedAt,
            items: [RawPasteboardItem(representations: reps)]
        )
    }

    convenience init(from snapshot: PasteboardSnapshot) {
        // Flatten across pasteboard items — persistence does not keep item boundaries.
        let reps = snapshot.representations.map {
            PersistedRepresentation(rawType: $0.rawType, data: $0.data)
        }
        self.init(id: snapshot.id, capturedAt: snapshot.capturedAt, representations: reps)
    }
}

extension PersistedRepresentation {
    func toDomain() -> RawRepresentation {
        let resolved = UTType(rawType) ?? UTType(importedAs: rawType)
        return RawRepresentation(rawType: rawType, type: resolved, data: data)
    }
}
