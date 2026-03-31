import AppKit

final class SyntaxHighlighter {
    private weak var textStorage: NSTextStorage?

    // Escritoire warm dark palette
    private static let base    = NSColor(red: 232/255.0, green: 224/255.0, blue: 213/255.0, alpha: 1.0)
    private static let keyword = NSColor(red: 200/255.0, green: 139/255.0, blue:  58/255.0, alpha: 1.0)
    private static let string  = NSColor(red: 143/255.0, green: 184/255.0, blue: 123/255.0, alpha: 1.0)
    private static let number  = NSColor(red: 126/255.0, green: 181/255.0, blue: 200/255.0, alpha: 1.0)
    private static let comment = NSColor(red: 107/255.0, green: 122/255.0, blue: 107/255.0, alpha: 1.0)
    private static let font    = NSFont.monospacedSystemFont(ofSize: 15, weight: .regular)

    // Compiled regex rules applied in order — later rules win (comments override strings, etc.)
    private static let rules: [(NSRegularExpression, NSColor)] = build()

    private static func build() -> [(NSRegularExpression, NSColor)] {
        let kw = [
            // Swift / general
            "func", "class", "struct", "enum", "protocol", "extension", "typealias",
            "var", "let", "const", "type", "static", "final", "override",
            "open", "public", "private", "internal", "fileprivate",
            "if", "else", "guard", "switch", "case", "default",
            "for", "while", "repeat", "break", "continue", "return",
            "import", "true", "false", "nil", "self", "super",
            "throws", "throw", "try", "catch", "do", "async", "await",
            // Python
            "def", "lambda", "pass", "yield", "with", "as", "in",
            "is", "not", "and", "or", "from", "del", "global", "raise",
            "except", "finally", "assert", "print",
            // JavaScript / TypeScript
            "function", "new", "delete", "typeof", "instanceof", "void",
            "this", "null", "undefined", "export", "require",
            "interface", "implements", "extends", "namespace", "module",
            // Shell
            "echo", "then", "fi", "done", "esac",
        ]

        let raw: [(String, NSColor)] = [
            ("\\b0x[0-9a-fA-F]+\\b|\\b\\d+\\.?\\d*\\b",                        number),
            ("\\b(" + kw.joined(separator: "|") + ")\\b",                       keyword),
            ("\"(?:[^\"\\\\]|\\\\.)*\"|'(?:[^'\\\\]|\\\\.)*'|`[^`]*`",          string),
            ("/\\*[\\s\\S]*?\\*/",                                               comment),
            ("//[^\\n]*|#(?![0-9a-fA-F]{3,6}\\b)[^\\n]*|--[^\\n]*",           comment),
        ]

        return raw.compactMap { pattern, color in
            guard let re = try? NSRegularExpression(pattern: pattern) else { return nil }
            return (re, color)
        }
    }

    init(textStorage: NSTextStorage) {
        self.textStorage = textStorage
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(storageDidEdit(_:)),
            name: NSTextStorage.didProcessEditingNotification,
            object: textStorage
        )
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    @objc private func storageDidEdit(_ note: Notification) {
        guard let storage = note.object as? NSTextStorage,
              storage.editedMask.contains(.editedCharacters) else { return }
        highlight(storage: storage)
    }

    func highlight(storage: NSTextStorage? = nil) {
        guard let storage = storage ?? textStorage else { return }
        let text = storage.string
        guard !text.isEmpty, text.count < 200_000 else { return }

        let full = NSRange(text.startIndex..., in: text)
        storage.beginEditing()
        storage.addAttribute(.foregroundColor, value: Self.base, range: full)
        storage.addAttribute(.font,            value: Self.font, range: full)
        for (regex, color) in Self.rules {
            for match in regex.matches(in: text, range: full) {
                storage.addAttribute(.foregroundColor, value: color, range: match.range)
            }
        }
        storage.endEditing()
    }
}
