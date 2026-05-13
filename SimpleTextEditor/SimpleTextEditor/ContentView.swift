import SwiftUI

enum EditorVariant: String, CaseIterable, Identifiable {
    case minimal, classic, manuscript

    var id: String { rawValue }

    var title: String {
        switch self {
        case .minimal:
            return "Minimal"
        case .classic:
            return "Classic"
        case .manuscript:
            return "Manuscript"
        }
    }
}

// MARK: - Document model (mirrors design's Doc type)
struct Doc: Identifiable {
    let id: String
    var name: String
    var content: String
}

enum EditorTheme: String, CaseIterable {
    case terminal
    case light
}

private typealias Tok = DS.Escritoire

// MARK: - ContentView
struct ContentView: View {
    @Binding var document: TextDocument

    // Tabs
    @State private var docs: [Doc]
    @State private var activeId: String
    @State private var sessionIDsByDocID: [String: UUID]
    @StateObject private var sessionStore: DocumentSessionStore

    // Editor UI
    @State private var caretLine: Int = 4
    @State private var findOpen: Bool = false
    @State private var findQ: String = ""
    @State private var replaceQ: String = ""
    @State private var fontScale: CGFloat = 1.1
    @State private var fontFamilyIndex: Int = 0

    // App-level
    @State private var variant: EditorVariant = .classic
    @State private var darkMode: Bool = true
    @State private var splashDone: Bool = true
    @State private var tweaksVisible: Bool = false

    // SwiftUI-only find state
    @State private var searchCursor: Int = 0
    @State private var lastMatchLine: Int? = nil
    @State private var lastMatchColumn: Int? = nil

    // Redesign features
    @State private var commandBarOpen: Bool = false
    @State private var commandQuery: String = ""
    @State private var focusMode: Bool = false
    @State private var typewriterMode: Bool = false
    @State private var caretColumn: Int = 1
    @State private var saveStatusText: String = "Unsaved"
    @State private var autosaveWorkItems: [String: DispatchWorkItem] = [:]
    @State private var isApplyingSessionState: Bool = false
    @State private var editorTheme: EditorTheme = .terminal

    init(document: Binding<TextDocument>, fileURL: URL?) {
        _document = document

        let initialContent = document.wrappedValue.text
        let resolvedName = fileURL?.lastPathComponent ?? "untitled.txt"

        let firstDoc = Doc(id: "d1", name: resolvedName, content: initialContent)
        let store = DocumentSessionStore()
        let firstSessionID = store.openSession(
            initialText: initialContent,
            fileURL: fileURL,
            displayName: resolvedName
        )

        _docs = State(initialValue: [firstDoc])
        _activeId = State(initialValue: firstDoc.id)
        _sessionIDsByDocID = State(initialValue: [firstDoc.id: firstSessionID])
        _sessionStore = StateObject(wrappedValue: store)
    }

    // MARK: Derived state
    private var activeDoc: Doc { docs.first(where: { $0.id == activeId }) ?? docs[0] }
    private var activeContent: String { activeDoc.content }
    private var fileSizeText: String { ByteCountFormatter.string(fromByteCount: Int64(activeContent.utf8.count), countStyle: .file) }
    private var activeSessionID: UUID? { sessionIDsByDocID[activeId] }

    private func setContent(_ next: String) {
        guard let idx = docs.firstIndex(where: { $0.id == activeId }) else { return }

        let previousContent = docs[idx].content
        docs[idx].content = next
        document.text = next

        let hasChanges = previousContent != next
        markDirtyCurrentDocIfNeeded(hasChanges: hasChanges)

        if let sessionID = activeSessionID {
            sessionStore.markDirty(hasChanges, for: sessionID)
        }

        scheduleAutosave(content: next, docID: activeId)
    }

    private func markDirtyCurrentDocIfNeeded(hasChanges: Bool) {
        guard let idx = docs.firstIndex(where: { $0.id == activeId }) else { return }
        docs[idx].name = docs[idx].name.replacingOccurrences(of: " •", with: "")
        if hasChanges {
            docs[idx].name += " •"
            saveStatusText = "Unsaved"
        }
    }

    private func cleanDisplayName(_ name: String) -> String {
        name.replacingOccurrences(of: " •", with: "")
    }

