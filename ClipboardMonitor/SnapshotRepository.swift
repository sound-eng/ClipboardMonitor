//
//  SnapshotRepository.swift
//  ClipboardMonitor
//
//  Created by Oleh Naumenko on 08.07.2026.
//

@MainActor
class SnapshotRepository {
    var snapshots: [PasteboardSnapshot] = []

    func add(_ snapshot: PasteboardSnapshot) {
        snapshots.append(snapshot)
    }
}
