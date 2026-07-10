//
//  ClipboardController.swift
//  ClipboardMonitor
//

import Foundation

/// Wires monitor → reader → repository. Owns the monitoring task lifecycle.
///
@MainActor
final class ClipboardController {
    private let monitor: ClipboardMonitoring
    private let reader: ClipboardReading
    private let repository: any SnapshotRepositoryProtocol
    private let classifier: ClipboardClassifier
    private var task: Task<Void, Never>?

    init(
        repository: any SnapshotRepositoryProtocol,
        monitor: (any ClipboardMonitoring)? = nil,
        reader: (any ClipboardReading)? = nil,
        classifier: ClipboardClassifier? = nil
    ) {
        self.repository = repository
        // Defaults constructed in the body so MainActor isolation is satisfied
        // (default argument expressions are evaluated in a nonisolated context).
        self.monitor = monitor ?? ClipboardMonitor()
        self.reader = reader ?? ClipboardReader()
        self.classifier = classifier ?? .default
    }

    /// Starts listening for pasteboard change events.
    func start() {
        task?.cancel()
        task = Task {
            for await event in monitor.events {
                switch event {
                case .changed:
                    self.captureSnapshot()
                }
            }
        }
    }

    /// Reads the current pasteboard, stores a snapshot, and classifies for side-effect logging.
    func captureSnapshot() {
        let snapshot = reader.readSnapshot()
        // Skip empty pasteboards — common right after launch or clear.
        guard !snapshot.representations.isEmpty else { return }
        repository.add(snapshot)
        _ = snapshot.items.map(classifier.classify)
    }

    /// Stops listening for pasteboard changes.
    func stop() {
        task?.cancel()
        task = nil
    }
}
