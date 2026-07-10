//
//  ClipboardMonitoring.swift
//  ClipboardMonitor
//

/// Protocol for all types who pretends they are able to monitor clipboard events
///
protocol ClipboardMonitoring {
    var events: AsyncStream<ClipboardEvent> { get }
}
