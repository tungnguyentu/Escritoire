import SwiftUI
import UniformTypeIdentifiers

struct TextDocument: FileDocument {
    var text: String = ""

    static var readableContentTypes: [UTType] { [.plainText] }

    init(text: String = "") {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        text = "" // stub: real UTF-8 decode added in Task 2
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data()) // stub: real UTF-8 encode added in Task 2
    }
}
