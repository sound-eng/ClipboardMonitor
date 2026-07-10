//
//  UTType+Raw.swift
//  ClipboardMonitor
//

import UniformTypeIdentifiers

extension UTType {
    /// Custom Pasteboard uniform type id to represent color, for cleaner code.
    static let appleColor = UTType("com.apple.cocoa.pasteboard.color")!
}
