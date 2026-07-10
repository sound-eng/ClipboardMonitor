//
//  CompareView.swift
//  ClipboardMonitor
//

import SwiftUI

/// Side-by-side comparison of two representations with a simple LCS line diff.
struct CompareView: View {
    let representations: [RawRepresentation]
    let initialLeftID: RawRepresentation.ID?
    let classifier: ClipboardClassifier

    @Environment(\.dismiss) private var dismiss
    @State private var leftID: RawRepresentation.ID?
    @State private var rightID: RawRepresentation.ID?

    init(
        representations: [RawRepresentation],
        initialLeftID: RawRepresentation.ID?,
        classifier: ClipboardClassifier
    ) {
        self.representations = representations
        self.initialLeftID = initialLeftID
        self.classifier = classifier
        let left = initialLeftID ?? representations.first?.id
        let right = representations.first(where: { $0.id != left })?.id ?? representations.dropFirst().first?.id
        _leftID = State(initialValue: left)
        _rightID = State(initialValue: right)
    }

    private var left: RawRepresentation? {
        representations.first { $0.id == leftID }
    }

    private var right: RawRepresentation? {
        representations.first { $0.id == rightID }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                pickerBar
                Divider()
                diffBody
            }
            .navigationTitle("Compare")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .frame(minWidth: 720, minHeight: 480)
    }

    private var pickerBar: some View {
        HStack(spacing: 16) {
            Picker("Left", selection: $leftID) {
                ForEach(representations) { rep in
                    Text(rep.rawType).tag(Optional(rep.id))
                }
            }
            Picker("Right", selection: $rightID) {
                ForEach(representations) { rep in
                    Text(rep.rawType).tag(Optional(rep.id))
                }
            }
        }
        .padding(12)
    }

    @ViewBuilder
    private var diffBody: some View {
        let leftText = left.flatMap(text(for:))
        let rightText = right.flatMap(text(for:))

        if let leftText, let rightText {
            let lines = TextDiff.diff(lhs: leftText, rhs: rightText)
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                        diffRow(line)
                    }
                }
                .padding(12)
            }
        } else {
            ContentUnavailableView(
                "Binary comparison unavailable",
                systemImage: "doc.on.doc",
                description: Text("One or both sides could not be decoded as text. Use Hex instead.")
            )
        }
    }

    private func text(for representation: RawRepresentation) -> String? {
        let content = classifier.classify(representation)
        switch content {
        case .plainText(let text, _): return text
        case .richText(let attributed): return String(attributed.characters)
        case .html(let source): return source
        case .url(let raw, _): return raw
        case .image, .color: return nil
        case .unknown: return RepresentationDecoding.text(from: representation)
        }
    }

    private func diffRow(_ line: TextDiff.Line) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(prefix(for: line))
                .foregroundStyle(color(for: line))
                .frame(width: 14, alignment: .center)
            Text(line.text.isEmpty ? " " : line.text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundStyle(color(for: line))
        }
        .font(.system(.caption, design: .monospaced))
        .padding(.vertical, 1)
        .padding(.horizontal, 4)
        .background(background(for: line))
        .textSelection(.enabled)
    }

    private func prefix(for line: TextDiff.Line) -> String {
        switch line {
        case .unchanged: " "
        case .added: "+"
        case .removed: "-"
        }
    }

    private func color(for line: TextDiff.Line) -> Color {
        switch line {
        case .unchanged: .primary
        case .added: .green
        case .removed: .red
        }
    }

    private func background(for line: TextDiff.Line) -> Color {
        switch line {
        case .unchanged: .clear
        case .added: Color.green.opacity(0.12)
        case .removed: Color.red.opacity(0.12)
        }
    }
}
