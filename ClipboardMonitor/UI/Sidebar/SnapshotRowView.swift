//
//  SnapshotRowView.swift
//  ClipboardMonitor
//

import SwiftUI

/// Single history row: type icon, relative time, total byte count.
struct SnapshotRowView: View {
    let snapshot: PasteboardSnapshot
    private let classifier = ClipboardClassifier.default

    private var totalBytes: Int {
        snapshot.representations.reduce(0) { $0 + $1.data.count }
    }

    private var primaryRepresentation: RawRepresentation? {
        classifier.primaryRepresentation(in: snapshot.representations)
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: ContentTypeIcon.systemImage(for: snapshot))
                .foregroundStyle(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(primaryLabel)
                    .lineLimit(1)
                Text(Formatters.relativeDate(snapshot.capturedAt))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 0)

            Text(Formatters.bytes(totalBytes))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var primaryLabel: String {
        guard let primaryRepresentation else { return "Empty" }
        return classifier.classify(primaryRepresentation).displayTitle
    }
}
