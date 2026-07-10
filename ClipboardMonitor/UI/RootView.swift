//
//  RootView.swift
//  ClipboardMonitor
//

import SwiftUI
import SwiftData

/// App root: owns selection state, clipboard controller, and the 3-pane split.
struct RootView: View {
    @Bindable var repository: SwiftDataSnapshotRepository

    @State private var controller: ClipboardController
    /// ID-based selection survives repository cache rebuilds after each `add`.
    @State private var selectedSnapshotID: PasteboardSnapshot.ID?
    @State private var selectedRepresentationID: RawRepresentation.ID?
    @State private var isComparing = false

    private let classifier = ClipboardClassifier.default

    init(repository: SwiftDataSnapshotRepository) {
        self.repository = repository
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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if let snapshot = selectedSnapshot, snapshot.representations.count >= 2 {
                    Button("Compare…") { isComparing = true }
                }
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
            controller.start()
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
    }

    var body: some View {
        RootView(repository: repository)
            .modelContainer(container)
    }
}
