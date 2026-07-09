
final class ClipboardClassifier {
    var inspectors: [ClipboardInspector]

    init(inspectors: [ClipboardInspector]) {
        self.inspectors = inspectors.sorted { $0.priority > $1.priority }
    }

    func classify(_ item: RawPasteboardItem) -> ClipboardContent? {
        // Index representations by type once, then hand inspectors only what they declare interest in:
        let byType = Dictionary(grouping: item.representations, by: \.type)

        for inspector in inspectors {
            for type in inspector.supportedTypes {
                if let rep = byType[type]?.first, let content = inspector.inspect(rep) {
                    return content
                }
            }
        }
        return nil
    }
}