//
//  AppPreferences.swift
//  ClipboardMonitor
//

import Foundation
import Observation

/// User-facing settings persisted in `UserDefaults`.
@Observable
@MainActor
final class AppPreferences {
    enum MonitorMode: String, CaseIterable, Identifiable, Sendable {
        case polling
        case foreground

        var id: String { rawValue }

        var title: String {
            switch self {
            case .polling: "Poll continuously"
            case .foreground: "On foreground only"
            }
        }

        var systemImage: String {
            switch self {
            case .polling: "metronome"
            case .foreground: "arrow.up.forward.app"
            }
        }
    }

    private enum Keys {
        static let maxSnapshots = "preferences.maxSnapshots"
        static let maxHexDisplayBytes = "preferences.maxHexDisplayBytes"
        static let monitorMode = "preferences.monitorMode"
        static let pollIntervalMilliseconds = "preferences.pollIntervalMilliseconds"
        static let hasCompletedPasteAccessOnboarding = "preferences.hasCompletedPasteAccessOnboarding"
    }

    /// Rolling history cap. Oldest snapshots are evicted when exceeded.
    var maxSnapshots: Int {
        didSet { defaults.set(maxSnapshots, forKey: Keys.maxSnapshots) }
    }

    /// Hex facet refuses to materialize dumps larger than this (keeps UI responsive).
    var maxHexDisplayBytes: Int {
        didSet { defaults.set(maxHexDisplayBytes, forKey: Keys.maxHexDisplayBytes) }
    }

    /// How pasteboard changes are observed. On iOS only `.foreground` is available.
    var monitorMode: MonitorMode {
        didSet { defaults.set(monitorMode.rawValue, forKey: Keys.monitorMode) }
    }

    /// Polling interval when `monitorMode == .polling`.
    var pollIntervalMilliseconds: Int {
        didSet { defaults.set(pollIntervalMilliseconds, forKey: Keys.pollIntervalMilliseconds) }
    }

    var pollInterval: Duration {
        .milliseconds(pollIntervalMilliseconds)
    }

    /// iOS-only: first-launch paste-access guidance has been acknowledged.
    /// Unused on macOS; kept in the shared model so preferences stay one type.
    var hasCompletedPasteAccessOnboarding: Bool {
        didSet { defaults.set(hasCompletedPasteAccessOnboarding, forKey: Keys.hasCompletedPasteAccessOnboarding) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let storedMaxSnapshots = defaults.object(forKey: Keys.maxSnapshots) as? Int
        maxSnapshots = Self.clamp(storedMaxSnapshots ?? 100, to: Self.maxSnapshotsRange)

        let storedHex = defaults.object(forKey: Keys.maxHexDisplayBytes) as? Int
        maxHexDisplayBytes = Self.clamp(storedHex ?? 1_048_576, to: Self.maxHexDisplayBytesRange)

        let storedPoll = defaults.object(forKey: Keys.pollIntervalMilliseconds) as? Int
        pollIntervalMilliseconds = Self.clamp(storedPoll ?? 250, to: Self.pollIntervalRange)

        hasCompletedPasteAccessOnboarding = defaults.bool(forKey: Keys.hasCompletedPasteAccessOnboarding)

        #if os(iOS)
        monitorMode = .foreground
        #else
        if let raw = defaults.string(forKey: Keys.monitorMode),
           let mode = MonitorMode(rawValue: raw) {
            monitorMode = mode
        } else {
            monitorMode = .polling
        }
        #endif
    }

    static let maxSnapshotsRange = 10...500
    static let maxHexDisplayBytesRange = 16_384...16_777_216
    static let pollIntervalRange = 100...5_000

    static let pollIntervalChoices = [100, 250, 500, 1_000, 2_000, 5_000]
    static let hexSizeChoices = [
        16_384,
        65_536,
        262_144,
        1_048_576,
        4_194_304,
        16_777_216
    ]

    private static func clamp(_ value: Int, to range: ClosedRange<Int>) -> Int {
        min(max(value, range.lowerBound), range.upperBound)
    }
}
