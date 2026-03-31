# Escritoire

A minimal native macOS text editor with a warm dark aesthetic. Built with SwiftUI + AppKit.

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-black) ![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange)

## Features

- **Paste** — standard system clipboard via the AppKit responder chain
- **Save / Open** — full `DocumentGroup` integration: Save, Save As, Open Recent, multi-window, unsaved-changes indicator (• in title bar)
- **Find** — native inline Find bar (Cmd+F) with live highlighting via `NSTextFinder`
- **Line numbers** — gutter that stays accurate through word-wrap and scrolling
- **Undo / Redo** — character-level undo stack (Cmd+Z / Cmd+Shift+Z)
- **Spell check** — continuous red underlines

## Requirements

- macOS 13 Ventura or later
- Xcode 15 or later (to build)

## Getting Started

```bash
git clone git@github.com:tungnguyentu/Escritoire.git
open Escritoire/SimpleTextEditor.xcodeproj
```

In Xcode:

1. Select the **Escritoire** target → **Signing & Capabilities** → set your **Team** (free Apple ID works)
2. Press **Cmd+R**

## Stack

| Layer | Technology |
|---|---|
| App shell | SwiftUI `DocumentGroup` |
| Document model | `FileDocument` (UTF-8 encode/decode) |
| Editor | `NSTextView` via `NSViewRepresentable` |
| Find bar | `NSTextFinder` (`usesFindBar = true`) |
| Line numbers | Custom `NSRulerView` subclass |
| Tests | XCTest (10 unit tests for document model) |

## Project Layout

```
SimpleTextEditor/
├── SimpleTextEditorApp.swift      # @main entry, DocumentGroup wiring
├── ContentView.swift              # Root view + status bar
├── TextDocument.swift             # FileDocument, UTF-8 helpers
├── NSTextViewWrapper.swift        # NSViewRepresentable bridge
├── LineNumberRulerView.swift      # Gutter line numbers
└── Assets.xcassets/               # App icon (all macOS sizes)
SimpleTextEditorTests/
└── SimpleTextEditorTests.swift    # TextDocument encode/decode tests
```

## License

MIT