    private func scheduleAutosave(content: String, docID: String) {
        autosaveWorkItems[docID]?.cancel()

        let work = DispatchWorkItem {
            if activeId == docID {
                saveStatusText = "Saving..."
                document.text = content
            }

            if let idx = docs.firstIndex(where: { $0.id == docID }) {
                docs[idx].name = cleanDisplayName(docs[idx].name)
            }

            if activeId == docID {
                saveStatusText = "Saved just now"
            }

            if let sessionID = sessionIDsByDocID[docID] {
                sessionStore.markDirty(false, for: sessionID)
            }

            autosaveWorkItems[docID] = nil
        }

        autosaveWorkItems[docID] = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: work)
    }

    private func handleCommand(_ command: String) {
        let q = command.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { commandBarOpen = false; return }

        let isFocusCommand = q == "focus" || q == "toggle focus"
        let isTypewriterCommand = q == "typewriter" || q == "toggle typewriter"

        if isFocusCommand {
            focusMode.toggle()
            if let sessionID = activeSessionID {
                sessionStore.setFocusMode(focusMode, for: sessionID)
            }
            commandBarOpen = false
            return
        }

        if isTypewriterCommand {
            typewriterMode.toggle()
            if let sessionID = activeSessionID {
                sessionStore.setTypewriterMode(typewriterMode, for: sessionID)
            }
            commandBarOpen = false
            return
        }

        if q.hasPrefix("line "), let line = Int(q.replacingOccurrences(of: "line ", with: "")) {
            let boundedLine = max(1, line)
            caretLine = boundedLine
            if let sessionID = activeSessionID {
                sessionStore.jumpToLine(boundedLine, in: sessionID)
            }
            commandBarOpen = false
            return
        }

        if q == "new tab" {
            addTab()
            commandBarOpen = false
            return
        }

        if q == "close tab" {
            closeTab(id: activeId)
            commandBarOpen = false
        }
    }


    private var lineCount: Int { activeContent.isEmpty ? 1 : activeContent.components(separatedBy: "\n").count }
    private var wordCount: Int { activeContent.split(whereSeparator: \.isWhitespace).count }
    private var charCount: Int { activeContent.count }
    private let editorLineSpacingMultiplier: CGFloat = 1.35
    private var themeEditorBG: Color { editorTheme == .terminal ? .black : Color(hex: "#F6F6F4") }
    private var themeCanvasBG: Color { editorTheme == .terminal ? .black : Color(hex: "#ECEBE7") }
    private var themeText: Color { editorTheme == .terminal ? .white : Color(hex: "#1F1F1D") }
    private var themeGutterText: Color { editorTheme == .terminal ? Color(hex: "#4E8A54") : Color(hex: "#8A867E") }
    private var themeAccent: Color { editorTheme == .terminal ? Color(hex: "#8DFF99") : Color(hex: "#C7943D") }
    private var themeBorder: Color { editorTheme == .terminal ? Color(hex: "#1D2A1E") : Color(hex: "#D4D0C8") }
    private var themeEditorBGNS: NSColor { editorTheme == .terminal ? .black : NSColor(deviceRed: 246/255, green: 246/255, blue: 244/255, alpha: 1) }
    private var themeTextNS: NSColor { editorTheme == .terminal ? .white : NSColor(deviceRed: 31/255, green: 31/255, blue: 29/255, alpha: 1) }
    private var themeGutterTextNS: NSColor { editorTheme == .terminal ? NSColor(deviceRed: 78/255, green: 138/255, blue: 84/255, alpha: 1) : NSColor(deviceRed: 138/255, green: 134/255, blue: 126/255, alpha: 1) }
    private var themeAccentNS: NSColor { editorTheme == .terminal ? NSColor(deviceRed: 141/255, green: 255/255, blue: 153/255, alpha: 1) : NSColor(deviceRed: 199/255, green: 148/255, blue: 61/255, alpha: 1) }
    private var themeBorderNS: NSColor { editorTheme == .terminal ? NSColor(deviceRed: 29/255, green: 42/255, blue: 30/255, alpha: 1) : NSColor(deviceRed: 212/255, green: 208/255, blue: 200/255, alpha: 1) }

    private func resolvedEditorFont() -> Font {
        let size = 14 * fontScale
        switch fontFamilyIndex {
        case 0:
            return .system(size: size, weight: .regular, design: .monospaced)
        case 1:
            return .system(size: size, weight: .regular, design: .default)
        default:
            return .system(size: size, weight: .regular, design: .serif)
        }
    }

    private func resolvedNSFont() -> NSFont {
        let size = 14 * fontScale
        switch fontFamilyIndex {
        case 0:
            return NSFont(name: "Menlo", size: size) ?? .monospacedSystemFont(ofSize: size, weight: .regular)
        case 1:
            return .systemFont(ofSize: size)
        default:
            return NSFont(name: "Georgia", size: size) ?? .systemFont(ofSize: size)
        }
    }

    // MARK: Font-family picker + A−/A+ pill (compact)
    private var fontControls: some View {
        HStack(spacing: 4) {
            Picker("", selection: $fontFamilyIndex) {
                Text("Mono").tag(0)
                Text("Sans").tag(1)
                Text("Serif").tag(2)
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(width: 80)
            .font(.system(size: 10))
            .padding(.horizontal, 1)
            .padding(.vertical, 0)
            .background(Tok.editorBackground(variant: variant, dark: darkMode))
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(Tok.borderColor(variant: variant, dark: darkMode), lineWidth: 1))

            HStack(spacing: 0) {
                Button("A−") { fontScale = max(0.7, fontScale - 0.1) }
                    .buttonStyle(.plain)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(Tok.textColor(dark: darkMode))
                    .frame(width: 28, height: 20)
                Tok.borderColor(variant: variant, dark: darkMode).frame(width: 1, height: 12)
                Button("A+") { fontScale = min(1.8, fontScale + 0.1) }
                    .buttonStyle(.plain)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(Tok.textColor(dark: darkMode))
                    .frame(width: 28, height: 20)
            }
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(Tok.borderColor(variant: variant, dark: darkMode), lineWidth: 1))
        }
        .padding(.trailing, DS.Spacing.sm)
    }

    private var shortcutHandlers: some View {
        VStack {
            Button("") { findOpen = true }
                .keyboardShortcut("f", modifiers: [.command])
                .frame(width: 0, height: 0)
                .opacity(0)
            Button("") { commandBarOpen = true }
                .keyboardShortcut("k", modifiers: [.command])
                .frame(width: 0, height: 0)
                .opacity(0)
            Button("") {
                if commandBarOpen {
                    commandBarOpen = false
                } else if findOpen {
                    findOpen = false
                }
            }
            .keyboardShortcut(.escape, modifiers: [])
            .frame(width: 0, height: 0)
            .opacity(0)
            Button("") {
                editorTheme = (editorTheme == .terminal) ? .light : .terminal
            }
            .keyboardShortcut("t", modifiers: [.command, .shift])
            .frame(width: 0, height: 0)
            .opacity(0)
        }
    }

    // MARK: Body
    var body: some View {
        ZStack {
            mainContent
            if !splashDone { SplashView(done: $splashDone, dark: darkMode) }
            if tweaksVisible {
                TweaksPanel(variant: $variant, darkMode: $darkMode) { tweaksVisible = false }
            }
        }
        .preferredColorScheme(darkMode ? .dark : .light)
        .onAppear {
            searchCursor = 0
        }
        .onChange(of: fontScale) { value in
            guard !isApplyingSessionState, let sessionID = activeSessionID else { return }
            sessionStore.setFontScale(Double(value), for: sessionID)
        }
        .onChange(of: fontFamilyIndex) { value in
            guard !isApplyingSessionState, let sessionID = activeSessionID else { return }
            sessionStore.setFontFamilyIndex(value, for: sessionID)
        }
        .background(shortcutHandlers)
    }

    // MARK: Main layout
    private var mainContent: some View {
        ZStack {
            themeCanvasBG
            .ignoresSafeArea()

            RadialGradient(
                colors: [themeAccent.opacity(editorTheme == .terminal ? 0.08 : 0.04), .clear],
                center: .center,
                startRadius: 20,
                endRadius: 540
            )
            .ignoresSafeArea()

            EditorShellView(
                showTopBar: false,
                showTabBar: false,
                showCommandBar: commandBarOpen,
                showFindBar: findOpen && !focusMode,
                showStatusBar: true,
                background: .clear,
                topBar: AnyView(titleBar),
                tabBar: AnyView(tabsRow),
                commandBar: AnyView(commandBar),
                findBar: AnyView(findBar),
                statusBar: AnyView(statusBar)
            ) {
                editorWithGutter
            }
        }
    }

    private var commandBar: some View {
        CommandBarView(
            query: $commandQuery,
            darkMode: darkMode,
            variant: variant,
            onSubmit: handleCommand
        )
    }

    // MARK: Editor + line-number gutter
    private var editorWithGutter: some View {
        HStack(spacing: 0) {
            lineNumberGutter
            TextEditor(text: Binding(get: { activeContent }, set: { setContent($0) }))
            #if os(macOS)
                .scrollContentBackground(.hidden)
            #endif
                .font(resolvedEditorFont())
                .foregroundColor(themeText)
                .padding(.horizontal, 6)
                .padding(.vertical, 8)
        }
        .background(themeEditorBG)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var lineNumberGutter: some View {
        let total = max(1, lineCount)
        let rowHeight = lineHeight
        return VStack(alignment: .trailing, spacing: 0) {
            ForEach(1...total, id: \.self) { line in
                Text("\(line)")
                    .font(.system(size: max(10, 14 * fontScale - 1), weight: line == caretLine ? .semibold : .regular, design: .monospaced))
                    .foregroundColor(line == caretLine ? themeAccent : themeGutterText)
                    .frame(height: rowHeight, alignment: .topTrailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 8)
        .padding(.trailing, 8)
        .frame(maxHeight: .infinity, alignment: .topTrailing)
        .frame(width: 52)
        .background(themeEditorBG)
        .overlay(alignment: .trailing) { themeBorder.frame(width: 1) }
        .allowsHitTesting(false)
    }

    private var lineHeight: CGFloat {
        let f = resolvedNSFont()
        let layoutManager = NSLayoutManager()
        return layoutManager.defaultLineHeight(for: f)
    }
    
    // The extra spacing we add beneath each line
    private var lineSpacingExtra: CGFloat {
        lineHeight * (editorLineSpacingMultiplier - 1.0)
    }
    
    // MARK: Title bar  (42px, chrome bg, centered brand)
    private var titleBar: some View {
        EditorTopBarView(
            darkMode: darkMode,
            title: cleanDisplayName(activeDoc.name),
            saveStateText: saveStatusText
        )
    }

    // MARK: Tabs row  (28px)
    private var tabsRow: some View {
        HStack(spacing: 0) {
            EditorTabStripView(
                tabs: docs.map {
                    EditorTabStripView.TabItem(
                        id: $0.id,
                        title: cleanDisplayName($0.name),
                        isDirty: $0.name.contains(" •")
                    )
                },
                activeID: activeId,
                darkMode: darkMode,
                variant: variant,
                onSelect: selectTab,
                onClose: closeTab,
                onAdd: addTab
            )

            Spacer()
            fontControls
        }
        .frame(height: 38)
        .background(Tok.tabBackground(variant: variant, dark: darkMode))
    }


    // MARK: Find/replace bar
    private var findBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 10))
                .foregroundColor(themeGutterText)
                .frame(width: 12, height: 12)

            findInput("Find", text: $findQ)
                .onSubmit { doFindNext() }
                .onChange(of: findQ) { _ in
                    searchCursor = 0
                    lastMatchLine = nil
                    lastMatchColumn = nil
                }

            findInput("Replace", text: $replaceQ)

            Button("Next") { doFindNext() }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundColor(themeAccent)
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.tag).stroke(themeBorder, lineWidth: 1))

            Button("Replace all") { doReplaceAll() }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundColor(themeAccent)
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .overlay(RoundedRectangle(cornerRadius: DS.Radius.tag).stroke(themeBorder, lineWidth: 1))

            Spacer()

            Button("✕") { findOpen = false }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundColor(themeGutterText)
                .padding(.horizontal, 4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(themeEditorBG)
        .overlay(alignment: .bottom) { themeBorder.frame(height: 1) }
    }

    private func findInput(_ placeholder: String, text: Binding<String>) -> some View {
        TextField(placeholder, text: text)
            .textFieldStyle(.plain)
            .font(.system(size: 11))
            .frame(width: 140)
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(themeCanvasBG)
            .foregroundColor(themeText)
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.tag).stroke(themeBorder, lineWidth: 1))
    }

    // MARK: Status bar  (20px)
    private var statusBar: some View {
        EditorStatusBarView(
            line: lastMatchLine ?? caretLine,
            column: caretColumn,
            encoding: "UTF-8",
            lineEnding: "LF",
            fileSizeText: fileSizeText,
            lineCount: lineCount,
            wordCount: wordCount,
            characterCount: charCount,
            saveStateText: saveStatusText,
            variantTitle: variant.title,
            findLine: lastMatchLine,
            findColumn: lastMatchColumn,
            darkMode: darkMode,
            variant: variant,
            foregroundColor: themeAccent.opacity(0.9),
            backgroundColor: themeEditorBG,
            borderColor: themeBorder,
            selectedTheme: editorTheme == .terminal ? .terminal : .light,
            onSelectTheme: { choice in
                editorTheme = (choice == .terminal) ? .terminal : .light
            }
        )
    }

    // MARK: Tab actions
    private func selectTab(id: String) {
        activeId = id
        guard let sessionID = sessionIDsByDocID[id] else { return }
        sessionStore.selectSession(id: sessionID)
        applySessionUIState(sessionID: sessionID)
    }

    private func applySessionUIState(sessionID: UUID) {
        guard let session = sessionStore.sessions.first(where: { $0.id == sessionID }) else { return }
        isApplyingSessionState = true
        focusMode = session.settings.focusModeEnabled
        typewriterMode = session.settings.typewriterModeEnabled
        fontScale = CGFloat(session.settings.fontScale)
        fontFamilyIndex = session.settings.fontFamilyIndex
        caretLine = session.cursor.line
        caretColumn = session.cursor.column
        isApplyingSessionState = false
    }

    private func addTab() {
        let id = UUID().uuidString
        docs.append(Doc(id: id, name: "untitled.txt", content: ""))

        let sessionID = sessionStore.openUntitledSession(initialText: "")
        sessionIDsByDocID[id] = sessionID

        activeId = id
        sessionStore.selectSession(id: sessionID)
        applySessionUIState(sessionID: sessionID)
        saveStatusText = "Unsaved"
    }

    private func closeTab(id: String) {
        guard docs.count > 1 else { return }
        let idx = docs.firstIndex(where: { $0.id == id }) ?? 0
        docs.removeAll(where: { $0.id == id })

        autosaveWorkItems[id]?.cancel()
        autosaveWorkItems[id] = nil

        if let sessionID = sessionIDsByDocID[id] {
            sessionStore.closeSession(id: sessionID)
        }
        sessionIDsByDocID[id] = nil

        if activeId == id {
            let nextActiveID = docs[max(0, idx - 1)].id
            activeId = nextActiveID
            if let nextSessionID = sessionIDsByDocID[nextActiveID] {
                sessionStore.selectSession(id: nextSessionID)
                applySessionUIState(sessionID: nextSessionID)
            }
        }
    }

    // MARK: Find/replace actions
    private func doFindNext() {
        guard !findQ.isEmpty else { return }

        let content = activeContent
        let start = max(0, min(searchCursor, content.count))
        let startIndex = content.index(content.startIndex, offsetBy: start)

        if let range = content.range(of: findQ, range: startIndex..<content.endIndex) ?? content.range(of: findQ) {
            let matchLocation = content.distance(from: content.startIndex, to: range.lowerBound)
            searchCursor = matchLocation + findQ.count

            let prefix = content[..<range.lowerBound]
            let line = prefix.split(separator: "\n", omittingEmptySubsequences: false).count
            let lastNewline = prefix.lastIndex(of: "\n")
            let columnBase = lastNewline.map { content.index(after: $0) } ?? content.startIndex
            let column = content.distance(from: columnBase, to: range.lowerBound) + 1

            lastMatchLine = max(1, line)
            lastMatchColumn = max(1, column)
        } else {
            searchCursor = 0
            lastMatchLine = nil
            lastMatchColumn = nil
        }
    }

    private func doReplaceAll() {
        guard !findQ.isEmpty else { return }
        setContent(activeContent.components(separatedBy: findQ).joined(separator: replaceQ))
        searchCursor = 0
        lastMatchLine = nil
        lastMatchColumn = nil
    }
}

