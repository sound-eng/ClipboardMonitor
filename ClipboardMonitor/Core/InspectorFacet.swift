//
//  InspectorFacet.swift
//  ClipboardMonitor
//

import Foundation

/// One inspection dimension an inspector can expose — maps 1:1 to a tab in the detail pane.
/// Preview is not a tab; it renders at the top of Overview when available.
///
enum InspectorFacet: String, CaseIterable, Identifiable {
    case overview
    case source
    case metadata
    case hex

    var id: String { rawValue }

    /// Tab title shown in the inspector strip.
    var label: String {
        switch self {
        case .overview: "Overview"
        case .source: "Source"
        case .metadata: "Metadata"
        case .hex: "Hex"
        }
    }

    /// SF Symbol for the tab.
    var systemImage: String {
        switch self {
        case .overview: "info.circle"
        case .source: "chevron.left.forwardslash.chevron.right"
        case .metadata: "list.bullet.rectangle"
        case .hex: "number"
        }
    }
}
