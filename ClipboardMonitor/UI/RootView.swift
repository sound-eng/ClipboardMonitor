//
//  RootView.swift
//  ClipboardMonitor
//

import SwiftUI
import SwiftData

/// App root: owns selection state, clipboard controller, and the 3-pane split.
struct RootView: View {
    @Bindable var repository: SwiftDataSnapshotRepository
    @Bindable var preferences: AppPreferences

    @State private var controller: ClipboardController
    /// ID-based selection survives repository cache rebuilds after each `add`.
    @State private var selectedSnapshotID: PasteboardSnapshot.ID?
    @State private var selectedRepresentationID: RawRepresentation.ID?
    @State private var isComparing = false
    @State private var showPreferences = false

    @Environment(\.scenePhase) private var scenePhase

    private let classifier = ClipboardClassifier.default

    init(repository: SwiftDataSnapshotRepository, preferences: AppPreferences) {
        self.repository = repository
        self.preferences = preferences
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

    var body: some View {
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
    }

    // MARK: - Inspector chrome

    @ViewBuilder
    private var inspectorChrome: some View {
        Group {
            switch preferences.representationsLayout {
            case .middle:
                threeColumnLayout
            case .bottom:
                bottomRepresentationsLayout
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if let snapshot = selectedSnapshot, snapshot.representations.count >= 2 {
                    Button("Compare…") { isComparing = true }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showPreferences = true
                } label: {
                    Label("Preferences", systemImage: "gearshape")
                }
                .help("Preferences")
                .keyboardShortcut(",", modifiers: .command)
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
                selectedSnapshotID = repository.snapshots.first?.id
            }
            selectPrimaryRepresentationIfNeeded()
        }
        .onDisappear {
            controller.stop()
        }
        .onChange(of: repository.snapshots.map(\.id)) { _, newIDs in
            if selectedSnapshotID == nil || selectedSnapshotID.map({ !newIDs.contains($0) }) == true {
                selectedSnapshotID = repository.snapshots.first?.id
            }
        }
        .onChange(of: selectedSnapshotID) { _, _ in
            selectPrimaryRepresentation()
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

    private var threeColumnLayout: some View {
        NavigationSplitView {
            SnapshotSidebarView(
                snapshots: repository.snapshots,
                selection: $selectedSnapshotID
            )
            .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 300)
        } content: {
            RepresentationListView(
                snapshot: selectedSnapshot,
                selection: $selectedRepresentationID,
                classifier: classifier
            )
            .navigationSplitViewColumnWidth(min: 220, ideal: 280, max: 400)
        } detail: {
            InspectorDetailView(
                representation: selectedRepresentation,
                classifier: classifier
            )
        }
    }

    private var bottomRepresentationsLayout: some View {
        NavigationSplitView {
            SnapshotSidebarView(
                snapshots: repository.snapshots,
                selection: $selectedSnapshotID
            )
            .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 300)
        } detail: {
            VStack(spacing: 0) {
                InspectorDetailView(
                    representation: selectedRepresentation,
                    classifier: classifier
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
        RootView(repository: repository, preferences: preferences)
            .modelContainer(container)
    }
}
