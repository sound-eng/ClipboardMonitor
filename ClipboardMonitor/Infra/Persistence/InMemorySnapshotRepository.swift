//
//  InMemorySnapshotRepository.swift
//  ClipboardMonitor
//

import Foundation
import Observation

/// In-memory snapshot repository for SwiftUI previews and unit tests.
@Observable
@MainActor
final class InMemorySnapshotRepository: SnapshotRepositoryProtocol {
    private(set) var snapshots: [PasteboardSnapshot]

    init(snapshots: [PasteboardSnapshot] = []) {
        // Newest-first to match the SwiftData repository contract.
        self.snapshots = snapshots.sorted { $0.capturedAt > $1.capturedAt }
    }

    func add(_ snapshot: PasteboardSnapshot) {
        snapshots.insert(snapshot, at: 0)
    }
}
