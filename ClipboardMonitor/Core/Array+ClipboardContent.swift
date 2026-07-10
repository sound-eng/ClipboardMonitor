//
//  Array+ClipboardContent.swift
//  ClipboardMonitor
//

import Foundation

extension Array where Element == ClipboardContent {
    /// Extracts primary clipboard item from content array
    ///
    var primary: ClipboardContent? {
        first { if case .unknown = $0 { return false }; return true } ?? first
    }
}
