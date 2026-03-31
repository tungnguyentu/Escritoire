import AppKit

final class LineNumberRulerView: NSRulerView {
    private weak var textView: NSTextView?

    init(textView: NSTextView, scrollView: NSScrollView) {
        self.textView = textView
        super.init(scrollView: scrollView, orientation: .verticalRuler)
        ruleThickness = 44
        textView.postsFrameChangedNotifications = true
        NotificationCenter.default.addObserver(
            self, selector: #selector(invalidate),
            name: NSText.didChangeNotification, object: textView
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(invalidate),
            name: NSView.frameDidChangeNotification, object: textView
        )
    }

    required init(coder: NSCoder) { fatalError() }

    deinit { NotificationCenter.default.removeObserver(self) }

    @objc private func invalidate() { needsDisplay = true }

    private static let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
        .foregroundColor: NSColor.tertiaryLabelColor
    ]
    private static let newline: unichar = "\n".utf16.first!

    override func drawHashMarksAndLabels(in rect: NSRect) {
        NSColor.windowBackgroundColor.set()
        bounds.fill()

        NSColor.separatorColor.setStroke()
        let border = NSBezierPath()
        border.move(to: NSPoint(x: bounds.maxX - 0.5, y: rect.minY))
        border.line(to: NSPoint(x: bounds.maxX - 0.5, y: rect.maxY))
        border.lineWidth = 1
        border.stroke()

        guard let textView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer,
              let scrollView else { return }

        let visibleRect = scrollView.contentView.bounds
        let insetY = textView.textContainerInset.height
        let string = textView.string as NSString
        let totalGlyphs = layoutManager.numberOfGlyphs

        if totalGlyphs == 0 {
            drawNumber(1, y: insetY - visibleRect.minY, height: 18)
            return
        }

        let visibleRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
        let firstCharIdx = layoutManager.characterIndexForGlyph(at: visibleRange.location)
        let preceding = string.substring(to: min(firstCharIdx, string.length))
        var lineNum = preceding.components(separatedBy: "\n").count

        var glyphIdx = visibleRange.location
        let endGlyph = NSMaxRange(visibleRange)

        while glyphIdx < endGlyph {
            var fragRange = NSRange(location: NSNotFound, length: 0)
            let fragRect = layoutManager.lineFragmentRect(forGlyphAt: glyphIdx, effectiveRange: &fragRange)
            guard fragRange.location != NSNotFound, fragRange.length > 0 else { break }

            let charIdx = layoutManager.characterIndexForGlyph(at: fragRange.location)
            let isLineStart = charIdx == 0 || string.character(at: charIdx - 1) == Self.newline

            if isLineStart {
                drawNumber(lineNum, y: fragRect.minY + insetY - visibleRect.minY, height: fragRect.height)
                lineNum += 1
            }

            glyphIdx = NSMaxRange(fragRange)
        }
    }

    private func drawNumber(_ n: Int, y: CGFloat, height: CGFloat) {
        let s = "\(n)" as NSString
        let size = s.size(withAttributes: Self.attrs)
        s.draw(at: NSPoint(x: bounds.width - size.width - 8,
                           y: y + (height - size.height) / 2),
               withAttributes: Self.attrs)
    }
}
