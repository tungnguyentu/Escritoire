import SwiftUI

struct ContentView: View {
    @Binding var document: TextDocument

    var body: some View {
        NSTextViewWrapper(text: $document.text)
            .frame(minWidth: 500, minHeight: 400)
    }
}
