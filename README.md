# ClipboardMonitor

Developer-oriented clipboard inspector for Apple platforms. It watches the pasteboard, captures each change as a snapshot, and lets you inspect every representation the system exposes — not just the “obvious” text or image.

**Current release: 0.2.0**

## What it does

- Polls the system pasteboard and records changes automatically
- Classifies representations (plain text, rich text, URL, image, color, and unknowns)
- Shows a three-pane inspector UI:
  - **History** - recent snapshots with readable titles
  - **Representations** - all UTTypes in the selected snapshot (primary first)
  - **Inspector** - overview (with inline preview), source, metadata, hex, and compare
- Persists up to 100 snapshots with SwiftData (oldest entries are evicted)

## Requirements

- Xcode 16+ (project targets macOS 15.7+)
- macOS recommended for the full inspector experience (iOS plumbing exists in Core/Infra)

## Getting started

1. Open `ClipboardMonitor.xcodeproj` in Xcode
2. Select the **ClipboardMonitor** scheme
3. Run on **My Mac**
4. Copy something - a new snapshot should appear in History

```bash
# Build
xcodebuild -scheme ClipboardMonitor -destination 'platform=macOS' build

# Unit tests
xcodebuild -scheme ClipboardMonitor -destination 'platform=macOS' test
```

## Architecture

```
ClipboardMonitor/
├── Core/          # Pure domain: snapshots, classifiers, inspectors, repository protocol
├── Infra/         # Platform + persistence: pasteboard I/O, SwiftData models
└── UI/            # SwiftUI 3-pane inspector
```

- **Core** stays free of AppKit/UIKit/SwiftData
- **Infra** maps pasteboard bytes ↔ domain types and owns `@Model` persistence
- **UI** binds to `SnapshotRepositoryProtocol` implementations

Design notes and the original UI plan live in [`Design/implementation_plan.md`](Design/implementation_plan.md).

## Primary representation

When a snapshot has several supported types, the **primary** one (shown first and selected by default) prefers representations that expose a **Metadata** facet, then falls back to inspector priority (color → image → text → URL).

## Changelog

See [CHANGELOG.md](CHANGELOG.md).
