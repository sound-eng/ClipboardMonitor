//
//  ClipboardController.swift
//  ClipboardMonitor
//
//  Created by Oleh Naumenko on 08.07.2026.
//

import Foundation

@MainActor
class ClipboardController {

    let monitor = ClipboardMonitor()
    let reader = ClipboardReader()
    let repository = SnapshotRepository()
    let classifier = ClipboardClassifier(inspectors: .all)

    var task: Task<Void, Never>?


    func start() {
        task = Task {
            for await event in monitor.events {
                switch event {
                case .changed:
                    let snapshot = reader.readSnapshot()
                    repository.add(snapshot)
                    let classifications = snapshot.items.map(classifier.classify)
                    print("\n>> Classification:")
                    classifications.forEach { contentsArray in
                        contentsArray.forEach { content in
                            print(" * \(content)")
                        }
                    }

                }
            }
        }
    }

    func stop() {
        task?.cancel()
    }
}
