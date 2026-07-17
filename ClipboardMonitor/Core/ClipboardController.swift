//
//  ClipboardController.swift
//  ClipboardMonitor
//

import Foundation

/// Wires monitor → reader → repository. Owns the monitoring task lifecycle.
///
@MainActor
final class ClipboardController {
    private var monitor: any ClipboardMonitoring
    private let reader: ClipboardReading
    private let repository: any SnapshotRepositoryProtocol
    private let classifier: ClipboardClassifier
    private var task: Task<Void, Never>?
    /// Last pasteboard generation we successfully considered. Avoids re-reading
    /// unchanged content on every iOS foreground activation.
    private var lastCapturedChangeCount: Int?

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

    /// Starts listening for pasteboard change events from `monitor`.
    func start(monitor: (any ClipboardMonitoring)? = nil) {
        if let monitor {
            self.monitor = monitor
        }
        task?.cancel()
        task = Task {
            for await event in self.monitor.events {
                switch event {
                case .changed:
                    self.captureSnapshot()
                }
            }
        }
    }

    /// Reads the current pasteboard, stores a snapshot, and classifies for side-effect logging.
    /// Skips empty pasteboards and consecutive duplicates (e.g. relaunch / foreground
    /// with unchanged clipboard). Prefer `changeCount`; fall back to content fingerprint
    /// when changeCount is unknown (cold start) or when the pasteboard was rewritten
    /// with identical payload.
    func captureSnapshot() {
        let changeCount = reader.changeCount
        if lastCapturedChangeCount == changeCount {
            return
        }

        let snapshot = reader.readSnapshot()
        guard !snapshot.representations.isEmpty else { return }

        if let latest = repository.snapshots.first, latest.hasSameClipboardContent(as: snapshot) {
            lastCapturedChangeCount = changeCount
            return
        }

        repository.add(snapshot)
        lastCapturedChangeCount = changeCount
        _ = snapshot.items.map(classifier.classify)
    }

    /// Stops listening for pasteboard changes.
    func stop() {
        task?.cancel()
        task = nil
    }
}
