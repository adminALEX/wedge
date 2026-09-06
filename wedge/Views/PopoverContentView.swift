import AppKit
import SwiftUI

/// Panel content: one-thing + up-next list with add, inline edit,
/// delete (context menu or ⌫), drag reorder, and Done via ⌘↩ (plus
/// status-item shortcuts outside this view).
/// Hosted in a floating `NSPanel` from `StatusItemController` (not a transient popover).
///
/// `onChange` is called after any list mutation (add/edit/delete/move) so
/// the controller can persist and refresh the status item title.
/// `onDone` is the single Done path — the controller owns
/// `performDone()` (complete-one-thing + persist + refresh).
struct PopoverContentView: View {
    let store: WedgeStore
    var onChange: () -> Void
    var onDone: () -> Void

    @State private var draft = ""
    @State private var selection: UUID?
    @State private var donePulse = false
    @FocusState private var isAddFieldFocused: Bool

    private var addPlaceholder: String {
        store.items.isEmpty ? "What's your one thing?" : "Add to up next…"
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
        // Hidden control so ⌘↩ still marks Done without a visible button.
        .background {
            Button("Done") { onDone() }
                .keyboardShortcut(.return, modifiers: .command)
                .opacity(0)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
                .disabled(store.oneThing == nil)
        }
        .onAppear { focusAddField() }
        .onReceive(NotificationCenter.default.publisher(for: .wedgePanelDidOpen)) { _ in
            focusAddField()
        }
        .onReceive(NotificationCenter.default.publisher(for: .wedgeDidPop)) { _ in
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
                store.move(from: indices, to: newOffset)
                onChange()
            }
            .onDelete { indexSet in
                // Resolve IDs up front: deleting by index while mutating the
                // same array would shift the remaining offsets.
                let ids = indexSet.map { store.items[$0].id }
                ids.forEach { store.delete(id: $0) }
                onChange()
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .frame(maxHeight: .infinity)
        .onDeleteCommand { deleteSelection() }
    }

    private func itemRow(_ item: WedgeItem) -> some View {
        HStack(alignment: .center, spacing: 10) {
            NotionDragHandle()
            ItemRow(
                item: item,
                isOneThing: item.id == store.oneThing?.id,
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
            Button("Delete") {
                store.delete(id: item.id)
                if selection == item.id { selection = nil }
                onChange()
            }
        }
    }

    private var addField: some View {
        TextField(addPlaceholder, text: $draft)
            .textFieldStyle(.roundedBorder)
            .focused($isAddFieldFocused)
            .onSubmit { submitDraft() }
    }

    private func focusAddField() {
        // Defer until the panel is key so AppKit focus sticks.
        DispatchQueue.main.async {
            isAddFieldFocused = true
        }
    }

    private func deleteSelection() {
        guard let selection else { return }
        store.delete(id: selection)
        self.selection = nil
        onChange()
    }

    private func submitDraft() {
        do {
            _ = try store.add(draft)
            draft = ""
            onChange()
        } catch {
            NSSound.beep()
        }
    }
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
        .accessibilityLabel("Drag to reorder")
    }
}

/// A single editable row. Keeps its own draft text so the store is only
/// mutated on submit or blur — editing through the store on every keystroke
/// would reject transient empty/whitespace states mid-typing.
private struct ItemRow: View {
    let item: WedgeItem
    let isOneThing: Bool
    let commit: (String) -> Bool

    @State private var text: String
    @FocusState private var isFocused: Bool

    init(item: WedgeItem, isOneThing: Bool, commit: @escaping (String) -> Bool) {
        self.item = item
        self.isOneThing = isOneThing
        self.commit = commit
        _text = State(initialValue: item.text)
    }

    var body: some View {
        TextField("Item", text: $text)
            .textFieldStyle(.plain)
            .font(isOneThing ? .body.weight(.semibold) : .body)
            .focused($isFocused)
            .onSubmit { commitDraft() }
            .onChange(of: isFocused) { _, focused in
                if !focused { commitDraft() }
            }
            .onChange(of: item.text) { _, newText in
                if !isFocused { text = newText }
            }
    }

    private func commitDraft() {
        guard text != item.text else { return }
        if !commit(text) {
            NSSound.beep()
            text = item.text
        }
    }
}
