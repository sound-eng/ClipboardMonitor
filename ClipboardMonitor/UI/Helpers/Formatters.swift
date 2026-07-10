//
//  Formatters.swift
//  ClipboardMonitor
//

import Foundation

enum Formatters {
    /// Human-readable byte count, e.g. "4.2 KB".
    static func bytes(_ count: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        return formatter.string(fromByteCount: Int64(count))
    }

    /// Relative timestamp, e.g. "2s ago".
    static func relativeDate(_ date: Date, relativeTo reference: Date = Date()) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: reference)
    }
}
