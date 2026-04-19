import SwiftUI
import AppKit

/// Bridges NSTextView into SwiftUI. Provides: paste (automatic), undo/redo,
/// native Find bar (Cmd+F), spell check, plain-text mode, current-line highlight,
/// and font family/size controls.
struct NSTextViewWrapper: NSViewRepresentable {
    @Binding var text: String
    @Binding var currentLine: Int
    var fontFamilyIndex: Int = 0
    var editorFontSize: CGFloat = 15

    // MARK: - NSViewRepresentable

    func makeNSView(context: Context) -> NSScrollView {
        // Build scroll view + text view manually so we can use our NSTextView subclass.
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        let textView = EscritorTextView()
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = .width
        textView.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        scrollView.documentView = textView

        textView.isRichText = true                           // required for colour attributes
        textView.usesFontPanel = false                       // hide formatting palette
        textView.usesRuler = false                           // hide ruler bar
        textView.allowsUndo = true                           // Cmd-Z / Cmd-Shift-Z
        textView.usesFindBar = true                          // inline Find bar (Cmd-F)
        textView.isIncrementalSearchingEnabled = true        // live highlighting
        textView.isContinuousSpellCheckingEnabled = true     // red underlines
        textView.isAutomaticQuoteSubstitutionEnabled = false // keep straight quotes
        textView.isAutomaticDashSubstitutionEnabled = false  // keep double dashes
        textView.font = resolvedFont(index: fontFamilyIndex, size: editorFontSize)
        textView.textContainerInset = NSSize(width: 6, height: 12)
        textView.delegate = context.coordinator

        let editorBg = NSColor(red: 30/255.0, green: 27/255.0, blue: 24/255.0, alpha: 1)
        textView.backgroundColor = editorBg
        textView.drawsBackground = true
        textView.textColor = NSColor(red: 232/255.0, green: 224/255.0, blue: 213/255.0, alpha: 1)
        textView.insertionPointColor = NSColor(red: 200/255.0, green: 139/255.0, blue: 58/255.0, alpha: 1)
        textView.selectedTextAttributes = [
            .backgroundColor: NSColor(red: 200/255.0, green: 139/255.0, blue: 58/255.0, alpha: 0.28)
        ]
        scrollView.backgroundColor = editorBg
        scrollView.drawsBackground = true

        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true
        let rulerView = LineNumberRulerView(textView: textView, scrollView: scrollView)
        scrollView.verticalRulerView = rulerView
        context.coordinator.rulerView = rulerView

        textView.string = text

        let highlighter = SyntaxHighlighter(textStorage: textView.textStorage!)
        highlighter.font = resolvedFont(index: fontFamilyIndex, size: editorFontSize)
        context.coordinator.highlighter = highlighter
        highlighter.highlight(storage: textView.textStorage)

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self
        let textView = scrollView.documentView as! EscritorTextView
        if textView.string != text {
            textView.string = text
        }
        let newFont = resolvedFont(index: fontFamilyIndex, size: editorFontSize)
        if textView.font?.fontName != newFont.fontName || textView.font?.pointSize != newFont.pointSize {
            textView.font = newFont
            if let highlighter = context.coordinator.highlighter {
                highlighter.font = newFont
                highlighter.highlight(storage: textView.textStorage)
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    // MARK: - Font helper

    func resolvedFont(index: Int, size: CGFloat) -> NSFont {
        switch index {
        case 1:  return NSFont.systemFont(ofSize: size, weight: .regular)
        case 2:  return NSFont(name: "Georgia", size: size) ?? NSFont.systemFont(ofSize: size)
        default: return NSFont.monospacedSystemFont(ofSize: size, weight: .regular)
        }
    }

    // MARK: - NSTextView subclass

    final class EscritorTextView: NSTextView {
        private static let lineHighlight =
            NSColor(red: 42/255.0, green: 38/255.0, blue: 34/255.0, alpha: 1)

        override func drawBackground(in rect: NSRect) {
            super.drawBackground(in: rect)
            guard !string.isEmpty, let lm = layoutManager else { return }

            let charIdx = selectedRange().location

            // If cursor is past all glyphs and document ends with \n, use the extra fragment.
            let extra = lm.extraLineFragmentRect
            if !extra.isEmpty {
                let gi = lm.glyphIndexForCharacter(at: charIdx)
                if gi >= lm.numberOfGlyphs {
                    var r = extra
                    r.origin.y += textContainerInset.height
                    r.origin.x = 0; r.size.width = bounds.width
                    Self.lineHighlight.setFill(); r.fill()
                    return
                }
            }

            // Normal path: clamp to last valid character so end-of-string doesn't go out of bounds.
            let clamped = min(charIdx, max(0, string.count - 1))
            let gi = lm.glyphIndexForCharacter(at: clamped)
            guard gi < lm.numberOfGlyphs else { return }

            var lineRect = lm.lineFragmentRect(forGlyphAt: gi, effectiveRange: nil)
            lineRect.origin.y += textContainerInset.height
            lineRect.origin.x = 0
            lineRect.size.width = bounds.width
            Self.lineHighlight.setFill()
            lineRect.fill()
        }
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: NSTextViewWrapper
        var highlighter: SyntaxHighlighter?
        weak var rulerView: LineNumberRulerView?

        init(_ parent: NSTextViewWrapper) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            updateCurrentLine(textView)
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            updateCurrentLine(textView)
            // Ensure the line-highlight stripe repaints when cursor moves without typing.
            textView.needsDisplay = true
        }

        private func updateCurrentLine(_ textView: NSTextView) {
            let pos = textView.selectedRange().location
            let lineNum = pos == 0 ? 1 : (textView.string as NSString)
                .substring(to: pos)
                .components(separatedBy: "\n").count
            if parent.currentLine != lineNum { parent.currentLine = lineNum }
            if let ruler = rulerView, ruler.currentLine != lineNum {
                ruler.currentLine = lineNum
                ruler.needsDisplay = true
            }
        }
    }
}