// MARK: - Splash screen
private struct SplashView: View {
    @Binding var done: Bool
    var dark: Bool

    @State private var opacity: Double = 1

    var body: some View {
        ZStack {
            (dark ? Color(red: 22/255, green: 20/255, blue: 26/255)
                  : Color(red: 250/255, green: 250/255, blue: 247/255))
            .ignoresSafeArea()

            HStack(spacing: 18) {
                InitialMarkView(size: 72 * 1.3, dark: dark)
                VStack(alignment: .leading, spacing: 5) {
                    Text("Escritoire")
                        .font(.system(size: 40 * 1.3, weight: .medium, design: .serif))
                        .foregroundColor(dark ? Color(red: 250/255, green: 250/255, blue: 247/255)
                                              : Color(red: 43/255, green: 40/255, blue: 37/255))
                        .tracking(-0.8 * 1.3)
                    Text("A WRITING DESK")
                        .font(.system(size: 11 * 1.3, weight: .regular, design: .monospaced))
                        .foregroundColor(dark ? Color(red: 158/255, green: 154/255, blue: 143/255)
                                              : Color(red: 120/255, green: 116/255, blue: 108/255))
                        .tracking(2.4 * 1.3)
                }
            }
        }
        .opacity(opacity)
        .allowsHitTesting(true) // blocks interaction until dismissed
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation(.easeOut(duration: 0.6)) { opacity = 0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { done = true }
            }
        }
    }
}

