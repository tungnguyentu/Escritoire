import SwiftUI
import AppKit

struct NSTextViewWrapper: NSViewRepresentable {
    @Binding var text: String
    @Binding var selectedLine: Int
    @Binding var selectedColumn: Int
    var font: NSFont
    var textColor: NSColor
    var backgroundColor: NSColor
    var lineSpacing: CGFloat = 1.35
    var inset: CGSize = CGSize(width: 8, height: 12)
    var caretColor: NSColor = NSColor(red: 124/255, green: 252/255, blue: 138/255, alpha: 1.0)
    var caretWidth: CGFloat = 1
    var typewriterMode: Bool = false
    var gutterTextColor: NSColor = NSColor(white: 0.45, alpha: 1)
    var gutterActiveColor: NSColor = NSColor(red: 124/255, green: 252/255, blue: 138/255, alpha: 1)
    var gutterBackgroundColor: NSColor = NSColor(white: 0.07, alpha: 1)
    var gutterSeparatorColor: NSColor = NSColor(white: 0.14, alpha: 1)

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = true

        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer(containerSize: NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
        textContainer.widthTracksTextView = true
        textContainer.heightTracksTextView = false
        layoutManager.addTextContainer(textContainer)

        let textView = NSTextView(frame: .zero, textContainer: textContainer)
        textView.minSize = NSSize.zero
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainerInset = inset
        textView.textContainer?.lineFragmentPadding = 4
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        scrollView.documentView = textView

        textView.delegate = context.coordinator
        textView.string = text
        // Force plain-text mode so imported attributes can't hide glyphs.
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true
        textView.isEditable = true
        textView.isSelectable = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainerInset = inset
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        textView.textContainer?.lineFragmentPadding = 4
        textView.drawsBackground = true
        textView.usesFindBar = true
        textView.usesFindPanel = true
        textView.selectedTextAttributes = [
            .backgroundColor: caretColor.withAlphaComponent(0.35),
            .foregroundColor: normalizedTextColor(backgroundColor)
        ]

        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true

        let ruler = LineNumberRulerView(textView: textView)
        ruler.textColor = gutterTextColor
        ruler.activeTextColor = gutterActiveColor
        ruler.background = gutterBackgroundColor
        ruler.separatorColor = gutterSeparatorColor
        ruler.font = NSFont.monospacedSystemFont(ofSize: max(10, font.pointSize - 1), weight: .regular)
        scrollView.verticalRulerView = ruler

        applyStyle(to: textView, in: scrollView)
        applyParagraphStyle(to: textView)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        if textView.string != text {
            let selected = textView.selectedRange()
            textView.string = text
            let safeLocation = min(selected.location, (text as NSString).length)
            textView.setSelectedRange(NSRange(location: safeLocation, length: 0))
        }

        applyStyle(to: textView, in: scrollView)
        applyParagraphStyle(to: textView)
        textView.setNeedsDisplay(textView.bounds, avoidAdditionalLayout: false)
        textView.displayIfNeeded()

        if typewriterMode {
            centerSelectionInViewport(textView, scrollView: scrollView)
        }
        scrollView.verticalRulerView?.needsDisplay = true
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func applyStyle(to textView: NSTextView, in scrollView: NSScrollView) {
        let fg = normalizedTextColor(textColor)
        textView.font = font
        textView.textColor = fg
        textView.insertionPointColor = caretColor
        textView.backgroundColor = backgroundColor
        textView.drawsBackground = true
        scrollView.backgroundColor = backgroundColor
        scrollView.drawsBackground = true
        textView.typingAttributes = [
            .font: font,
            .foregroundColor: fg
        ]
        let paragraph = NSMutableParagraphStyle()
        let defaultHeight = NSLayoutManager().defaultLineHeight(for: font)
        paragraph.lineSpacing = max(0, defaultHeight * (max(1.0, lineSpacing) - 1.0))
        textView.defaultParagraphStyle = paragraph

        if let ruler = scrollView.verticalRulerView as? LineNumberRulerView {
            ruler.textColor = gutterTextColor
            ruler.activeTextColor = gutterActiveColor
            ruler.background = gutterBackgroundColor
            ruler.separatorColor = gutterSeparatorColor
            ruler.font = NSFont.monospacedSystemFont(ofSize: max(10, font.pointSize - 1), weight: .regular)
        }
    }

    private func applyParagraphStyle(to textView: NSTextView) {
        let defaultHeight = NSLayoutManager().defaultLineHeight(for: font)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = max(0, defaultHeight * (max(1.0, lineSpacing) - 1.0))
        textView.defaultParagraphStyle = paragraph
        textView.needsDisplay = true
    }

    private func normalizedTextColor(_ color: NSColor) -> NSColor {
        if let rgb = color.usingColorSpace(.deviceRGB) {
            return NSColor(deviceRed: rgb.redComponent, green: rgb.greenComponent, blue: rgb.blueComponent, alpha: 1)
        }
        return NSColor(deviceRed: 0.85, green: 1.0, blue: 0.88, alpha: 1.0)
    }

    private func centerSelectionInViewport(_ textView: NSTextView, scrollView: NSScrollView) {
        guard let layoutManager = textView.layoutManager, let textContainer = textView.textContainer else { return }
        let selectedRange = textView.selectedRange()
        let glyphRange = layoutManager.glyphRange(forCharacterRange: selectedRange, actualCharacterRange: nil)
        let rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        let visibleHeight = scrollView.contentView.bounds.height
        let targetY = max(0, rect.midY - visibleHeight / 2)
        textView.scroll(NSPoint(x: 0, y: targetY))
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: NSTextViewWrapper

        init(_ parent: NSTextViewWrapper) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            textView.enclosingScrollView?.verticalRulerView?.needsDisplay = true
        }

        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            let range = textView.selectedRange()
            let content = textView.string as NSString
            let prefix = content.substring(to: range.location)
            let line = prefix.components(separatedBy: "\n").count
            let lastNewline = prefix.lastIndex(of: "\n")
            let column = lastNewline.map { prefix.distance(from: prefix.index(after: $0), to: prefix.endIndex) + 1 } ?? (prefix.count + 1)
            parent.selectedLine = line
            parent.selectedColumn = max(1, column)
            textView.enclosingScrollView?.verticalRulerView?.needsDisplay = true
        }
    }
}
