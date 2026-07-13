//
//  FullWindowImagePreview.swift
//  ClipboardMonitor
//

import SwiftUI

#if os(macOS)
import AppKit
#else
import UIKit
#endif

// MARK: - Presentation

private struct PresentImagePreviewKey: EnvironmentKey {
    static let defaultValue: (Data) -> Void = { _ in }
}

extension EnvironmentValues {
    /// Opens the full-window image lightbox owned by `RootView`.
    var presentImagePreview: (Data) -> Void {
        get { self[PresentImagePreviewKey.self] }
        set { self[PresentImagePreviewKey.self] = newValue }
    }
}

// MARK: - Lightbox

/// Full-window image lightbox: fits the image, dismiss via ✕, Esc, or swipe down.
struct FullWindowImagePreview: View {
    let data: Data
    @Binding var isPresented: Bool

    @State private var dragOffset: CGFloat = 0
    @State private var isDragging = false

    private let dismissThreshold: CGFloat = 120

    var body: some View {
        ZStack {
            Color.black
                .opacity(0.92 * (1.0 - dismissProgress * 0.55))
                .ignoresSafeArea()

            imageContent
                .padding(24)
                .offset(y: dragOffset)
                .opacity(1.0 - dismissProgress * 0.35)

            VStack {
                HStack {
                    Spacer()
                    closeButton
                }
                Spacer()
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .gesture(swipeDownGesture)
        .animation(isDragging ? nil : .spring(response: 0.28, dampingFraction: 0.86), value: dragOffset)
        #if os(macOS)
        .onExitCommand(perform: close)
        #endif
        .accessibilityAddTraits(.isModal)
    }

    // MARK: - Content

    @ViewBuilder
    private var imageContent: some View {
        #if os(macOS)
        if let nsImage = NSImage(data: data) {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel("Image preview")
        } else {
            unreadableLabel
        }
        #else
        if let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel("Image preview")
        } else {
            unreadableLabel
        }
        #endif
    }

    private var unreadableLabel: some View {
        Text("Unreadable image")
            .foregroundStyle(.white.opacity(0.7))
    }

    private var closeButton: some View {
        Button(action: close) {
            Image(systemName: "xmark")
                .font(.body.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))
                .frame(width: 32, height: 32)
                .background(.ultraThinMaterial.opacity(0.55), in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.borderless)
        .keyboardShortcut(.cancelAction)
        .help("Close")
        .accessibilityLabel("Close image preview")
    }

    // MARK: - Gestures

    private var swipeDownGesture: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                isDragging = true
                // Only follow downward pull; upward stays at rest.
                dragOffset = max(0, value.translation.height)
            }
            .onEnded { value in
                isDragging = false
                let shouldDismiss = value.translation.height > dismissThreshold
                    || value.predictedEndTranslation.height > dismissThreshold * 1.6
                if shouldDismiss {
                    close()
                } else {
                    dragOffset = 0
                }
            }
    }

    private var dismissProgress: CGFloat {
        min(1, dragOffset / dismissThreshold)
    }

    private func close() {
        isPresented = false
        dragOffset = 0
    }
}

#Preview {
    FullWindowImagePreview(
        data: Data(),
        isPresented: .constant(true)
    )
}
