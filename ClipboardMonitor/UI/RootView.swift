//
//  RootView.swift
//  ClipboardMonitor
//

import SwiftUI
import SwiftData

/// App root: owns selection state, clipboard controller, and the inspector chrome.
struct RootView: View {
    @Bindable var repository: SwiftDataSnapshotRepository
    @Bindable var preferences: AppPreferences
    @Binding var showPreferences: Bool

    @State private var controller: ClipboardController
    /// ID-based selection survives repository cache rebuilds after each `add`.
    @State private var selectedSnapshotID: PasteboardSnapshot.ID?
    @State private var selectedRepresentationID: RawRepresentation.ID?
    @State private var isComparing = false
    /// When true, the inspector tracks the newest snapshot as copies arrive.
    @State private var followLatest = true

    @Environment(\.scenePhase) private var scenePhase

    private let classifier = ClipboardClassifier.default

    init(
        repository: SwiftDataSnapshotRepository,
        preferences: AppPreferences,
        showPreferences: Binding<Bool>
    ) {
        self.repository = repository
        self.preferences = preferences
        _showPreferences = showPreferences
        _controller = State(initialValue: ClipboardController(repository: repository))
    }

    private var selectedSnapshot: PasteboardSnapshot? {
        repository.snapshots.first { $0.id == selectedSnapshotID }
    }

    private var selectedRepresentation: RawRepresentation? {
        guard let snapshot = selectedSnapshot else { return nil }
        let ordered = classifier.orderedRepresentations(snapshot.representations)
        return ordered.first { $0.id == selectedRepresentationID } ?? ordered.first
    }

    private var latestSnapshotID: PasteboardSnapshot.ID? {
        repository.snapshots.first?.id
    }

    private var isShowingLatest: Bool {
        selectedSnapshotID == latestSnapshotID
    }

    /// True when the inspector is pinned to an older snapshot than the newest history entry.
    private var isStale: Bool {
        latestSnapshotID != nil && !isShowingLatest
    }

    /// How many history entries are newer than the current selection (newest-first list).
    private var unseenCount: Int {
        guard let selectedSnapshotID,
              let index = repository.snapshots.firstIndex(where: { $0.id == selectedSnapshotID })
        else { return 0 }
        return index
    }

