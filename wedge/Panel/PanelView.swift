import SwiftUI

/// Where keyboard focus is in the panel.
enum PanelFocus: Hashable {
    case add
    case list
    case row(UUID)
}

/// An Up Next row being edited in place, with its uncommitted text.
struct RowEdit: Equatable {
    let id: UUID
    var text: String
}

/// The panel content (spec §3.1, A1) on Liquid Glass: issue banner, Now, Up Next, add field
/// and hint row. Owns focus, selection, the add draft and the inline edit, so ⌘Z can tell
/// unsaved typing from Undo Done.
struct PanelView: View {
    let store: WedgeStore
    let doneAction: DoneAction

    @Environment(PanelController.self) private var panel
    @State private var draft = ""
    @State private var selection: UUID?
    @State private var edit: RowEdit?
    @FocusState private var focus: PanelFocus?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let issue = store.issue {
                IssueBanner(issue: issue)
            }
            if let now = store.now {
                section(WedgeCopy.now) {
                    NowHeader(item: now, doneAction: doneAction)
                }
                Divider()
                section(WedgeCopy.upNext) {
                    if !store.upNext.isEmpty {
                        UpNextList(
                            store: store,
                            selection: $selection,
                            edit: $edit,
                            focus: $focus,
                            onLeaveBottom: focusAddField
                        )
                    }
                }
            }
            AddField(
                store: store,
                draft: $draft,
                focus: $focus,
                onMoveUp: selectLastRow,
                onClose: { panel.hide() }
            )
            Text(WedgeCopy.panelHint)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(width: PanelAnchor.width)
        .fixedSize(horizontal: false, vertical: true)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
        .background { shortcuts }
        .defaultFocus($focus, .add)
        .onChange(of: panel.isVisible) { _, isVisible in
            if isVisible { focusAddField() }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(WedgeCopy.appName)
    }

    private func section<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            content()
        }
    }

    /// Panel-wide shortcuts. Disabled buttons let the key go on (⌘Z then reaches the field's undo).
    private var shortcuts: some View {
        Group {
            Button(WedgeCopy.done) { doneAction.perform() }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(store.now == nil)
            Button(WedgeCopy.settingsMenu) { panel.openSettings() }
                .keyboardShortcut(",", modifiers: .command)
            Button(WedgeCopy.undoDoneMenu) { doneAction.undo() }
                .keyboardShortcut("z", modifiers: .command)
                .disabled(undoRoute != .done)
        }
        .focusable(false)
        .opacity(0)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var undoRoute: UndoRoute {
        UndoRoute.resolve(fieldHasUnsavedTyping: fieldHasUnsavedTyping, canUndoDone: store.canUndoDone)
    }

    /// The focused field's text differs from what is saved.
    private var fieldHasUnsavedTyping: Bool {
        switch focus {
        case .add:
            return !draft.isEmpty
        case .row(let id):
            guard let edit, edit.id == id else { return false }
            return store.items.first { $0.id == id }?.text != edit.text
        case .list, nil:
            return false
        }
    }

    private func focusAddField() {
        selection = nil
        focus = .add
    }

    /// ↑ from the add field enters the list at its last row.
    private func selectLastRow() {
        guard let last = store.upNext.last else { return }
        selection = last.id
        focus = .list
    }
}
