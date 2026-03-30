import SwiftUI
import UniformTypeIdentifiers

struct TextDocument: FileDocument {
    var text: String = ""

    static var readableContentTypes: [UTType] { [.plainText] }

    init(text: String = "") {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        text = ""
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data())
    }
}
