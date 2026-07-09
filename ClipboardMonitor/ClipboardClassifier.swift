//
//  ClipboardClassifier.swift
//  ClipboardMonitor
//
//  Created by Oleh Naumenko on 08.07.2026.
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
