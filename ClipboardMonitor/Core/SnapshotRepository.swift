//
//  SnapshotRepository.swift
//  ClipboardMonitor
//

@MainActor
class SnapshotRepository {
    var snapshots: [PasteboardSnapshot] = []

    func add(_ snapshot: PasteboardSnapshot) {
        snapshots.append(snapshot)
    }
}
