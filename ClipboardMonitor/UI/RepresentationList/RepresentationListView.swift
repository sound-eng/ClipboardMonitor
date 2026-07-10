//
//  RepresentationListView.swift
//  ClipboardMonitor
//

import SwiftUI

/// Middle pane: flattened list of every representation in the selected snapshot.
struct RepresentationListView: View {
    let snapshot: PasteboardSnapshot?
    @Binding var selection: RawRepresentation.ID?
    let classifier: ClipboardClassifier

    var body: some View {
        Group {
            if let snapshot {
                let reps = classifier.orderedRepresentations(snapshot.representations)
                if reps.isEmpty {
                    ContentUnavailableView(
                        "No representations",
                        systemImage: "tray",
                        description: Text("This snapshot has no pasteboard data.")
                    )
                } else {
                    List(reps, selection: $selection) { representation in
                        RepresentationRowView(
                            representation: representation,
                            isInspectable: classifier.inspector(for: representation) != nil
                        )
                        .tag(representation.id)
                    }
                }
            } else {
                ContentUnavailableView(
                    "Select a snapshot",
                    systemImage: "sidebar.left",
                    description: Text("Choose an entry from History.")
                )
            }
        }
        .navigationTitle("Representations")
    }
}
