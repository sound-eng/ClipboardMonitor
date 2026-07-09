struct PasteboardSnapshot {
    let items: [RawPasteboardItem]
}

struct RawPasteboardItem {
    let representations: [RawRepresentation]
}

struct RawRepresentation {
    let rawType: String
    let type: UTType?
    let data: Data
}