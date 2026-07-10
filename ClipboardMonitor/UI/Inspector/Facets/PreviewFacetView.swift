//
//  PreviewFacetView.swift
//  ClipboardMonitor
//

import SwiftUI

#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// Type-specific rendered preview — embedded at the top of Overview when available.
struct PreviewFacetView: View {
    let content: ClipboardContent

    var body: some View {
        Group {
            switch content {
            case .image(let data):
                imagePreview(data)
            case .url(let raw, let parsed):
                urlPreview(raw: raw, parsed: parsed)
            case .plainText(let text, _):
                Text(text)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            case .color:
                colorPreview
            case .unknown:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func imagePreview(_ data: Data) -> some View {
        #if os(macOS)
        if let nsImage = NSImage(data: data) {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: 320)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            Text("Unreadable image")
                .foregroundStyle(.secondary)
        }
        #else
        if let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: 320)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            Text("Unreadable image")
                .foregroundStyle(.secondary)
        }
        #endif
    }

    @ViewBuilder
    private func urlPreview(raw: String, parsed: URL?) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if let parsed {
                Link(destination: parsed) {
                    Label(parsed.absoluteString, systemImage: "link")
                }
            } else {
                Text(raw)
                    .font(.body.monospaced())
                    .textSelection(.enabled)
                Text("Could not parse as URL")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var colorPreview: some View {
        if let color = content.platformColor {
            VStack(alignment: .leading, spacing: 16) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(color))
                    .frame(height: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(.quaternary)
                    )
                Text(colorSummary(color))
                    .font(.body.monospaced())
                    .textSelection(.enabled)
            }
        } else {
            Text("Unreadable color")
                .foregroundStyle(.secondary)
        }
    }

    private func colorSummary(_ color: PlatformColor) -> String {
        #if os(macOS)
        let converted = color.usingColorSpace(.deviceRGB) ?? color
        let r = Int((converted.redComponent * 255).rounded())
        let g = Int((converted.greenComponent * 255).rounded())
        let b = Int((converted.blueComponent * 255).rounded())
        let a = converted.alphaComponent
        return String(format: "#%02X%02X%02X  rgba(%d, %d, %d, %.2f)", r, g, b, r, g, b, a)
        #else
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let ri = Int((r * 255).rounded())
        let gi = Int((g * 255).rounded())
        let bi = Int((b * 255).rounded())
        return String(format: "#%02X%02X%02X  rgba(%d, %d, %d, %.2f)", ri, gi, bi, ri, gi, bi, a)
        #endif
    }
}
