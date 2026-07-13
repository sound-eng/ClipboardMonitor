//
//  HexFacetView.swift
//  ClipboardMonitor
//

import SwiftUI

/// Classic offset / hex / ASCII dump for any representation.
struct HexFacetView: View {
    let data: Data
    @Environment(AppPreferences.self) private var preferences

    var body: some View {
        if data.isEmpty {
            ContentUnavailableView("Empty payload", systemImage: "number")
        } else if data.count > preferences.maxHexDisplayBytes {
            ContentUnavailableView(
                "Payload too large for hex",
                systemImage: "number",
                description: Text(
                    "\(Formatters.bytes(data.count)) exceeds the \(Formatters.bytes(preferences.maxHexDisplayBytes)) hex display limit. Raise it in Preferences to inspect this binary."
                )
            )
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    header
                    ForEach(HexDump.rows(from: data)) { row in
                        HStack(alignment: .firstTextBaseline, spacing: 16) {
                            Text(row.offset)
                                .foregroundStyle(.secondary)
                                .frame(width: 72, alignment: .leading)
                            Text(row.hex)
                                .foregroundStyle(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(row.ascii)
                                .foregroundStyle(.tertiary)
                                .frame(width: 130, alignment: .leading)
                        }
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                    }
                }
                .padding(16)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 16) {
            Text("Offset").frame(width: 72, alignment: .leading)
            Text("Hex").frame(maxWidth: .infinity, alignment: .leading)
            Text("ASCII").frame(width: 130, alignment: .leading)
        }
        .font(.system(.caption2, design: .monospaced).weight(.semibold))
        .foregroundStyle(.secondary)
        .padding(.bottom, 4)
    }
}
