//
//  MetadataFacetView.swift
//  ClipboardMonitor
//

import SwiftUI
import ImageIO
import UniformTypeIdentifiers

#if os(macOS)
import AppKit
#endif

/// Structured key-value metadata for the selected representation.
struct MetadataFacetView: View {
    let representation: RawRepresentation
    let content: ClipboardContent

    var body: some View {
        let rows = metadataRows
        if rows.isEmpty {
            ContentUnavailableView(
                "No metadata",
                systemImage: "list.bullet.rectangle",
                description: Text("Nothing structured to show for this type.")
            )
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(rows) { row in
                        metadataRow(row.key, value: row.value)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
            }
        }
    }

    private func metadataRow(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased())
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body.monospaced())
                .textSelection(.enabled)
        }
    }

    private struct Row: Identifiable {
        let id: String
        let key: String
        let value: String
    }

    private var metadataRows: [Row] {
        switch content {
        case .url(let raw, let parsed):
            return urlRows(raw: raw, parsed: parsed)
        case .image(let data):
            return imageRows(data)
        case .plainText(let text, let encoding):
            return plainTextRows(text, encoding: encoding)
        case .richText(let attributed):
            return richTextRows(attributed)
        case .html(let source):
            return htmlRows(source)
        case .color:
            return colorRows
        case .unknown:
            return unknownRows
        }
    }

    // MARK: - Per type

    private func urlRows(raw: String, parsed: URL?) -> [Row] {
        var rows = [Row(id: "raw", key: "Raw", value: raw)]
        guard let components = parsed.flatMap({ URLComponents(url: $0, resolvingAgainstBaseURL: false) })
                ?? URLComponents(string: raw) else {
            return rows
        }
        if let scheme = components.scheme {
            rows.append(Row(id: "scheme", key: "Scheme", value: scheme))
        }
        if let host = components.host {
            rows.append(Row(id: "host", key: "Host", value: host))
        }
        if let port = components.port {
            rows.append(Row(id: "port", key: "Port", value: String(port)))
        }
        rows.append(Row(id: "path", key: "Path", value: components.path.isEmpty ? "/" : components.path))
        if let query = components.query, !query.isEmpty {
            rows.append(Row(id: "query", key: "Query", value: query))
        }
        for item in components.queryItems ?? [] {
            rows.append(Row(id: "q-\(item.name)", key: item.name, value: item.value ?? ""))
        }
        if let fragment = components.fragment {
            rows.append(Row(id: "fragment", key: "Fragment", value: fragment))
        }
        return rows
    }

    private func imageRows(_ data: Data) -> [Row] {
        var rows: [Row] = [
            Row(id: "bytes", key: "Bytes", value: Formatters.bytes(data.count))
        ]
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            return rows
        }
        if let width = props[kCGImagePropertyPixelWidth] {
            rows.append(Row(id: "width", key: "Width", value: "\(width) px"))
        }
        if let height = props[kCGImagePropertyPixelHeight] {
            rows.append(Row(id: "height", key: "Height", value: "\(height) px"))
        }
        if let space = props[kCGImagePropertyColorModel] {
            rows.append(Row(id: "color", key: "Color model", value: "\(space)"))
        }
        if let dpiX = props[kCGImagePropertyDPIWidth] {
            rows.append(Row(id: "dpiX", key: "DPI (X)", value: "\(dpiX)"))
        }
        if let dpiY = props[kCGImagePropertyDPIHeight] {
            rows.append(Row(id: "dpiY", key: "DPI (Y)", value: "\(dpiY)"))
        }
        if let uti = CGImageSourceGetType(source) {
            rows.append(Row(id: "uti", key: "Image UTI", value: uti as String))
        }
        return rows
    }

    private func plainTextRows(_ text: String, encoding: String.Encoding) -> [Row] {
        let lines = text.components(separatedBy: .newlines).count
        return [
            Row(id: "chars", key: "Characters", value: "\(text.count)"),
            Row(id: "lines", key: "Lines", value: "\(lines)"),
            Row(id: "encoding", key: "Encoding", value: encodingName(encoding))
        ]
    }

    private func richTextRows(_ attributed: AttributedString) -> [Row] {
        let plain = String(attributed.characters)
        let lines = plain.components(separatedBy: .newlines).count
        return [
            Row(id: "chars", key: "Characters", value: "\(plain.count)"),
            Row(id: "lines", key: "Lines", value: "\(lines)"),
            Row(id: "runs", key: "Attribute runs", value: "\(attributed.runs.count)")
        ]
    }

    private func htmlRows(_ source: String) -> [Row] {
        var rows = [
            Row(id: "chars", key: "Characters", value: "\(source.count)"),
            Row(id: "lines", key: "Lines", value: "\(source.components(separatedBy: .newlines).count)"),
            Row(id: "encoding", key: "Encoding", value: "UTF-8")
        ]
        if let title = htmlTitle(in: source) {
            rows.insert(Row(id: "title", key: "Title", value: title), at: 0)
        }
        if let charset = htmlCharset(in: source) {
            rows.append(Row(id: "charset", key: "Declared charset", value: charset))
        }
        return rows
    }

    private var colorRows: [Row] {
        guard let color = content.platformColor else {
            return [Row(id: "err", key: "Color", value: "Unreadable")]
        }
        #if os(macOS)
        let converted = color.usingColorSpace(.deviceRGB) ?? color
        let r = converted.redComponent
        let g = converted.greenComponent
        let b = converted.blueComponent
        let a = converted.alphaComponent
        var h: CGFloat = 0, s: CGFloat = 0, br: CGFloat = 0, aa: CGFloat = 0
        converted.getHue(&h, saturation: &s, brightness: &br, alpha: &aa)
        let hex = String(
            format: "#%02X%02X%02X",
            Int((r * 255).rounded()),
            Int((g * 255).rounded()),
            Int((b * 255).rounded())
        )
        return [
            Row(id: "hex", key: "Hex", value: hex),
            Row(id: "rgb", key: "RGB", value: String(format: "%.3f, %.3f, %.3f", r, g, b)),
            Row(id: "hsb", key: "HSB", value: String(format: "%.3f, %.3f, %.3f", h, s, br)),
            Row(id: "alpha", key: "Alpha", value: String(format: "%.3f", a))
        ]
        #else
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        var h: CGFloat = 0, s: CGFloat = 0, br: CGFloat = 0, aa: CGFloat = 0
        color.getHue(&h, saturation: &s, brightness: &br, alpha: &aa)
        let hex = String(
            format: "#%02X%02X%02X",
            Int((r * 255).rounded()),
            Int((g * 255).rounded()),
            Int((b * 255).rounded())
        )
        return [
            Row(id: "hex", key: "Hex", value: hex),
            Row(id: "rgb", key: "RGB", value: String(format: "%.3f, %.3f, %.3f", r, g, b)),
            Row(id: "hsb", key: "HSB", value: String(format: "%.3f, %.3f, %.3f", h, s, br)),
            Row(id: "alpha", key: "Alpha", value: String(format: "%.3f", a))
        ]
        #endif
    }

    private var unknownRows: [Row] {
        [
            Row(id: "rawType", key: "Raw type", value: representation.rawType),
            Row(id: "bytes", key: "Bytes", value: Formatters.bytes(representation.data.count))
        ]
    }

    private func encodingName(_ encoding: String.Encoding) -> String {
        switch encoding {
        case .utf8: "UTF-8"
        case .utf16: "UTF-16"
        case .utf16BigEndian: "UTF-16 BE"
        case .utf16LittleEndian: "UTF-16 LE"
        case .ascii: "ASCII"
        default: "\(encoding.rawValue)"
        }
    }

    private func htmlTitle(in source: String) -> String? {
        // Lightweight scrape — good enough for clipboard HTML without pulling in a parser.
        guard let regex = try? NSRegularExpression(
            pattern: #"<title[^>]*>(.*?)</title>"#,
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else { return nil }
        let range = NSRange(source.startIndex..<source.endIndex, in: source)
        guard let match = regex.firstMatch(in: source, range: range),
              let titleRange = Range(match.range(at: 1), in: source) else { return nil }
        return String(source[titleRange]).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func htmlCharset(in source: String) -> String? {
        // <meta charset="utf-8"> or <meta http-equiv="content-type" content="…charset=…">
        let patterns = [
            #"<meta[^>]+charset\s*=\s*["']?\s*([a-zA-Z0-9_\-]+)"#,
            #"charset\s*=\s*["']?\s*([a-zA-Z0-9_\-]+)"#
        ]
        let range = NSRange(source.startIndex..<source.endIndex, in: source)
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
                  let match = regex.firstMatch(in: source, range: range),
                  let charsetRange = Range(match.range(at: 1), in: source) else { continue }
            return String(source[charsetRange])
        }
        return nil
    }
}