    var body: some View {
        #if os(iOS)
        inspectorChrome
            .sheet(isPresented: $showPreferences) {
                PreferencesView(preferences: preferences, isPresented: $showPreferences)
            }
            .environment(preferences)
        #else
        ZStack {
            inspectorChrome
                .opacity(showPreferences ? 0 : 1)
                .allowsHitTesting(!showPreferences)

            if showPreferences {
                PreferencesView(preferences: preferences, isPresented: $showPreferences)
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showPreferences)
        .environment(preferences)
        #endif
    }

    // MARK: - Inspector chrome

    private var inspectorChrome: some View {
        NavigationSplitView {
            sidebarColumn
        } detail: {
            VStack(spacing: 0) {
                InspectorDetailView(
                    representation: selectedRepresentation,
                    classifier: classifier,
                    source: selectedSnapshot?.source
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                Divider()

                RepresentationListView(
                    snapshot: selectedSnapshot,
                    selection: $selectedRepresentationID,
                    classifier: classifier
                )
                .frame(minHeight: 140, idealHeight: 200, maxHeight: 280)
            }
            .toolbar {
                followLatestToolbarItem
                compareToolbarItem
            }
        }
        .sheet(isPresented: $isComparing) {
            if let snapshot = selectedSnapshot {
                CompareView(
                    representations: classifier.orderedRepresentations(snapshot.representations),
                    initialLeftID: selectedRepresentationID,
                    classifier: classifier
                )
            }
        }
        .onAppear {
            repository.maxCount = preferences.maxSnapshots
            controller.captureSnapshot()
            applyMonitoringConfiguration()
            if selectedSnapshotID == nil {
                selectedSnapshotID = latestSnapshotID
            }
            selectPrimaryRepresentationIfNeeded()
        }
        .onDisappear {
            controller.stop()
        }
        .onChange(of: repository.snapshots.map(\.id)) { _, newIDs in
            let selectionMissing = selectedSnapshotID == nil
                || selectedSnapshotID.map { !newIDs.contains($0) } == true
            if followLatest || selectionMissing {
                selectedSnapshotID = latestSnapshotID
            }
        }
        .onChange(of: selectedSnapshotID) { _, newID in
            selectPrimaryRepresentation()
            if newID != latestSnapshotID {
                followLatest = false
            }
        }
        .onChange(of: preferences.maxSnapshots) { _, newValue in
            repository.maxCount = newValue
        }
        .onChange(of: preferences.monitorMode) { _, _ in
            applyMonitoringConfiguration()
        }
        .onChange(of: preferences.pollIntervalMilliseconds) { _, _ in
            applyMonitoringConfiguration()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active, preferences.monitorMode == .foreground else { return }
            controller.captureSnapshot()
        }
    }

    /// Gear lives on the sidebar so it remains reachable on iPadOS split columns.
    private var sidebarColumn: some View {
        SnapshotSidebarView(
            snapshots: repository.snapshots,
            selection: $selectedSnapshotID
        )
        .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 300)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showPreferences = true
                } label: {
                    Label("Preferences", systemImage: "gearshape")
                }
                .help("Preferences")
            }
        }
    }

    private var canCompare: Bool {
        !showPreferences
            && (selectedSnapshot?.representations.count ?? 0) >= 2
    }

    @ToolbarContentBuilder
    private var followLatestToolbarItem: some ToolbarContent {
        if !showPreferences, isStale {
            ToolbarItem(placement: .primaryAction) {
                Button(action: followLatestSnapshot) {
                    Label("Follow Latest", systemImage: "arrow.down.to.line")
                }
                .help("Show the latest clipboard snapshot and keep following new copies")
                .badge(unseenCount)
            }
        }
    }

    @ToolbarContentBuilder
    private var compareToolbarItem: some ToolbarContent {
        if canCompare {
            ToolbarItem(placement: .primaryAction) {
                Button("Compare…") { isComparing = true }
            }
        }
    }

    // MARK: - Monitoring

    private func applyMonitoringConfiguration() {
        controller.stop()
        switch preferences.monitorMode {
        case .polling:
            controller.start(
                monitor: ClipboardMonitor(pollingInterval: preferences.pollInterval)
            )
        case .foreground:
            // No polling task — capture now, then again whenever the scene activates.
            controller.captureSnapshot()
        }
    }

    // MARK: - Selection

    private func followLatestSnapshot() {
        followLatest = true
        selectedSnapshotID = latestSnapshotID
    }

    /// Prefer the highest-priority inspectable representation when a snapshot is selected.
    private func selectPrimaryRepresentation() {
        guard let snapshot = selectedSnapshot else {
            selectedRepresentationID = nil
            return
        }
        selectedRepresentationID = classifier.primaryRepresentation(in: snapshot.representations)?.id
    }

    private func selectPrimaryRepresentationIfNeeded() {
        guard selectedRepresentationID == nil else { return }
        selectPrimaryRepresentation()
    }
}

#Preview {
    PreviewRoot()
}

/// In-memory SwiftData host used only by `#Preview`.
private struct PreviewRoot: View {
    private let container: ModelContainer
    private let repository: SwiftDataSnapshotRepository
    private let preferences: AppPreferences

    init() {
        let schema = Schema([PersistedSnapshot.self, PersistedRepresentation.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        let repository = SwiftDataSnapshotRepository(modelContext: container.mainContext)
        for snapshot in PreviewData.snapshots {
            repository.add(snapshot)
        }
        self.container = container
        self.repository = repository
        self.preferences = AppPreferences(defaults: UserDefaults(suiteName: "preview.ClipboardMonitor")!)
    }

    var body: some View {
        RootView(
            repository: repository,
            preferences: preferences,
            showPreferences: .constant(false)
        )
            .modelContainer(container)
    }
}
