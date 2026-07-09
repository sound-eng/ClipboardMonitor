//
//  Array+ClipboardContent.swift
//  ClipboardMonitor
//
//  Created by Oleh Naumenko on 09.07.2026.
//


extension Array where Element == ClipboardContent {
    var primary: ClipboardContent? {
        first { if case .unknown = $0 { return false }; return true } ?? first
    }
}