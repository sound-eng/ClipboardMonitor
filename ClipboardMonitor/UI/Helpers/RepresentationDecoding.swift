//
//  RepresentationDecoding.swift
//  ClipboardMonitor
//

import Foundation

enum RepresentationDecoding {
    /// Best-effort text decode for source/compare panes.
    static func text(from data: Data) -> String? {
        if let utf8 = String(data: data, encoding: .utf8) { return utf8 }
        if let utf16 = String(data: data, encoding: .utf16) { return utf16 }
        return nil
    }

    static func text(from representation: RawRepresentation) -> String? {
        text(from: representation.data)
    }
}
