//
//  ClipboardMonitorApp.swift
//  ClipboardMonitor
//

import SwiftUI
import SwiftData

#if os(macOS)
import AppKit

/// Keeps the process alive after the main window closes so it can be reopened.
final class AppDelegate: NSObject, NSApplicationDelegate {
    static private(set) var shared: AppDelegate?

    /// Installed from SwiftUI with `openWindow(id: "main")` — survives window close.
    var reopenMainWindow: (() -> Void)?

    override init() {
        super.init()
        Self.shared = self
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldHandleReopen(
        _ sender: NSApplication,
        hasVisibleWindows flag: Bool
    ) -> Bool {
        if !flag {
            reopenMainWindow?()
        }
        return true
    }
}
#endif

@main
struct ClipboardMonitorApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    #endif

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
        #if os(macOS)
        Window("ClipboardMonitor", id: "main") {
            rootContent
                .background(WindowReopenInstaller())
        }
        .modelContainer(sharedModelContainer)
        .commands {
            OpenMainWindowCommands()
            CommandGroup(replacing: .appSettings) {
                Button("Preferences…") {
                    showPreferences = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
        #else
        WindowGroup {
            rootContent
        }
        .modelContainer(sharedModelContainer)
        #endif
    }

    private var rootContent: some View {
        RootView(
            repository: repository,
            preferences: preferences,
            showPreferences: $showPreferences
        )
    }
}

#if os(macOS)
/// Explicit Window-menu item — `Commands` stay alive after the window is closed.
private struct OpenMainWindowCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(after: .windowList) {
            Button("ClipboardMonitor") {
                openMainWindow()
            }
        }
    }

    private func openMainWindow() {
        openWindow(id: "main")
        AppDelegate.shared?.reopenMainWindow = { openWindow(id: "main") }
    }
}

/// Captures `openWindow` for Dock reopen after the window view is torn down.
private struct WindowReopenInstaller: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
            .onAppear {
                AppDelegate.shared?.reopenMainWindow = {
                    openWindow(id: "main")
                }
            }
    }
}
#endif
