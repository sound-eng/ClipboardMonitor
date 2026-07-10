//
//  ClipboardController.swift
//  ClipboardMonitor
//

import Foundation

/// Controller that assembles together the clipboard monitor core service
///
@MainActor
final class ClipboardController {
    private let monitor = ClipboardMonitor()
    private let reader = ClipboardReader()
    private let repository = SnapshotRepository()
    private let classifier = ClipboardClassifier.default
    private var task: Task<Void, Never>?

    /// Starts periodic clipboard monitoring
    ///
    func start() {
        task?.cancel()
        task = Task {
            for await event in monitor.events {
                switch event {
                case .changed:
                    self.makeSnapshot()
                }
            }
        }
    }

    /// Fetches single snapshot of the Pasteboard state, classifies the contents and invokes all necessary logic (I know, a bit god - like)
    /// 
    func makeSnapshot() {
        let snapshot = reader.readSnapshot()
        repository.add(snapshot)

        let contents = snapshot.items.map(classifier.classify)

        print("\n>> Classification:")

        contents.forEach { contentsArray in
            contentsArray.forEach { content in
                print(" * \(content)")
            }
        }
    }

    /// Stops periodic clipboard monitoring
    ///
    func stop() {
        task?.cancel()
    }
}
