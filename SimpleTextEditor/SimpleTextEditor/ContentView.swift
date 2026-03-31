import SwiftUI

// MARK: - Escritoire colour palette (warm dark)
private enum Theme {
    static let bg        = Color(red: 30/255.0,  green: 27/255.0,  blue: 24/255.0)
    static let statusBg  = Color(red: 22/255.0,  green: 19/255.0,  blue: 16/255.0)
    static let border    = Color(red: 46/255.0,  green: 42/255.0,  blue: 38/255.0)
    static let accent    = Color(red: 200/255.0, green: 139/255.0, blue: 58/255.0)
    static let muted     = Color(red: 92/255.0,  green: 85/255.0,  blue: 80/255.0)
}

struct ContentView: View {
    @Binding var document: TextDocument

    private var lineCount: Int {
        document.text.isEmpty ? 1 : document.text.components(separatedBy: "\n").count
    }
    private var wordCount: Int {
        document.text.split(whereSeparator: \.isWhitespace).count
    }
    private var charCount: Int { document.text.count }

    var body: some View {
        VStack(spacing: 0) {
            NSTextViewWrapper(text: $document.text)
                .frame(minWidth: 520, minHeight: 400)

            Rectangle()
                .fill(Theme.border)
                .frame(height: 1)

            HStack(spacing: 0) {
                Spacer()
                stat(count: lineCount, singular: "line",  plural: "lines")
                dot
                stat(count: wordCount, singular: "word",  plural: "words")
                dot
                stat(count: charCount, singular: "char",  plural: "chars")
            }
            .padding(.horizontal, 16)
            .frame(height: 28)
            .background(Theme.statusBg)
        }
        .preferredColorScheme(.dark)
    }

    private var dot: some View {
        Text("·")
            .font(.system(size: 11, weight: .regular, design: .monospaced))
            .foregroundColor(Theme.muted)
            .padding(.horizontal, 8)
    }

    private func stat(count: Int, singular: String, plural: String) -> some View {
        HStack(spacing: 4) {
            Text("\(count)")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(Theme.accent)
            Text(count == 1 ? singular : plural)
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundColor(Theme.muted)
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView(document: .constant(TextDocument(text: "Escritoire — a warm writing space.\nLine two.\nLine three.")))
}
