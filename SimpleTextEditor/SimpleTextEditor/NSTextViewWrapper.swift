import SwiftUI
import AppKit

/// Bridges NSTextView into SwiftUI. Provides: paste (automatic), undo/redo,
/// native Find bar (Cmd+F), spell check, and plain-text mode.
struct NSTextViewWrapper: NSViewRepresentable {
    @Binding var text: String

    // MARK: - NSViewRepresentable

    func makeNSView(context: Context) -> NSScrollView {
        // NSTextView.scrollableTextView() returns a pre-configured NSScrollView
        // containing a properly sized, vertically resizable NSTextView.
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        textView.isRichText = false                          // plain text only
        textView.allowsUndo = true                           // Cmd-Z / Cmd-Shift-Z
        textView.usesFindBar = true                          // inline Find bar (Cmd-F)
        textView.isIncrementalSearchingEnabled = true        // live highlighting
        textView.isContinuousSpellCheckingEnabled = true     // red underlines
        textView.isAutomaticQuoteSubstitutionEnabled = false // keep straight quotes
        textView.isAutomaticDashSubstitutionEnabled = false  // keep double dashes
        textView.font = NSFont.monospacedSystemFont(ofSize: 15, weight: .regular)
        textView.textContainerInset = NSSize(width: 6, height: 12)
        textView.delegate = context.coordinator

        // Escritoire warm dark theme
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
        scrollView.verticalRulerView = LineNumberRulerView(textView: textView, scrollView: scrollView)

        textView.string = text
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.parent = self
        let textView = scrollView.documentView as! NSTextView
        // Guard against unnecessary resets that would move the cursor.
        if textView.string != text {
            textView.string = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: NSTextViewWrapper

        init(_ parent: NSTextViewWrapper) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}
