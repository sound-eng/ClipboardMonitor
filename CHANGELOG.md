# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.6.0] - 2026-07-10

### Added

- iOS first-launch paste-access guidance with a direct link to Settings → Paste from Other Apps
- Preferences link on iOS to reopen Paste Settings anytime

### Changed

- Inspector facet tabs (Overview, Metadata, Source, …) collapse to icons when the strip is too narrow for labels
- iOS deployment target lowered to 18.6; app categorized as Utilities

### Fixed

- Follow Latest unseen-count badge now appears on macOS (NSToolbar ignores SwiftUI `.badge`)

## [0.5.0] - 2026-07-10

### Added

- macOS source-app attribution on snapshots: prefer `org.nspasteboard.source`, otherwise infer from the frontmost app
- Source shown in History rows and Overview (declared vs inferred)

### Changed

- URL inspector priority now ranks above plain text when both are present

## [0.4.0] - 2026-07-10

### Added

- **Follow Latest** toolbar control with a badge when the inspector is behind the newest history entry; resumes auto-tracking new copies
- Standard macOS **Preferences…** menu item (⌘,) that opens the in-window preferences pane
- iOS / iPadOS preferences via sheet; gear control lives on the History sidebar so it stays reachable in split view

### Changed

- Inspector chrome is now History + detail with representations stacked under the inspector (middle-column layout option removed)

### Fixed

- Skip capturing a duplicate snapshot on launch / foreground when the pasteboard content is unchanged
- History list scrolls the latest row fully into view while following new copies
- Compare is hidden when unavailable or while Preferences is open
- Preferences were unreachable on iPadOS because the toolbar sat on the outer split-view wrapper

## [0.3.0] - 2026-07-10

### Added

- HTML inspector for `public.html` pasteboard types (source, metadata, hex)
- Minimal HTML Overview preview via Foundation HTML → attributed text (no WebKit)

## [0.2.0] - 2026-07-10

### Added

- Rich text inspector for RTF / RTFD / flat-RTF pasteboard types (`AttributedString`)
- Rich-text Overview preview framed as a document card (attributes unchanged; paper color sniffed from dominant background)
- Metadata for rich text (characters, lines, attribute runs)

### Fixed

- `public.utf16-external-plain-text` decoding: honor BOM and sniff endianness so LE pasteboard data no longer renders as CJK garbage

## [0.1.0] - 2026-07-10

First MVP release: a usable inspector UI on top of the existing clipboard monitoring core.

### Added

- Three-pane SwiftUI inspector (`NavigationSplitView`): History, Representations, Inspector
- Overview facet with inline preview for known content (text, image, URL, color)
- Source, Metadata, and Hex facets; Compare sheet with line-oriented LCS diff
- SwiftData persistence for snapshots (rolling cap of 100)
- `SnapshotRepositoryProtocol` with SwiftData and in-memory implementations
- `InspectorFacet` vocabulary and per-inspector supported facets
- Human-readable sidebar titles from the primary content type
- Primary representation ordering: metadata-capable types first, then inspector priority
- Unit coverage for content titles and representation ordering

### Changed

- Replaced placeholder `ContentView` / `Item` stub with `RootView` and persisted models
- `PasteboardSnapshot` now carries `id` and `capturedAt`
- `ClipboardController` takes an injected snapshot repository

### Removed

- Template `Item.swift` and stub `ContentView.swift`
