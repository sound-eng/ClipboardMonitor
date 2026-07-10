//
//  SourceFacetView.swift
//  ClipboardMonitor
//

import SwiftUI

/// Decoded text/markup source, or a binary empty-state pointing at Hex.
struct SourceFacetView: View {
    let representation: RawRepresentation
    let content: ClipboardContent

    var body: some View {
        if let text = sourceText {
            ScrollView {
                Text(text)
                    .font(.system(.body, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .padding(16)
            }
        } else {
            ContentUnavailableView(
                "Binary data — use Hex tab",
                systemImage: "doc.questionmark",
                description: Text("\(Formatters.bytes(representation.data.count)) could not be decoded as text.")
            )
        }
    }

    private var sourceText: String? {
        switch content {
        case .plainText(let text, _):
            return text
        case .richText(let attributed):
            // Prefer the original RTF markup when it decodes; fall back to plain characters.
            return RepresentationDecoding.text(from: representation)
                ?? String(attributed.characters)
        case .html(let source):
            return source
        case .url(let raw, _):
            return raw
        case .image, .color:
            return nil
        case .unknown:
            return RepresentationDecoding.text(from: representation)
        }
    }
}
