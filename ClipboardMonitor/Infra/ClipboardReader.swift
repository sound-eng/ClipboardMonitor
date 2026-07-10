//
//  ClipboardMonitor.swift
//  ClipboardMonitor
//

#if os(macOS)
import AppKit
#else
import UIKit
#endif

import UniformTypeIdentifiers

protocol ClipboardReading {
    func readSnapshot() -> PasteboardSnapshot
}

@MainActor
final class ClipboardReader: ClipboardReading {
    private let pasteboard: PlatformPasteboard

    init(pasteboard: PlatformPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    func readSnapshot() -> PasteboardSnapshot {
        #if os(macOS)
        let items = pasteboard.pasteboardItems ?? []
        return PasteboardSnapshot(
            items: items.map { item in
                RawPasteboardItem(
                    representations: item.types.compactMap { type -> RawRepresentation? in
                        guard let data = item.data(forType: type) else { return nil }
                        let rawType = type.rawValue
                        // Using UTType(importedAs:) because we want clipboard items from all the applications, and this causes console to log messages like:
                        // "Type "org.chromium.source-url" was expected to be declared and imported in the Info.plist of ClipboardMonitor.app, but it was not found.",
                        // because this type is reserved for someone else (Chromium/Slack in this case), so we ignore the message.
                        let resolvedType = UTType(rawType) ?? UTType(importedAs: rawType)
                        return RawRepresentation(rawType: rawType, type: resolvedType, data: data)
                    }
                )
            }
        )
        #else
        let items = pasteboard.items
        return PasteboardSnapshot(
            items: items.map { item in
                RawPasteboardItem(
                    representations: item.compactMap { (key, value) -> RawRepresentation? in
                        let rawType = key
                        let resolvedType = UTType(rawType)
                        let data: Data
                        if let d = value as? Data {
                            data = d
                        } else if let s = value as? String {
                            data = Data(s.utf8)
                        } else if let img = value as? UIImage, let pngData = img.pngData() {
                            data = pngData
                        } else {
                            return nil
                        }
                        return RawRepresentation(rawType: rawType, type: resolvedType, data: data)
                    }
                )
            }
        )
        #endif
    }
}

@MainActor
final class FakePasteboardReader: ClipboardReading {
    var snapshotToReturn = PasteboardSnapshot(items: [])
    func readSnapshot() -> PasteboardSnapshot { snapshotToReturn }
}
