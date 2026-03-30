import SwiftUI
import AppKit

struct NSTextViewWrapper: NSViewRepresentable {
    @Binding var text: String

    func makeNSView(context: Context) -> NSScrollView {
        NSScrollView()
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: NSTextViewWrapper
        init(_ parent: NSTextViewWrapper) { self.parent = parent }
    }
}
