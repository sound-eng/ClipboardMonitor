//
//  ClipboardMonitorApp.swift
//  ClipboardMonitor
//

import SwiftUI
import SwiftData

@main
struct ClipboardMonitorApp: App {
    private let sharedModelContainer: ModelContainer
    @State private var repository: SwiftDataSnapshotRepository
    @State private var preferences: AppPreferences
    @State private var showPreferences = false

    init() {
        let preferences = AppPreferences()
        let schema = Schema([
            PersistedSnapshot.self,
            PersistedRepresentation.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            sharedModelContainer = container
            // Create the repository once with the container's main context so the
            // same instance is observed by RootView for the app lifetime.
            _repository = State(
                initialValue: SwiftDataSnapshotRepository(
                    modelContext: container.mainContext,
                    maxCount: preferences.maxSnapshots
                )
            )
            _preferences = State(initialValue: preferences)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(
                repository: repository,
                preferences: preferences,
                showPreferences: $showPreferences
            )
        }
        .modelContainer(sharedModelContainer)
        #if os(macOS)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Preferences…") {
                    showPreferences = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
        #endif
    }
}
