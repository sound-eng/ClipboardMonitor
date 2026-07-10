//
//  ClipboardEvent.swift
//  ClipboardMonitor
//

import Foundation

/// Event fired when new clipboard snapshot arrives
/// 
enum ClipboardEvent {
    case changed(changeCount: Int)
}
