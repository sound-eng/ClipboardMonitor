# Inspector-Centric 3-Pane UI for ClipboardMonitor

The current app has a functional core (monitoring, reading, classifying) but a placeholder UI (`ContentView` using SwiftData's `Item` stub). This plan replaces the placeholder UI with a polished, developer-tool-grade 3-pane inspector interface, while respecting and extending the existing Core/Infra architecture.

---

## Design Reference

The existing mockup (below) shows a 2-pane split with a sidebar. The new UI extends this to **3 panes** and shifts focus from "preview" to "inspection":

![Existing Mockup](Design/clipboard_ui_mockup_1783629861066.png)

**Visual Design Targets:**
- Dark-mode-first, native macOS feel (vibrancy, `.sidebar` material)
- System fonts (`SF Pro`) with `.monospaced` where appropriate (hex, source)
- `NavigationSplitView` for native 3-column support
- Subtle icons via `SF Symbols` (e.g., `doc.on.clipboard`, `waveform.badge.magnifyingglass`)
- Consistent tab bar in the inspector pane (tab strip, not segmented control)

---

## Resolved Design Decisions

> [!NOTE]
> **Persistence**: Snapshots **are persisted to disk** using SwiftData (the `Item` stub is the intended seed for this). The history is capped at **100 snapshots** — oldest entries are evicted when the limit is exceeded. SwiftData `@Model` classes live in `Infra/` to respect the existing platform-boundary convention (Core stays pure Swift/Foundation).

> [!NOTE]
> **Multi-item pasteboard**: The middle pane **flattens all representations across all `RawPasteboardItem`s** in a snapshot. This covers the vast majority of real-world copies and keeps the representation list simple.

---

## Proposed Changes

### Persistence Layer — SwiftData Models in `Infra/`

The Core layer structs (`PasteboardSnapshot`, `RawPasteboardItem`, `RawRepresentation`) remain **pure value types** — they are the currency of the classification pipeline. SwiftData needs `@Model` reference types, so we introduce a parallel set of persisted models in `Infra/` and a mapping layer.

---

#### [NEW] `Infra/Persistence/PersistedSnapshot.swift`

```swift
import SwiftData
import Foundation

/// Persisted representation of a single clipboard capture event.
/// Mirrors `PasteboardSnapshot` but as a SwiftData `@Model` class.
@Model
final class PersistedSnapshot {
    var capturedAt: Date
    // Cascade delete: removing a snapshot removes all its representations.
    @Relationship(deleteRule: .cascade)
    var representations: [PersistedRepresentation]

    init(capturedAt: Date, representations: [PersistedRepresentation]) { ... }
}
```

---

#### [NEW] `Infra/Persistence/PersistedRepresentation.swift`

```swift
import SwiftData
import Foundation

/// Persisted single data-type representation from a pasteboard item.
/// Mirrors `RawRepresentation` but as a SwiftData `@Model` class.
@Model
final class PersistedRepresentation {
    var rawType: String      // e.g. "public.html"
    var data: Data

    init(rawType: String, data: Data) { ... }
}
```

> [!NOTE]
> `UTType?` is **not** persisted — it is a computed/resolved value derived from `rawType` at runtime. This avoids the complexity of serializing `UTType` and keeps the model lean.

---

#### [MODIFY] `Core/SnapshotRepository.swift`

Currently an in-memory `@MainActor` class. It becomes a **protocol** so the UI can inject either the real SwiftData-backed implementation or a fake for previews/tests:

```swift
/// Provides access to the ordered history of clipboard snapshots.
@MainActor
protocol SnapshotRepositoryProtocol: AnyObject {
    var snapshots: [PasteboardSnapshot] { get }
    func add(_ snapshot: PasteboardSnapshot)
}
```

#### [NEW] `Infra/Persistence/SwiftDataSnapshotRepository.swift`

The real implementation, backed by SwiftData:

```swift
/// SwiftData-backed implementation of `SnapshotRepositoryProtocol`.
/// Enforces a rolling cap of `maxCount` snapshots, evicting the oldest on overflow.
@Observable @MainActor
final class SwiftDataSnapshotRepository: SnapshotRepositoryProtocol {
    static let maxCount = 100

    private let modelContext: ModelContext
    // In-memory cache — kept in sync with the persistent store.
    // Avoids re-fetching on every UI read.
    private(set) var snapshots: [PasteboardSnapshot] = []

    init(modelContext: ModelContext) { ... }

    func add(_ snapshot: PasteboardSnapshot) {
        // 1. Map PasteboardSnapshot → PersistedSnapshot
        // 2. Insert into modelContext
        // 3. If count > maxCount, delete oldest PersistedSnapshot
        // 4. Save and refresh in-memory cache
    }
}
```

#### [NEW] `Infra/Persistence/InMemorySnapshotRepository.swift`

A lightweight fake for SwiftUI Previews and unit tests:

```swift
/// In-memory snapshot repository for use in previews and tests.
@Observable @MainActor
final class InMemorySnapshotRepository: SnapshotRepositoryProtocol {
    private(set) var snapshots: [PasteboardSnapshot] = []
    func add(_ snapshot: PasteboardSnapshot) { snapshots.append(snapshot) }
}
```

---

#### [MODIFY] `Item.swift` → [DELETE]

The `Item` SwiftData stub is replaced by `PersistedSnapshot` + `PersistedRepresentation`. `Item.swift` is deleted.

#### [MODIFY] `ClipboardMonitorApp.swift`

Set up the SwiftData schema and inject the real repository:

```swift
var body: some Scene {
    WindowGroup {
        RootView()
            .environment(SwiftDataSnapshotRepository(modelContext: ...))
    }
    .modelContainer(for: [PersistedSnapshot.self, PersistedRepresentation.self])
}
```

---

### Core Layer — New: `InspectorFacet` & extended `ClipboardInspector` protocol

These changes are **additive**; nothing in the existing protocol is removed.

---

#### [NEW] `Core/InspectorFacet.swift`

Defines the vocabulary of what an inspector can expose. Each facet maps to one tab in the right pane.

```swift
/// Represents a single inspection dimension that an inspector supports.
/// For example, an HTML inspector may support .preview, .source, .metadata, .hex.
/// Facets drive the tab bar in the inspector detail pane.
enum InspectorFacet: String, CaseIterable, Identifiable {
    case overview    // Summary card: type, size, encoding
    case preview     // Rendered representation (HTML render, image, color swatch, URL link)
    case source      // Raw decoded text (HTML source, RTF, plain text)
    case metadata    // Structured key-value metadata (dimensions, encoding, URL components)
    case hex         // Raw bytes as hex dump — always available as fallback

    var id: String { rawValue }
    var label: String { ... }        // "Overview", "Preview", etc.
    var systemImage: String { ... }  // SF Symbol name
}
```

---

#### [MODIFY] `Core/ClipboardInspector.swift`

Extend the protocol with two new **optional** requirements (via default implementations so existing inspectors compile without changes):

```swift
protocol ClipboardInspector {
    var supportedTypes: Set<UTType> { get }
    var priority: Int { get }
    func inspect(_ representation: RawRepresentation) -> ClipboardContent?

    /// Facets this inspector supports for a given representation.
    /// Default: [.overview, .hex] — meaningful for all types.
    func supportedFacets(for representation: RawRepresentation) -> [InspectorFacet]
}
```

**No breaking changes** — existing inspectors get `.overview` + `.hex` for free via the default.

---

#### [MODIFY] `Core/SnapshotRepository.swift`

Make it `@Observable` so the UI can reactively bind to the snapshot list without `@Published` boilerplate:

```swift
@Observable
@MainActor
final class SnapshotRepository {
    private(set) var snapshots: [PasteboardSnapshot] = []
    func add(_ snapshot: PasteboardSnapshot) { ... }
}
```

`@Observable` (iOS 17+/macOS 14+ macro) is preferred over `ObservableObject` — it's more granular and avoids redundant view refreshes.

---

### UI Layer — New Group: `UI/`

All UI files live under `ClipboardMonitor/UI/`. This keeps SwiftUI code out of `Core/` and `Infra/`.

```
UI/
├── RootView.swift                  # Replaces ContentView — owns ClipboardController
├── Sidebar/
│   ├── SnapshotSidebarView.swift   # Left pane: list of snapshots
│   └── SnapshotRowView.swift       # Single row: timestamp, type icon, snippet
├── RepresentationList/
│   ├── RepresentationListView.swift # Middle pane: list of RawRepresentations
│   └── RepresentationRowView.swift  # Single row: UTType badge + byte count
└── Inspector/
    ├── InspectorDetailView.swift    # Right pane: tab bar + content switching
    ├── Facets/
    │   ├── OverviewFacetView.swift  # Type, size, source app metadata card
    │   ├── HexFacetView.swift       # Hex dump (works for every representation)
    │   ├── SourceFacetView.swift    # Text/markup rendered as monospaced source
    │   ├── PreviewFacetView.swift   # Type-specific render (image, HTML webview, color)
    │   └── MetadataFacetView.swift  # Key-value table (URL components, image EXIF, etc.)
    └── CompareView.swift            # Side-by-side comparison of two representations
```

---

#### [NEW] `UI/RootView.swift`

Replaces `ContentView`. Owns `ClipboardController` and holds `@State` for the three selection levels:

```swift
struct RootView: View {
    // Single source of truth for the entire app's selection state.
    @State private var selectedSnapshot: PasteboardSnapshot?
    @State private var selectedRepresentation: RawRepresentation?
    @State private var selectedFacet: InspectorFacet = .overview

    // Controller is a @State (not @StateObject) because it's a non-observable value type
    // wrapped in SwiftUI's state system for lifecycle management.
    @State private var controller = ClipboardController()

    var body: some View {
        NavigationSplitView(columnVisibility: ...) {
            SnapshotSidebarView(...)
        } content: {
            RepresentationListView(...)
        } detail: {
            InspectorDetailView(...)
        }
    }
}
```

---

#### [NEW] `UI/Sidebar/SnapshotSidebarView.swift`

- Binds to `SnapshotRepository.snapshots` via `@Environment`
- Each row: timestamp (relative, e.g. "2s ago"), primary content type icon, byte count badge
- Most-recent snapshot auto-selected on first appearance

#### [NEW] `UI/Sidebar/SnapshotRowView.swift`

- Shows `SF Symbol` for the dominant type (image, text, link, color, unknown)
- Relative timestamp ("just now", "3m ago") via `RelativeDateTimeFormatter`
- Subtle highlight on hover + selection accent

---

#### [NEW] `UI/RepresentationList/RepresentationListView.swift`

- Shows all `RawRepresentation`s from the selected snapshot (flattened across items)
- Each row: UTType identifier string (e.g. `public.html`), byte count, check mark if an inspector handles it
- Unknown/unhandled types are shown in muted style — not hidden

#### [NEW] `UI/RepresentationList/RepresentationRowView.swift`

- `UTType` badge rendered as a monospaced pill (e.g. `public.html`)
- Byte count in human-readable form (e.g. `4.2 KB`)
- Small colored dot: green = inspectable, gray = raw/unknown

---

#### [NEW] `UI/Inspector/InspectorDetailView.swift`

- Tab strip across the top (custom `HStack` of tab buttons, not `TabView` — more control over styling)
- Only shows tabs returned by `inspector.supportedFacets(for: representation)`
- Hex is always present as the last tab
- Animates between facets with `.contentTransition(.opacity)`

---

#### [NEW] `UI/Inspector/Facets/HexFacetView.swift`

A proper hex dump view:

```
Offset    Hex                                      ASCII
00000000  48 65 6c 6c 6f 20 57 6f 72 6c 64 0a     Hello World.
```

- `LazyVStack` for performance on large payloads
- Monospaced font, colored columns (offset = `.secondary`, hex bytes = `.primary`, ASCII = `.tertiary`)
- No external dependencies — computed from `Data` directly

---

#### [NEW] `UI/Inspector/Facets/OverviewFacetView.swift`

Card layout with:
- **Type**: `public.html (text/html)`
- **Size**: `4.2 KB (4,312 bytes)`
- **Inspector**: `HTML Inspector` (or `Unknown`)
- **Conformances**: shows UTType conformance chain (e.g. `public.html → public.text → public.data`)

---

#### [NEW] `UI/Inspector/Facets/PreviewFacetView.swift`

Dispatches to the right preview based on `ClipboardContent`:
- `.image(Data)` → `Image(nsImage:)`
- `.url(URL)` → clickable `Link` + favicon attempt
- `.plainText(String, _)` → `Text` in scrollable container
- `.color(Data)` → large color swatch with hex/RGB values
- `.unknown` → "No preview available" empty state

---

#### [NEW] `UI/Inspector/Facets/SourceFacetView.swift`

Raw decoded source as monospaced text:
- HTML, RTF, plain text: decoded `String` in `ScrollView > Text`
- Unknown binary: "Binary data — use Hex tab" empty state with byte count

---

#### [NEW] `UI/Inspector/Facets/MetadataFacetView.swift`

Type-specific structured metadata in a key-value grid:
- **HTML**: detected `<title>`, charset from headers, detected encoding
- **Image**: dimensions (`CGImageSource`), color space, DPI
- **URL**: scheme, host, path, query parameters (parsed `URLComponents`)
- **Color**: hex, RGB float, HSB float, alpha
- **Plain text**: character count, line count, encoding name

---

#### [NEW] `UI/Inspector/CompareView.swift`

Side-by-side split of two selected representations:
- Activated by a toolbar button "Compare…" when ≥2 representations exist
- Shows raw decoded text (or "binary" fallback) side-by-side in a `HStack`
- Simple visual diff highlight (line-by-line color coding: added/removed/unchanged)
- Does not depend on any external diff library — uses simple LCS in a helper

---

### App Entry Point

Covered above in the persistence section — `ClipboardMonitorApp` wires `SwiftDataSnapshotRepository` into the environment and configures the `ModelContainer` for `PersistedSnapshot` + `PersistedRepresentation`.

---

### Inspector Conformances — Extended

#### [MODIFY] `Core/ClipboardInspector.swift` — each concrete inspector

Each inspector gains `supportedFacets(for:)`:

| Inspector | Facets |
|---|---|
| `URLClipboardInspector` | overview, preview, metadata, hex |
| `PlainTextInspector` | overview, preview, source, hex |
| `ImageClipboardInspector` | overview, preview, metadata, hex |
| `ColorClipboardInspector` | overview, preview, metadata, hex |
| _(unknown)_ | overview, hex |

---

## File Deletion

#### [DELETE] `Item.swift`
Replaced by `PersistedSnapshot` + `PersistedRepresentation` in `Infra/Persistence/`.

---

## Verification Plan

### Build & Compile
- `xcodebuild build -scheme ClipboardMonitor` must succeed with zero warnings (treat warnings as errors)

### Manual Verification
1. Launch app → left pane shows empty state ("No clipboard history yet")
2. Copy any text → snapshot appears in left pane automatically
3. Select snapshot → middle pane shows all representations (e.g. `public.utf8-plain-text`, `public.rtf`)
4. Select a representation → right pane shows tabs and inspector content
5. Verify Hex tab renders correctly for all representations
6. Copy an image → image preview renders in Preview tab
7. Copy a URL → URL components visible in Metadata tab
8. Select two representations → Compare button appears → side-by-side diff renders
9. Copy something with 10+ representations → middle pane scrolls, no performance issues
