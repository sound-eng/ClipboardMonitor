//
//  ClipboardMonitor.swift
//  ClipboardMonitor
//
//  Created by Oleh Naumenko on 08.07.2026.
//

import Foundation

enum ClipboardEvent {
    case changed(changeCount: Int)
}

protocol PasteboardMonitor {
    var events: AsyncStream<ClipboardEvent> { get }
}

#if os(macOS)

import AppKit

@MainActor
final class ClipboardMonitor: PasteboardMonitor {

    private let pasteboard: NSPasteboard
    private let pollingInterval: Duration

    init(pasteboard: NSPasteboard = .general, pollingInterval: Duration = .milliseconds(250)) {
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

#else

import UIKit

@MainActor
final class ClipboardMonitor: PasteboardMonitor {

    private let pasteboard: UIPasteboard
    private let pollingInterval: Duration

    init(pasteboard: UIPasteboard = .general, pollingInterval: Duration = .milliseconds(250)) {
        self.pasteboard = pasteboard
        self.pollingInterval = pollingInterval
    }

    var events: AsyncStream<ClipboardEvent> {
        AsyncStream { continuation in
            let task = Task { @MainActor in
                var last = pasteboard.changeCount
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

#endif
