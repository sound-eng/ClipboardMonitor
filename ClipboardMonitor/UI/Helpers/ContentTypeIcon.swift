//
//  ContentTypeIcon.swift
//  ClipboardMonitor
//

import Foundation
import UniformTypeIdentifiers

enum ContentTypeIcon {
    /// SF Symbol for the dominant content in a snapshot (sidebar row).
    static func systemImage(for snapshot: PasteboardSnapshot, classifier: ClipboardClassifier = .default) -> String {
        guard let primaryRep = classifier.primaryRepresentation(in: snapshot.representations) else {
            return "doc.on.clipboard"
        }
        switch classifier.classify(primaryRep) {
        case .image: return "photo"
        case .url: return "link"
        case .plainText: return "doc.plaintext"
        case .color: return "paintpalette"
        case .unknown: return "questionmark.square"
        }
    }

    static func systemImage(for representation: RawRepresentation) -> String {
        guard let type = representation.type else { return "questionmark.square" }
        if type.conforms(to: .image) { return "photo" }
        if type.conforms(to: .url) || type.conforms(to: .fileURL) { return "link" }
        if type.conforms(to: .text) { return "doc.plaintext" }
        if type == .appleColor { return "paintpalette" }
        return "doc"
    }
}
