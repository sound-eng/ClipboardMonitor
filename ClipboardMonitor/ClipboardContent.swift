enum ClipboardContent {
    case url(URL)
    case image(NSImage)
    case plainText(String)
    case color(NSColor)
    case unknown(RawPasteboardItem)
    // extend as needed
}