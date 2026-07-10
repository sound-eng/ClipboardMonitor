//
//  UTType+Raw.swift
//  ClipboardMonitor
//

import UniformTypeIdentifiers

extension UTType {
    /// Custom Pasteboard uniform type id to represent color, for cleaner code.
    static let appleColor = UTType("com.apple.cocoa.pasteboard.color")
        ?? UTType(importedAs: "com.apple.cocoa.pasteboard.color")

    /// Flattened RTF payload commonly used on the macOS pasteboard.
    static let flatRTF = UTType("com.apple.flat-rtf")
        ?? UTType(importedAs: "com.apple.flat-rtf")

    /// Flattened RTFD (RTF + attachments) pasteboard payload.
    static let flatRTFD = UTType("com.apple.flat-rtfd")
        ?? UTType(importedAs: "com.apple.flat-rtfd")
}
