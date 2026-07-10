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
                List(snapshots, selection: $selection) { snapshot in
                    SnapshotRowView(snapshot: snapshot)
                        .tag(snapshot.id)
                }
            }
        }
        .navigationTitle("History")
#if os(macOS)
        .listStyle(.sidebar)
#endif
    }
}
