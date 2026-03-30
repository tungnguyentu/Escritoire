import XCTest
@testable import SimpleTextEditor

final class TextDocumentTests: XCTestCase {

    // MARK: - decode(fileWrapper:)

    func test_decode_returnsTextFromValidUTF8Data() throws {
        let expected = "Hello, macOS text editor!"
        let data = expected.data(using: .utf8)!
        let wrapper = FileWrapper(regularFileWithContents: data)

        let result = try TextDocument.decode(fileWrapper: wrapper)

        XCTAssertEqual(result, expected)
    }

    func test_decode_handlesUnicodeAndEmoji() throws {
        let expected = "日本語テスト 🌍"
        let wrapper = FileWrapper(regularFileWithContents: expected.data(using: .utf8)!)

        XCTAssertEqual(try TextDocument.decode(fileWrapper: wrapper), expected)
    }

    func test_decode_throwsOnInvalidUTF8Bytes() {
        // 0xC3 starts a 2-byte sequence; 0x28 '(' is not a valid continuation byte
        let badData = Data([0xC3, 0x28])
        let wrapper = FileWrapper(regularFileWithContents: badData)

        XCTAssertThrowsError(try TextDocument.decode(fileWrapper: wrapper))
    }

    func test_decode_throwsForDirectoryWrapper() {
        let wrapper = FileWrapper(directoryWithFileWrappers: [:])

        XCTAssertThrowsError(try TextDocument.decode(fileWrapper: wrapper))
    }

    func test_decode_handlesEmptyData() throws {
        let wrapper = FileWrapper(regularFileWithContents: Data())

        XCTAssertEqual(try TextDocument.decode(fileWrapper: wrapper), "")
    }

    // MARK: - encode(text:)

    func test_encode_producesRegularFileWrapper() {
        let wrapper = TextDocument.encode(text: "hello")

        XCTAssertNotNil(wrapper.regularFileContents)
    }

    func test_encode_dataDecodesBackToOriginalText() throws {
        let text = "Save this text"
        let wrapper = TextDocument.encode(text: text)

        let data = try XCTUnwrap(wrapper.regularFileContents)
        let decoded = try XCTUnwrap(String(data: data, encoding: .utf8))
        XCTAssertEqual(decoded, text)
    }

    // MARK: - Round-trip

    func test_roundTrip_textSurvivesEncodeAndDecode() throws {
        let original = "Round-trip: 日本語 🌍 & ASCII"

        let roundtripped = try TextDocument.decode(fileWrapper: TextDocument.encode(text: original))

        XCTAssertEqual(roundtripped, original)
    }

    // MARK: - init

    func test_init_defaultTextIsEmpty() {
        XCTAssertEqual(TextDocument().text, "")
    }

    func test_init_storesCustomText() {
        XCTAssertEqual(TextDocument(text: "hello").text, "hello")
    }
}
