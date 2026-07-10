# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
