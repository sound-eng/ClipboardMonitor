//
//  SnapshotSidebarView.swift
//  ClipboardMonitor
//

import SwiftUI

/// Left pane: chronological list of captured snapshots.
struct SnapshotSidebarView: View {
    let snapshots: [PasteboardSnapshot]
    @Binding var selection: PasteboardSnapshot.ID?

    var body: some View {
        Group {
            if snapshots.isEmpty {
                ContentUnavailableView(
                    "No clipboard history yet",
                    systemImage: "doc.on.clipboard",
                    description: Text("Copy something to start inspecting.")
                )
            } else {
                ScrollViewReader { proxy in
                    List(snapshots, selection: $selection) { snapshot in
                        SnapshotRowView(snapshot: snapshot)
                            .tag(snapshot.id)
                            .id(snapshot.id)
                    }
                    .onChange(of: snapshots.first?.id) { _, latestID in
                        scrollToLatestIfSelected(proxy: proxy, latestID: latestID)
                    }
                    .onChange(of: selection) { _, selectedID in
                        guard selectedID == snapshots.first?.id else { return }
                        scrollToLatestIfSelected(proxy: proxy, latestID: selectedID)
                    }
                }
            }
        }
        .navigationTitle("History")
#if os(macOS)
        .listStyle(.sidebar)
#endif
    }

    /// Pin the newest row fully into view when follow-mode (or equivalent) has it selected.
    private func scrollToLatestIfSelected(
        proxy: ScrollViewProxy,
        latestID: PasteboardSnapshot.ID?
    ) {
        guard let latestID, selection == latestID else { return }
        // Defer until after List inserts/lays out the new row; otherwise it often lands half-clipped.
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(32))
            withAnimation(.easeInOut(duration: 0.2)) {
                proxy.scrollTo(latestID, anchor: .top)
            }
        }
    }
}
