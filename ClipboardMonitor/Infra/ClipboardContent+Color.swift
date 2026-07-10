//
//  ClipboardContent+Color.swift
//  ClipboardMonitor
//

import Foundation

extension ClipboardContent {
    var platformColor: PlatformColor? {
        guard case .color(let data) = self else { return nil }
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: PlatformColor.self, from: data)
    }
}
