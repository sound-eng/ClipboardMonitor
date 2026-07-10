//
//  OverviewFacetView.swift
//  ClipboardMonitor
//

import SwiftUI
import UniformTypeIdentifiers

/// Summary card: optional live preview on top, then type/size/inspector metadata.
struct OverviewFacetView: View {
    let representation: RawRepresentation
    let content: ClipboardContent
    let inspectorName: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if showsPreview {
                    previewSection
                }

                VStack(alignment: .leading, spacing: 16) {
                    overviewRow("Type", value: typeDescription)
                    overviewRow("Size", value: sizeDescription)
                    overviewRow("Inspector", value: inspectorName ?? "Unknown")
                    if !conformances.isEmpty {
                        overviewRow("Conformances", value: conformances.joined(separator: " → "))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
    }

    /// Preview is inlined here for known content; unknown payloads skip it.
    private var showsPreview: Bool {
        if case .unknown = content { return false }
        return true
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PREVIEW")
                .font(.caption)
                .foregroundStyle(.secondary)
            PreviewFacetView(content: content)
        }
    }

    private var typeDescription: String {
        if let type = representation.type {
            let mime = type.preferredMIMEType.map { " (\($0))" } ?? ""
            return "\(representation.rawType)\(mime)"
        }
        return representation.rawType
    }

    private var sizeDescription: String {
        let count = representation.data.count
        return "\(Formatters.bytes(count)) (\(count.formatted()) bytes)"
    }

    /// Approximate conformance chain via well-known parents.
    /// UTType has no ordered `supertypes` API, so we probe common ancestors.
    private var conformances: [String] {
        guard let type = representation.type else { return [] }
        var chain = [type.identifier]
        let candidates: [UTType] = [
            .html, .xml, .plainText, .text, .image, .audio, .video,
            .url, .fileURL, .data, .content, .item
        ]
        for candidate in candidates where type != candidate && type.conforms(to: candidate) {
            if !chain.contains(candidate.identifier) {
                chain.append(candidate.identifier)
            }
        }
        return chain
    }

    private func overviewRow(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body.monospaced())
                .textSelection(.enabled)
        }
    }
}
