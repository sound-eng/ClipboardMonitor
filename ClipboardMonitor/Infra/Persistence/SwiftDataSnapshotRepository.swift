//
//  SwiftDataSnapshotRepository.swift
//  ClipboardMonitor
//

import Foundation
import SwiftData
import Observation

/// SwiftData-backed snapshot history with a rolling cap of `maxCount`.
@Observable
@MainActor
final class SwiftDataSnapshotRepository: SnapshotRepositoryProtocol {
    static let maxCount = 100

    private let modelContext: ModelContext

    /// In-memory cache kept in sync with the store so the UI never re-fetches on every read.
    private(set) var snapshots: [PasteboardSnapshot] = []

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        refresh()
    }

    func add(_ snapshot: PasteboardSnapshot) {
        let persisted = PersistedSnapshot(from: snapshot)
        modelContext.insert(persisted)
        evictIfNeeded()
        save()
        refresh()
    }

    // MARK: - Private

    private func evictIfNeeded() {
        let descriptor = FetchDescriptor<PersistedSnapshot>(
            sortBy: [SortDescriptor(\.capturedAt, order: .forward)]
        )
        guard let all = try? modelContext.fetch(descriptor), all.count > Self.maxCount else { return }
        // Delete oldest first until we are back under the cap.
        let overflow = all.count - Self.maxCount
        for snapshot in all.prefix(overflow) {
            modelContext.delete(snapshot)
        }
    }

    private func save() {
        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed to save snapshots: \(error)")
        }
    }

    private func refresh() {
        let descriptor = FetchDescriptor<PersistedSnapshot>(
            sortBy: [SortDescriptor(\.capturedAt, order: .reverse)]
        )
        let persisted = (try? modelContext.fetch(descriptor)) ?? []
        snapshots = persisted.map { $0.toDomain() }
    }
}
