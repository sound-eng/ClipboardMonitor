//
//  ClipboardContent+Image.swift
//  ClipboardMonitor
//

import Foundation
#if os(macOS)
import AppKit
#else
import UIKit
#endif

extension ClipboardContent {
    var platformImage: PlatformImage? {
        guard case .image(let data) = self else { return nil }
        return PlatformImage(data: data)
    }
}
