//
//  PasteAccessOnboardingView.swift
//  ClipboardMonitor
//

#if os(iOS)
import SwiftUI
import UIKit

/// Opens this app’s page in the Settings app (Paste from Other Apps lives there).
enum PasteAccessSettings {
    static var url: URL {
        URL(string: UIApplication.openSettingsURLString)!
    }
}

/// First-launch guidance for iOS paste permission. Explains how to set
/// Settings → Paste from Other Apps → Allow so captures stop prompting.
struct PasteAccessOnboardingView: View {
    let onOpenSettings: () -> Void
    let onContinue: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    steps
                    tip
                }
                .padding(24)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
            .safeAreaInset(edge: .bottom) {
                actions
            }
            .navigationTitle("Paste Access")
            .navigationBarTitleDisplayMode(.inline)
        }
        .interactiveDismissDisabled()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(Color.accentColor)
                .accessibilityHidden(true)

            Text("Allow clipboard access")
                .font(.title2.weight(.semibold))

            Text(
                "ClipboardMonitor reads the pasteboard to inspect what you copy. On iOS, that requires permission — set it to Allow once so you aren’t asked every time."
            )
            .font(.body)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: 14) {
            stepRow(number: 1, text: "Open Settings for ClipboardMonitor")
            stepRow(number: 2, text: "Tap Paste from Other Apps")
            stepRow(number: 3, text: "Choose Allow")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary.opacity(0.45), in: RoundedRectangle(cornerRadius: 12))
    }

    private func stepRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Color.accentColor, in: Circle())

            Text(text)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var tip: some View {
        Label {
            Text(
                "If Paste from Other Apps isn’t listed yet, tap Continue, allow the system paste prompt once, then open Settings again."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "lightbulb")
                .foregroundStyle(.secondary)
        }
    }

    private var actions: some View {
        VStack(spacing: 10) {
            Button(action: onOpenSettings) {
                Text("Open Settings")
                    .font(.body.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button("Continue", action: onContinue)
                .font(.body.weight(.medium))
                .frame(maxWidth: .infinity)
                .controlSize(.large)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(.bar)
    }
}

#Preview {
    PasteAccessOnboardingView(onOpenSettings: {}, onContinue: {})
}
#endif
