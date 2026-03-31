import AppKit

final class LineNumberRulerView: NSRulerView {
    private weak var textView: NSTextView?

    init(textView: NSTextView, scrollView: NSScrollView) {
        self.textView = textView
        super.init(scrollView: scrollView, orientation: .verticalRuler)
        ruleThickness = 40
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

    private static let gutterBg    = NSColor(red: 26/255.0, green: 23/255.0, blue: 20/255.0, alpha: 1)
    private static let borderColor  = NSColor(red: 46/255.0, green: 42/255.0, blue: 38/255.0, alpha: 1)
    private static let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
        .foregroundColor: NSColor(red: 92/255.0, green: 85/255.0, blue: 80/255.0, alpha: 1)
    ]
    private static let newline: unichar = "\n".utf16.first!

    override func drawHashMarksAndLabels(in rect: NSRect) {
        Self.gutterBg.set()
        bounds.fill()

        Self.borderColor.setStroke()
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

        let totalChars = string.length

        if totalChars == 0 {
            drawNumber(1, y: insetY - visibleRect.minY, height: 18)
            return
        }

        // Find visible char range via glyphs
        let visGlyphs = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
        let firstChar = layoutManager.characterIndexForGlyph(at: visGlyphs.location)

        // Walk back to the start of the first visible logical line
        var lineStart = firstChar
        while lineStart > 0 && string.character(at: lineStart - 1) != Self.newline {
            lineStart -= 1
        }

        // Count line number at lineStart
        var lineNum = string.substring(to: lineStart).components(separatedBy: "\n").count

        // Iterate one logical line at a time using character positions.
        // This correctly handles empty lines, which have no drawn glyph and
        // are silently skipped by glyph-range iteration.
        var charPos = lineStart
        while charPos < totalChars {
            let glyph = layoutManager.glyphIndexForCharacter(at: charPos)
            var fragRange = NSRange(location: NSNotFound, length: 0)
            let fragRect  = layoutManager.lineFragmentRect(forGlyphAt: glyph, effectiveRange: &fragRange)

            if fragRange.location != NSNotFound {
                let y = fragRect.minY + insetY - visibleRect.minY
                if y > rect.maxY + fragRect.height { break }  // past visible area
                drawNumber(lineNum, y: y, height: fragRect.height)
            }
            lineNum += 1

            let lr   = string.lineRange(for: NSRange(location: charPos, length: 0))
            let next = NSMaxRange(lr)
            if next <= charPos { break }
            charPos = next
        }

        // Trailing empty line when the document ends with \n
        if totalChars > 0 && string.character(at: totalChars - 1) == Self.newline {
            let extra = layoutManager.extraLineFragmentRect
            if !extra.isEmpty {
                let y = extra.minY + insetY - visibleRect.minY
                if y + extra.height >= rect.minY && y <= rect.maxY + extra.height {
                    drawNumber(lineNum, y: y, height: extra.height)
                }
            }
        }
    }

    private func drawNumber(_ n: Int, y: CGFloat, height: CGFloat) {
        let s = "\(n)" as NSString
        let size = s.size(withAttributes: Self.attrs)
        s.draw(at: NSPoint(x: bounds.width - size.width - 6,
                           y: y + (height - size.height) / 2),
               withAttributes: Self.attrs)
    }
}
