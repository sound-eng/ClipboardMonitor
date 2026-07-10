//
//  RepresentationRowView.swift
//  ClipboardMonitor
//

import SwiftUI

/// Single representation row: UTType pill, byte count, inspectable indicator.
struct RepresentationRowView: View {
    let representation: RawRepresentation
    let isInspectable: Bool

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isInspectable ? Color.green.opacity(0.85) : Color.secondary.opacity(0.35))
                .frame(width: 7, height: 7)

            Text(representation.rawType)
                .font(.system(.body, design: .monospaced))
                .lineLimit(1)
                .foregroundStyle(isInspectable ? .primary : .secondary)

            Spacer(minLength: 0)

            Text(Formatters.bytes(representation.data.count))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
