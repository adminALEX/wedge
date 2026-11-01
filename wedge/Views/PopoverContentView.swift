import AppKit
import SwiftUI

/// Panel content: one-thing + up-next list with add, inline edit,
/// delete (context menu or ⌫), drag reorder, and Done via ⌘↩ (plus
/// status-item shortcuts outside this view).
/// Hosted in a floating `NSPanel` from `StatusItemController` (not a transient popover).
///
/// `onChange` is called after any list mutation (add/edit/delete/move) so
/// the controller can refresh the status item title (the store saves itself).
/// `onDone` is the single Done path — the controller runs `DoneAction.perform()`
/// and refreshes the title. `doneAction.lastEvent` drives the brief confirmation pulse.
struct PopoverContentView: View {
    let store: WedgeStore
    let doneAction: DoneAction
    var onChange: () -> Void
    var onDone: () -> Void

    @State private var draft = ""
    @State private var selection: UUID?
    @State private var donePulse = false
    /// Which row is in edit mode (Text → TextField). Selection drives ↑/↓/⌫;
    /// tap-to-edit keeps TextFields from fighting List selection.
    @State private var editingItemID: UUID?
    @FocusState private var focus: PanelFocus?

    private var addPlaceholder: String {
        store.items.isEmpty ? WedgeCopy.addOneThingPlaceholder : WedgeCopy.addUpNextPlaceholder
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            list
            addField
        }
        .padding(.top, 10)
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
        .frame(width: 300)
        .opacity(donePulse ? 0.85 : 1)
        .background {
            Button(WedgeCopy.done) { onDone() }
                .keyboardShortcut(.return, modifiers: .command)
                .opacity(0)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .disabled(store.now == nil)
        }
        .onAppear { focusAddField() }
        .onReceive(NotificationCenter.default.publisher(for: .wedgePanelDidOpen)) { _ in
            focusAddField()
        }
        .onChange(of: doneAction.lastEvent?.id) { _, newID in
            guard newID != nil else { return }
            withAnimation(.easeOut(duration: 0.15)) { donePulse = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeIn(duration: 0.15)) { donePulse = false }
            }
        }
    }

    private var list: some View {
        List(selection: $selection) {
            ForEach(store.items) { item in
                itemRow(item)
                    .tag(item.id)
                    .listRowInsets(EdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6))
            }
            .onMove { indices, newOffset in
                store.move(fromOffsets: indices, toOffset: newOffset)
                onChange()
            }
            .onDelete { indexSet in
                let ids = indexSet.map { store.items[$0].id }
                ids.forEach { store.delete(id: $0) }
                if let editingItemID, ids.contains(editingItemID) {
                    self.editingItemID = nil
                }
                if let selection, ids.contains(selection) {
                    self.selection = nil
                }
                onChange()
            }
        }
        .listStyle(.inset)
        .frame(maxHeight: .infinity)
        .onDeleteCommand { deleteSelectedItem() }
    }

    private func itemRow(_ item: WedgeItem) -> some View {
        HStack(alignment: .center, spacing: 10) {
            NotionDragHandle()
            ItemRow(
                item: item,
                isOneThing: item.id == store.now?.id,
                isEditing: editingItemID == item.id,
                focus: $focus,
                onStartEditing: {
                    editingItemID = item.id
                    focus = .item(item.id)
                },
                onEndEditing: {
                    if editingItemID == item.id {
                        editingItemID = nil
                    }
                    if focus == .item(item.id) {
                        focus = .add
                    }
                },
                commit: { newText in
                    do {
                        try store.update(id: item.id, text: newText)
                        onChange()
                        return true
                    } catch {
                        return false
                    }
                }
            )
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button(WedgeCopy.delete) {
                store.delete(id: item.id)
                if editingItemID == item.id { editingItemID = nil }
                if selection == item.id { selection = nil }
                onChange()
            }
        }
    }

    private var addField: some View {
        TextField(addPlaceholder, text: $draft)
            .textFieldStyle(.roundedBorder)
            .focused($focus, equals: .add)
            .onSubmit { submitDraft() }
            .onChange(of: focus) { _, newFocus in
                if newFocus == .add { editingItemID = nil }
            }
    }

    private func focusAddField() {
        editingItemID = nil
        selection = nil
        DispatchQueue.main.async {
            focus = .add
        }
    }

    private func deleteSelectedItem() {
        // ponytail: List selection owns ⌫; TextFields own ⌫ while focused
        guard editingItemID == nil, focus != .add else { return }
        guard let id = selection else { return }
        store.delete(id: id)
        selection = nil
        onChange()
    }

    private func submitDraft() {
        do {
            _ = try store.add(draft)
            draft = ""
            onChange()
            focus = .add
        } catch {
            NSSound.beep()
        }
    }
}

private enum PanelFocus: Hashable {
    case add
    case item(UUID)
}

/// Notion-style 2×3 grip — visual affordance; reorder still uses `List`/`onMove`.
private struct NotionDragHandle: View {
    var body: some View {
        VStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: 3) {
                    Circle().frame(width: 2.5, height: 2.5)
                    Circle().frame(width: 2.5, height: 2.5)
                }
            }
        }
        .foregroundStyle(.secondary.opacity(0.7))
        .frame(width: 14, height: 22, alignment: .center)
        .accessibilityLabel(WedgeCopy.dragToReorder)
    }
}

/// Idle rows show `Text` (List-clickable); tap swaps in a focused `TextField`.
/// Commits on Return or when edit mode ends.
private struct ItemRow: View {
    let item: WedgeItem
    let isOneThing: Bool
    let isEditing: Bool
    var focus: FocusState<PanelFocus?>.Binding
    let onStartEditing: () -> Void
    let onEndEditing: () -> Void
    let commit: (String) -> Bool

    @State private var text: String

    init(
        item: WedgeItem,
        isOneThing: Bool,
        isEditing: Bool,
        focus: FocusState<PanelFocus?>.Binding,
        onStartEditing: @escaping () -> Void,
        onEndEditing: @escaping () -> Void,
        commit: @escaping (String) -> Bool
    ) {
        self.item = item
        self.isOneThing = isOneThing
        self.isEditing = isEditing
        self.focus = focus
        self.onStartEditing = onStartEditing
        self.onEndEditing = onEndEditing
        self.commit = commit
        _text = State(initialValue: item.text)
    }

    var body: some View {
        Group {
            if isEditing {
                TextField(WedgeCopy.itemFieldAccessibility, text: $text)
                    .textFieldStyle(.plain)
                    .font(rowFont)
                    .focused(focus, equals: .item(item.id))
                    .onSubmit {
                        commitDraft()
                        onEndEditing()
                    }
                    .onAppear {
                        DispatchQueue.main.async {
                            focus.wrappedValue = .item(item.id)
                        }
                    }
            } else {
                Text(text)
                    .font(rowFont)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 1) {
                        onStartEditing()
                    }
            }
        }
        .onChange(of: isEditing) { wasEditing, editing in
            if wasEditing && !editing {
                commitDraft()
            }
        }
        .onChange(of: item.text) { _, newText in
            if !isEditing { text = newText }
        }
    }

    private var rowFont: Font {
        isOneThing ? .body.weight(.semibold) : .body
    }

    private func commitDraft() {
        guard text != item.text else { return }
        if !commit(text) {
            NSSound.beep()
            text = item.text
        }
    }
}
