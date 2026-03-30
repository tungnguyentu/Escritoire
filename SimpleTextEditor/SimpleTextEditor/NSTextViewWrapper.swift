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
        textView.font = NSFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        textView.textContainerInset = NSSize(width: 8, height: 8)
        textView.delegate = context.coordinator

        textView.string = text
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
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
