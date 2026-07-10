//
//  PreferencesView.swift
//  ClipboardMonitor
//

import SwiftUI

/// Full-window settings surface. Replaces the inspector chrome while presented.
struct PreferencesView: View {
    @Bindable var preferences: AppPreferences
    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            Form {
                historySection
                hexSection
                monitoringSection
                layoutSection
            }
            .formStyle(.grouped)
            .navigationTitle("Preferences")
            #if os(macOS)
            .navigationSubtitle("ClipboardMonitor")
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.borderless)
                    .help("Close")
                    .keyboardShortcut(.cancelAction)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }

    // MARK: - Sections

    private var historySection: some View {
        Section {
            Stepper(value: $preferences.maxSnapshots, in: AppPreferences.maxSnapshotsRange, step: 10) {
                LabeledContent("Maximum snapshots") {
                    Text("\(preferences.maxSnapshots)")
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Label("History", systemImage: "clock")
        } footer: {
            Text("Oldest entries are removed when the limit is exceeded.")
        }
    }

    private var hexSection: some View {
        Section {
            Picker(selection: $preferences.maxHexDisplayBytes) {
                ForEach(AppPreferences.hexSizeChoices, id: \.self) { bytes in
                    Text(Formatters.bytes(bytes)).tag(bytes)
                }
            } label: {
                Label("Hex display limit", systemImage: "number")
            }
            #if os(macOS)
            .pickerStyle(.menu)
            #endif
        } header: {
            Label("Inspector", systemImage: "waveform.badge.magnifyingglass")
        } footer: {
            Text("Larger binaries skip the hex dump so the UI stays responsive.")
        }
    }

    private var monitoringSection: some View {
        Section {
            #if os(macOS)
            Picker(selection: $preferences.monitorMode) {
                ForEach(AppPreferences.MonitorMode.allCases) { mode in
                    Label(mode.title, systemImage: mode.systemImage).tag(mode)
                }
            } label: {
                Label("Monitor mode", systemImage: "dot.radiowaves.left.and.right")
            }
            .pickerStyle(.inline)
            #else
            LabeledContent {
                Text(AppPreferences.MonitorMode.foreground.title)
                    .foregroundStyle(.secondary)
            } label: {
                Label("Monitor mode", systemImage: "dot.radiowaves.left.and.right")
            }
            #endif

            #if os(macOS)
            Picker(selection: $preferences.pollIntervalMilliseconds) {
                ForEach(AppPreferences.pollIntervalChoices, id: \.self) { ms in
                    Text(pollLabel(ms)).tag(ms)
                }
            } label: {
                Label("Poll rate", systemImage: "timer")
            }
            .pickerStyle(.menu)
            .disabled(preferences.monitorMode != .polling)
            #endif
        } header: {
            Label("Monitoring", systemImage: "eye")
        } footer: {
            #if os(iOS)
            Text("iOS captures the pasteboard when the app becomes active.")
            #else
            Text(monitoringFooter)
            #endif
        }
    }

    private var layoutSection: some View {
        Section {
            Picker(selection: $preferences.representationsLayout) {
                ForEach(AppPreferences.RepresentationsLayout.allCases) { layout in
                    Label(layout.title, systemImage: layout.systemImage).tag(layout)
                }
            } label: {
                Label("Representations", systemImage: "rectangle.split.3x1")
            }
            #if os(macOS)
            .pickerStyle(.inline)
            #endif
        } header: {
            Label("Layout", systemImage: "rectangle.3.group")
        } footer: {
            Text("Middle column keeps the classic three-pane inspector; bottom pane stacks representations under the detail view.")
        }
    }

    private var monitoringFooter: String {
        switch preferences.monitorMode {
        case .polling:
            return "Polls the pasteboard on an interval and records each change."
        case .foreground:
            return "Captures the pasteboard only when ClipboardMonitor is brought to the foreground."
        }
    }

    private func pollLabel(_ milliseconds: Int) -> String {
        if milliseconds < 1_000 {
            return "\(milliseconds) ms"
        }
        let seconds = Double(milliseconds) / 1_000
        return seconds == seconds.rounded()
            ? "\(Int(seconds)) s"
            : String(format: "%.1f s", seconds)
    }
}

#Preview {
    PreferencesView(
        preferences: AppPreferences(),
        isPresented: .constant(true)
    )
}
