//
//  ClipboardContent.swift
//  ClipboardMonitor
//
//  Created by Oleh Naumenko on 09.07.2026.
//

import Foundation

enum ClipboardContent {
    case url(URL)
    case image(PlatformImage)
    case plainText(String, String.Encoding)
    case color(PlatformColor)
    case unknown(RawRepresentation)
    // extend as needed
}

extension ClipboardContent: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .url(let url):
            return "URL: \(url)"
        case .image:
            return "Image"
        case .plainText(let text, let encoding):
            return "Plain Text: \(text) (Encoding: \(encoding))"
        case .color(let color):
            return "Color: \(color)"
        case .unknown(let rawRepresentation):
            return "Unknown: \(rawRepresentation)"
        }
    }
}
