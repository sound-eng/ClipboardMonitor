//
//  HexDump.swift
//  ClipboardMonitor
//

import Foundation

/// Builds classic hex-dump rows from raw bytes (no third-party dependency).
enum HexDump {
    struct Row: Identifiable {
        let id: Int
        let offset: String
        let hex: String
        let ascii: String
    }

    static let bytesPerRow = 16

    /// Split `data` into display rows. Large payloads stay lazy via the caller’s `LazyVStack`.
    static func rows(from data: Data) -> [Row] {
        guard !data.isEmpty else { return [] }
        let rowCount = (data.count + bytesPerRow - 1) / bytesPerRow
        return (0..<rowCount).map { rowIndex in
            let start = rowIndex * bytesPerRow
            let end = min(start + bytesPerRow, data.count)
            let slice = data[start..<end]

            let offset = String(format: "%08X", start)
            let hex = slice.map { String(format: "%02x", $0) }.joined(separator: " ")
                .padding(toLength: bytesPerRow * 3 - 1, withPad: " ", startingAt: 0)
            let ascii = String(slice.map { byte -> Character in
                (32...126).contains(byte) ? Character(UnicodeScalar(byte)) : "."
            })

            return Row(id: rowIndex, offset: offset, hex: hex, ascii: ascii)
        }
    }
}
