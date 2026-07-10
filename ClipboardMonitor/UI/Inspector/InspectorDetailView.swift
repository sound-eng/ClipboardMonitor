//
//  InspectorDetailView.swift
//  ClipboardMonitor
//

import SwiftUI

/// Right pane: facet tab strip + content for the selected representation.
struct InspectorDetailView: View {
    let representation: RawRepresentation?
    let classifier: ClipboardClassifier
    var source: PasteboardSource? = nil

    /// Owned here so parent selection churn cannot clobber the active tab mid-click.
    @State private var selectedFacet: InspectorFacet = .overview

    var body: some View {
        Group {
            if let representation {
                VStack(spacing: 0) {
                    facetTabStrip(for: representation)
                    Divider()
                    facetContent(for: representation)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .id(selectedFacet) // force a clean swap when the tab changes
                }
            } else {
                ContentUnavailableView(
                    "Select a representation",
                    systemImage: "waveform.badge.magnifyingglass",
                    description: Text("Pick a type from the middle pane to inspect it.")
                )
            }
        }
        .onChange(of: representation?.id) { _, _ in
            selectedFacet = .overview
        }
    }

    // MARK: - Tabs

    private func facets(for representation: RawRepresentation) -> [InspectorFacet] {
        var list = classifier.supportedFacets(for: representation)
        // Hex is always available as the last-resort raw view.
        if !list.contains(.hex) {
            list.append(.hex)
        }
        return list
    }

    private func facetTabStrip(for representation: RawRepresentation) -> some View {
        let available = facets(for: representation)
        // Prefer labeled tabs; collapse the whole strip to icons when width is tight.
        return ViewThatFits(in: .horizontal) {
            facetTabRow(available, labelStyle: .titleAndIcon)
            facetTabRow(available, labelStyle: .iconOnly)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
        .onAppear {
            if !available.contains(selectedFacet) {
                selectedFacet = available.first ?? .overview
            }
        }
        .onChange(of: representation.id) { _, _ in
            let available = facets(for: representation)
            if !available.contains(selectedFacet) {
                selectedFacet = available.first ?? .overview
            }
        }
    }

    private func facetTabRow<S: LabelStyle>(
        _ available: [InspectorFacet],
        labelStyle: S
    ) -> some View {
        HStack(spacing: 4) {
            ForEach(available) { facet in
                facetTab(facet, selected: selectedFacet == facet, labelStyle: labelStyle) {
                    selectedFacet = facet
                }
            }
        }
    }

    private func facetTab<S: LabelStyle>(
        _ facet: InspectorFacet,
        selected: Bool,
        labelStyle: S,
        action: @escaping () -> Void
    ) -> some View {
        // Plain buttons inside split-view detail often miss hits on macOS unless the
        // tappable shape is explicit; prefer a borderless button + contentShape.
        Button(action: action) {
            Label(facet.label, systemImage: facet.systemImage)
                .labelStyle(labelStyle)
                .font(.callout)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .contentShape(Capsule())
        }
        .buttonStyle(.borderless)
        .background(selected ? Color.accentColor.opacity(0.2) : Color.clear, in: Capsule())
        .foregroundStyle(selected ? Color.accentColor : Color.primary)
        .help(facet.label)
    }

    // MARK: - Content

    @ViewBuilder
    private func facetContent(for representation: RawRepresentation) -> some View {
        let content = classifier.classify(representation)
        let inspector = classifier.inspector(for: representation)

        switch selectedFacet {
        case .overview:
            OverviewFacetView(
                representation: representation,
                content: content,
                inspectorName: inspector?.displayName,
                source: source
            )
        case .source:
            SourceFacetView(representation: representation, content: content)
        case .metadata:
            MetadataFacetView(representation: representation, content: content)
        case .hex:
            HexFacetView(data: representation.data)
        }
    }
}
