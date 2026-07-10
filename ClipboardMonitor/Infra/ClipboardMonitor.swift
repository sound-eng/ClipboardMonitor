//
//  ClipboardMonitor.swift
//  ClipboardMonitor
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

@MainActor
final class ClipboardMonitor: ClipboardMonitoring {
    private let pasteboard: PlatformPasteboard
    private let pollingInterval: Duration

    init(pasteboard: PlatformPasteboard = .general, pollingInterval: Duration = .milliseconds(250)) {
        self.pasteboard = pasteboard
        self.pollingInterval = pollingInterval
    }

    var events: AsyncStream<ClipboardEvent> {
        AsyncStream { continuation in
            var last = pasteboard.changeCount

            let task = Task {
                while !Task.isCancelled {
                    try await Task.sleep(for: pollingInterval)

                    let current = pasteboard.changeCount
                    guard current != last else { continue }

                    last = current
                    continuation.yield(.changed(changeCount: current))
                }
            }

            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
