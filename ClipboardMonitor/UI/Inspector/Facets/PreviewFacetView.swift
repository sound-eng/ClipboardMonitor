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
            case .richText(let attributed):
                richTextPreview(attributed)
            case .html(let source):
                htmlPreview(source)
            case .color:
                colorPreview
            case .unknown:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func richTextPreview(_ attributed: AttributedString) -> some View {
        // Attributes stay untouched; only the chrome matches the document "paper"
        // so themed Overview chrome doesn't clash with RTF backgrounds.
        Text(attributed)
            .frame(maxWidth: .infinity, alignment: .leading)
            .textSelection(.enabled)
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .background(documentPaperColor(for: attributed), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(.quaternary)
            )
    }

    /// Minimal HTML preview: Foundation's HTML → attributed text (no WebKit / JS).
    @ViewBuilder
    private func htmlPreview(_ source: String) -> some View {
        if let attributed = attributedString(fromHTML: source) {
            Text(attributed)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .padding(12)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .background(documentPaperColor(for: attributed), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(.quaternary)
                )
        } else {
            // Fall back to a short source snippet when HTML can't be rendered.
            Text(source)
                .font(.system(.body, design: .monospaced))
                .lineLimit(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .padding(12)
                .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(.quaternary)
                )
        }
    }

    private func attributedString(fromHTML source: String) -> AttributedString? {
        guard let data = source.data(using: .utf8) else { return nil }
        do {
            let ns = try NSAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html,
                    .characterEncoding: String.Encoding.utf8.rawValue
                ],
                documentAttributes: nil
            )
            return AttributedString(ns)
        } catch {
            return nil
        }
    }

    /// Card fill for rich-text preview: dominant run background when it covers most
    /// of the string (document paper), otherwise the system text-background color.
    private func documentPaperColor(for attributed: AttributedString) -> Color {
        #if os(macOS)
        let ns = NSAttributedString(attributed)
        let fullLength = max(ns.length, 1)
        var best: (color: NSColor, length: Int)?

        ns.enumerateAttribute(
            .backgroundColor,
            in: NSRange(location: 0, length: ns.length)
        ) { value, range, _ in
            guard let color = value as? NSColor else { return }
            if best == nil || range.length > best!.length {
                best = (color, range.length)
            }
        }

        // Only promote a run background to "paper" when it covers most of the text;
        // short highlight backgrounds (yellow, etc.) must not become the card fill.
        if let best, Double(best.length) / Double(fullLength) >= 0.5 {
            return Color(nsColor: best.color)
        }
        return Color(nsColor: .textBackgroundColor)
        #else
        let ns = NSAttributedString(attributed)
        let fullLength = max(ns.length, 1)
        var best: (color: UIColor, length: Int)?

        ns.enumerateAttribute(
            .backgroundColor,
            in: NSRange(location: 0, length: ns.length)
        ) { value, range, _ in
            guard let color = value as? UIColor else { return }
            if best == nil || range.length > best!.length {
                best = (color, range.length)
            }
        }

        if let best, Double(best.length) / Double(fullLength) >= 0.5 {
            return Color(uiColor: best.color)
        }
        return Color(uiColor: .systemBackground)
        #endif
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