// MARK: - Tweaks panel
private struct TweaksPanel: View {
    @Binding var variant: EditorVariant
    @Binding var darkMode: Bool
    var onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Tweaks")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10))
                        .foregroundColor(Color(white: 0.5))
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("THEME")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(white: 0.45))
                    .tracking(1.5)

                HStack(spacing: 0) {
                    themeButton("Light", active: !darkMode) { darkMode = false }
                    themeButton("Dark",  active: darkMode)  { darkMode = true }
                }
                .background(Color(white: 0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("VARIANT")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(white: 0.45))
                    .tracking(1.5)

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(EditorVariant.allCases) { v in variantRow(v) }
                }
            }
        }
        .padding(16)
        .frame(width: 260)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 28/255, green: 26/255, blue: 22/255, opacity: 0.96))
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
        .padding(20)
        .allowsHitTesting(true)
    }

    private func themeButton(_ label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(active ? .white : Color(white: 0.5))
                .padding(.vertical, 5)
                .padding(.horizontal, 16)
                .background(active ? Color(white: 0.28) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(.plain)
    }

    private func variantRow(_ v: EditorVariant) -> some View {
        Button(action: { variant = v }) {
            HStack(spacing: 8) {
                Circle()
                    .fill(v == variant ? Tok.ochre : Color.clear)
                    .frame(width: 5, height: 5)
                    .overlay(Circle().stroke(Color(white: 0.4), lineWidth: v == variant ? 0 : 1))
                Text(v.title)
                    .font(.system(size: 12))
                    .foregroundColor(v == variant ? .white : Color(white: 0.55))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - InitialMark (brand.jsx #04)
struct InitialMarkView: View {
    var size: CGFloat = 32
    var dark: Bool = false

    private var paper: Color {
        dark ? Color(hex: "#1A1D23")
             : Color(hex: "#FFFFFF")
    }
    private var ink: Color {
        dark ? Color(hex: "#E8ECF3")
             : Color(hex: "#1A1F28")
    }
    private var gutter: Color {
        dark ? Color(hex: "#3A4352")
             : Color(hex: "#D7DEE8")
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.175).fill(paper)

            // Gutter line at x=44 in 160-wide viewBox → ratio 0.275
            Path { path in
                let x = size * 0.275
                path.move(to: CGPoint(x: x, y: size * 0.26))
                path.addLine(to: CGPoint(x: x, y: size * 0.74))
            }
            .stroke(gutter, lineWidth: max(0.5, size * 0.007))

            // "1" in ochre, right-aligned at x=36/160=0.225
            Text("1")
                .font(.system(size: size * 0.1125, weight: .medium, design: .monospaced))
                .foregroundColor(Tok.ochre)
                .position(x: size * 0.225, y: size * 0.6125)

            // "E" in serif, right of gutter. SVG left-aligns at x=56/160; glyph center ≈ x=88, y=78.
            Text("E")
                .font(.system(size: size * 0.65, weight: .medium, design: .serif))
                .foregroundColor(ink)
                .kerning(-0.0125 * size)
                .position(x: size * 0.57, y: size * 0.49)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.175))
    }
}

#Preview {
    ContentView(
        document: .constant(TextDocument(text: "The Desk at Dusk\n— a short poem\n\nI keep my words on a wooden plank,")),
        fileURL: nil
    )
}
