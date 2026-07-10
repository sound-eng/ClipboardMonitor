//
//  ClipboardReader.swift
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
                        // UTType(importedAs:) accepts third-party types (Chromium, Slack, …)
                        // that are not declared in our Info.plist; the system may log a warning
                        // we intentionally ignore.
                        let resolvedType = UTType(rawType) ?? UTType(importedAs: rawType)
                        return RawRepresentation(rawType: rawType, type: resolvedType, data: data)
                    }
                )
            },
            source: resolveSource()
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
            },
            source: nil
        )
        #endif
    }

    #if os(macOS)
    /// Prefer `org.nspasteboard.source`; otherwise infer from the frontmost app.
    private func resolveSource() -> PasteboardSource {
        let sourceType = NSPasteboard.PasteboardType("org.nspasteboard.source")
        if let declared = pasteboard.string(forType: sourceType) {
            if declared.isEmpty {
                return PasteboardSource(
                    bundleIdentifier: nil,
                    displayName: nil,
                    attribution: .unknown
                )
            }
            let running = NSRunningApplication.runningApplications(withBundleIdentifier: declared).first
            return PasteboardSource(
                bundleIdentifier: declared,
                displayName: running?.localizedName ?? declared,
                attribution: .declared
            )
        }

        let frontmost = NSWorkspace.shared.frontmostApplication
        return PasteboardSource(
            bundleIdentifier: frontmost?.bundleIdentifier,
            displayName: frontmost?.localizedName,
            attribution: .frontmost
        )
    }
    #endif
}

@MainActor
final class FakePasteboardReader: ClipboardReading {
    var snapshotToReturn = PasteboardSnapshot(items: [])
    func readSnapshot() -> PasteboardSnapshot { snapshotToReturn }
}
