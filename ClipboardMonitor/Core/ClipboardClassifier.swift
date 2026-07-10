//
//  ClipboardClassifier.swift
//  ClipboardMonitor
//

import Foundation
import UniformTypeIdentifiers

/// Responsible for Pasteboard Items classification - i.e. getting Raw Pasteboard Item as input
/// and generating corresponding certain amount of Clipboard Contents type structs  in output.
///
final class ClipboardClassifier {
    private var inspectors: [ClipboardInspector]

    init(inspectors: [ClipboardInspector]) {
        self.inspectors = inspectors.sorted { $0.priority > $1.priority }
    }

    /// Default static initialiser, packs in all available inspectors.
    /// 
    static let `default` = ClipboardClassifier(inspectors: [
        URLClipboardInspector(),
        PlainTextInspector(),
        ImageClipboardInspector(),
        ColorClipboardInspector()
    ])

    /// Inspectors ordered by priority (highest first), for UI lookups.
    var orderedInspectors: [ClipboardInspector] { inspectors }

    /// Classify a single representation (convenience for the inspector pane).
    func classify(_ representation: RawRepresentation) -> ClipboardContent {
        classify(RawPasteboardItem(representations: [representation])).first ?? .unknown(representation)
    }

    /// First inspector that claims this representation's type, if any.
    func inspector(for representation: RawRepresentation) -> ClipboardInspector? {
        inspectors.first { inspector in
            inspector.supportedTypes.contains { $0.identifier == representation.rawType }
        }
    }

    /// Facets to show for a representation — falls back to overview + hex when unknown.
    func supportedFacets(for representation: RawRepresentation) -> [InspectorFacet] {
        inspector(for: representation)?.supportedFacets(for: representation) ?? [.overview, .hex]
    }

    /// Most obvious representation for UI defaults.
    /// Prefer inspectables that expose a Metadata facet; break ties by inspector priority.
    func primaryRepresentation(in representations: [RawRepresentation]) -> RawRepresentation? {
        orderedRepresentations(representations).first
    }

    /// Primary first, then other inspectables (metadata-capable before the rest), then unknowns.
    func orderedRepresentations(_ representations: [RawRepresentation]) -> [RawRepresentation] {
        representations.enumerated()
            .sorted { lhs, rhs in
                let lMeta = hasMetadataFacet(lhs.element)
                let rMeta = hasMetadataFacet(rhs.element)
                // When several types are supported, metadata-bearing ones are more "primary".
                if lMeta != rMeta { return lMeta && !rMeta }

                let lp = inspectionPriority(for: lhs.element)
                let rp = inspectionPriority(for: rhs.element)
                if lp != rp { return lp > rp }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }

    /// Inspector priority when the representation is inspectable; `Int.min` sinks unknowns.
    private func inspectionPriority(for representation: RawRepresentation) -> Int {
        guard let inspector = inspector(for: representation),
              inspector.inspect(representation) != nil else {
            return Int.min
        }
        return inspector.priority
    }

    private func hasMetadataFacet(_ representation: RawRepresentation) -> Bool {
        guard inspectionPriority(for: representation) != Int.min else { return false }
        return supportedFacets(for: representation).contains(.metadata)
    }

    /// Classify the incoming raw pasteboard item into our Content enum.
    /// - Parameter item: raw pasteboard item containing data type representations to unpack and classify
    /// - Returns: Content items that reconstruct the objects inside those representations
    func classify(_ item: RawPasteboardItem) -> [ClipboardContent] {
        var contents = [ClipboardContent]()

        // Index representations by type once, then hand inspectors only what they declare interest in:
        var remainingReps = Dictionary(grouping: item.representations, by: \.rawType)

        for inspector in inspectors {
            let supportedRawTypes = inspector.supportedTypes.map { $0.identifier }

            var keysToRemove = [String]()

            // Preferring forEach+mutation over functional composition here,
            // I know filter/partition could express directly what we are doing with keysToRemove,
            // but keeping it as is because I want simple understanding, not a scaffold of nested functions.
            remainingReps.forEach { (key: String, representations: [RawRepresentation]) in
                if supportedRawTypes.contains(key) == false {
                    return
                }
                var keyUsed = false
                for representation in representations {
                    if let content = inspector.inspect(representation) {
                        contents.append(content)
                        keyUsed = true
                    }
                }
                if keyUsed == true {
                    keysToRemove.append(key)
                }
            }

            keysToRemove.forEach { key in
                remainingReps.removeValue(forKey: key)
            }
        }

        remainingReps.values.forEach { unknownReps in
            let unknownContents = unknownReps.map(ClipboardContent.unknown)
            contents.append(contentsOf: unknownContents)
        }
        return contents
    }
}
