import AppKit

final class LineNumberRulerView: NSRulerView {
    private weak var textView: NSTextView?

    init(textView: NSTextView, scrollView: NSScrollView) {
        self.textView = textView
        super.init(scrollView: scrollView, orientation: .verticalRuler)
        ruleThickness = 36
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

    var currentLine: Int = 1

    private static let gutterBg = NSColor(red: 30/255.0, green: 27/255.0, blue: 24/255.0, alpha: 1)
    private static let attrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
        .foregroundColor: NSColor(red: 92/255.0, green: 85/255.0, blue: 80/255.0, alpha: 1),
    ]
    private static let activeAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .semibold),
        .foregroundColor: NSColor(red: 207/255.0, green: 200/255.0, blue: 192/255.0, alpha: 1),
    ]
    private static let newline: unichar = "\n".utf16.first!

    override func drawHashMarksAndLabels(in rect: NSRect) {
        Self.gutterBg.set()
        bounds.fill()

        guard let textView,
              let layoutManager = textView.layoutManager,
              let textContainer = textView.textContainer,
              let scrollView else { return }

        let visibleRect = scrollView.contentView.bounds
        let insetY = textView.textContainerInset.height
        let string = textView.string as NSString

        let totalChars = string.length

        if totalChars == 0 {
            drawNumber(1, y: insetY - visibleRect.minY, height: 18, active: true)
            return
        }

        // Find first visible character and walk back to the logical line start
        let visGlyphs  = layoutManager.glyphRange(forBoundingRect: visibleRect, in: textContainer)
        let firstChar  = layoutManager.characterIndexForGlyph(at: visGlyphs.location)
        var lineStart  = firstChar
        while lineStart > 0 && string.character(at: lineStart - 1) != Self.newline {
            lineStart -= 1
        }

        let totalGlyphs = layoutManager.numberOfGlyphs
        let startGlyph  = layoutManager.glyphIndexForCharacter(at: lineStart)
        var lineNum     = string.substring(to: lineStart).components(separatedBy: "\n").count

        guard startGlyph < totalGlyphs else { return }

        // enumerateLineFragments includes empty-line fragments (each \n owns a rect),
        // unlike lineFragmentRect(forGlyphAt:) which silently skips null/control glyphs.
        let enumRange = NSRange(location: startGlyph, length: totalGlyphs - startGlyph)
        layoutManager.enumerateLineFragments(forGlyphRange: enumRange) {
            fragRect, _, _, glyphRange, stop in

            let y = fragRect.minY + insetY - visibleRect.minY
            if y > rect.maxY + fragRect.height { stop.pointee = true; return }

            let charIdx = layoutManager.characterIndexForGlyph(at: glyphRange.location)
            let isStart = charIdx == 0 || string.character(at: charIdx - 1) == Self.newline

            if isStart {
                if y + fragRect.height >= rect.minY {
                    self.drawNumber(lineNum, y: y, height: fragRect.height, active: lineNum == self.currentLine)
                }
                lineNum += 1
            }
        }

        // Trailing empty line when the document ends with \n
        if totalChars > 0 && string.character(at: totalChars - 1) == Self.newline {
            let extra = layoutManager.extraLineFragmentRect
            if !extra.isEmpty {
                let y = extra.minY + insetY - visibleRect.minY
                if y + extra.height >= rect.minY && y <= rect.maxY + extra.height {
                    drawNumber(lineNum, y: y, height: extra.height, active: lineNum == currentLine)
                }
            }
        }
    }

    private func drawNumber(_ n: Int, y: CGFloat, height: CGFloat, active: Bool = false) {
        let attrs = active ? Self.activeAttrs : Self.attrs
        let s = "\(n)" as NSString
        let size = s.size(withAttributes: attrs)
        s.draw(at: NSPoint(x: bounds.width - size.width - 6,
                           y: y + (height - size.height) / 2),
               withAttributes: attrs)
    }
}
