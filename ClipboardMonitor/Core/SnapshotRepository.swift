//
//  SnapshotRepository.swift
//  ClipboardMonitor
//

import Foundation

/// Ordered history of clipboard snapshots.
///
/// Implementations may be in-memory (previews/tests) or SwiftData-backed (production).
/// Marked `@MainActor` because UI and `ClipboardController` both touch this on the main thread.
@MainActor
protocol SnapshotRepositoryProtocol: AnyObject {
    /// Snapshots newest-first.
    var snapshots: [PasteboardSnapshot] { get }

    /// Persists a snapshot and enforces any retention policy.
    func add(_ snapshot: PasteboardSnapshot)
}
