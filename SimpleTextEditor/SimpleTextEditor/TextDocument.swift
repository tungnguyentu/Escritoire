import SwiftUI
import UniformTypeIdentifiers

struct TextDocument: FileDocument {
    var text: String

    static var readableContentTypes: [UTType] { [.plainText] }

    init(text: String = "") {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        text = try TextDocument.decode(fileWrapper: configuration.file)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        TextDocument.encode(text: text)
    }

    // MARK: - Testable helpers

    /// Decodes UTF-8 text from a file wrapper. Throws `CocoaError(.fileReadCorruptFile)` on failure.
    static func decode(fileWrapper: FileWrapper) throws -> String {
        guard let data = fileWrapper.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return string
    }

    /// Encodes text as a UTF-8 regular file wrapper.
    static func encode(text: String) -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}
