//
//  PlatformTypes.swift
//  ClipboardMonitor
//

#if os(macOS)
import AppKit
typealias PlatformImage = NSImage
typealias PlatformColor = NSColor
typealias PlatformPasteboard = NSPasteboard
#else
import UIKit
typealias PlatformImage = UIImage
typealias PlatformColor = UIColor
typealias PlatformPasteboard = UIPasteboard
#endif
