import SwiftUI

struct EditorShellView<EditorContent: View>: View {
    var showTopBar: Bool
    var showTabBar: Bool
    var showCommandBar: Bool
    var showFindBar: Bool
    var showStatusBar: Bool

    let topBar: AnyView
    let tabBar: AnyView
    let commandBar: AnyView
    let findBar: AnyView
    let editorContent: EditorContent
    let statusBar: AnyView
    let background: Color

    init(
        showTopBar: Bool,
        showTabBar: Bool,
        showCommandBar: Bool,
        showFindBar: Bool,
        showStatusBar: Bool,
        background: Color,
        topBar: AnyView,
        tabBar: AnyView,
        commandBar: AnyView,
        findBar: AnyView,
        statusBar: AnyView,
        @ViewBuilder editorContent: () -> EditorContent
    ) {
        self.showTopBar = showTopBar
        self.showTabBar = showTabBar
        self.showCommandBar = showCommandBar
        self.showFindBar = showFindBar
        self.showStatusBar = showStatusBar
        self.background = background
        self.topBar = topBar
        self.tabBar = tabBar
        self.commandBar = commandBar
        self.findBar = findBar
        self.statusBar = statusBar
        self.editorContent = editorContent()
    }

    var body: some View {
        VStack(spacing: 0) {
            if showTopBar { topBar }
            if showTabBar { tabBar }
            if showCommandBar { commandBar }
            if showFindBar { findBar }
            editorContent
            if showStatusBar { statusBar }
        }
        .background(background)
    }
}
