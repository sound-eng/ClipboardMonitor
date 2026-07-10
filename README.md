# ClipboardMonitor

Developer-oriented clipboard inspector for Apple platforms. It watches the pasteboard, captures each change as a snapshot, and lets you inspect every representation the system exposes — not just the “obvious” text or image.

**Current release: 0.5.0**

## What it does

- Watches the pasteboard and records each change as a snapshot (macOS: poll or on-foreground; iOS: on-foreground)
- Classifies representations (plain text, rich text, HTML, URL, image, color, and unknowns)
- Shows an inspector UI:
  - **History** - recent snapshots with readable titles
  - **Inspector** - overview (with inline preview), source, metadata, hex, and compare
  - **Representations** - all UTTypes in the selected snapshot (primary first), under the inspector
- **Follow Latest** keeps the inspector on the newest copy, with a badge when you drift behind
- On macOS, attributes each snapshot to a source app (`org.nspasteboard.source` or frontmost inference)
- Preferences for history size, hex display limit, and (macOS) monitoring mode
- Persists snapshots with SwiftData (rolling cap; default 100)

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
└── UI/            # SwiftUI inspector chrome
```

- **Core** stays free of AppKit/UIKit/SwiftData
- **Infra** maps pasteboard bytes ↔ domain types and owns `@Model` persistence
- **UI** binds to `SnapshotRepositoryProtocol` implementations

Design notes and the original UI plan live in [`Design/implementation_plan.md`](Design/implementation_plan.md).

## Primary representation

When a snapshot has several supported types, the **primary** one (shown first and selected by default) prefers representations that expose a **Metadata** facet, then falls back to inspector priority (color → image → HTML → rich text → URL → plain text).

## Changelog

See [CHANGELOG.md](CHANGELOG.md).
