//
//  PersistedRepresentation.swift
//  ClipboardMonitor
//

import Foundation
import SwiftData

/// SwiftData mirror of `RawRepresentation`.
/// `UTType` is intentionally not stored — re-resolved from `rawType` at load time.
@Model
final class PersistedRepresentation {
    var rawType: String
    var data: Data
    var snapshot: PersistedSnapshot?

    init(rawType: String, data: Data) {
        self.rawType = rawType
        self.data = data
    }
}
