//
//  ClipboardMonitor.swift
//  ClipboardMonitor
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// The only task of this class is to monitor wether pasteboard's state changes, via changeCount property.
/// It then fires event for other components to proceed.

@MainActor
final class ClipboardMonitor: ClipboardMonitoring {
    private let pasteboard: PlatformPasteboard
    private let pollingInterval: Duration

    init(pasteboard: PlatformPasteboard = .general, pollingInterval: Duration = .milliseconds(250)) {
        self.pasteboard = pasteboard
        self.pollingInterval = pollingInterval
    }

    /// Asynchronous stream of events fired when Pasteboard state changes
    /// New event is emitted when pasteboard changeCount updates.
    ///
    var events: AsyncStream<ClipboardEvent> {
        AsyncStream { continuation in
            // We want to capture the initial pasteboard state too. To exclude it, use 'var last = pasteboard.changeCount':
            var last = 0

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
