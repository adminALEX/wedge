import SwiftUI

/// Up Next rows, numbered from 2. Rows drag by their whole body; click or ↩ edits in place
/// (↩ saves, Esc cancels, focus elsewhere saves); ⌫ deletes; ⌥⌘↑/↓ and the VoiceOver
/// Move Up / Move Down actions reorder.
struct UpNextList: View {
    static let rowHeight: CGFloat = 28
    static let maxVisibleRows = 8
    private static let messageHeight: CGFloat = 16

    let store: WedgeStore
    @Binding var selection: UUID?
    @Binding var edit: RowEdit?
    var focus: FocusState<PanelFocus?>.Binding
    /// ↓ from the last row.
    let onLeaveBottom: () -> Void

    @Environment(PanelController.self) private var panel
    @State private var refused = false
    /// The last rejected edit, shown under its row until the next edit starts.
    @State private var rowError: RowError?

    var body: some View {
        List(selection: $selection) {
            ForEach(Array(store.upNext.enumerated()), id: \.element.id) { offset, item in
                row(item, position: offset + 2)
                    .tag(item.id)
                    .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                    .listRowSeparator(.hidden)
            }
            .onMove { offsets, destination in
                // List offsets count from row 2; the store's count from Now.
                store.move(fromOffsets: IndexSet(offsets.map { $0 + 1 }), toOffset: destination + 1)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .environment(\.defaultMinListRowHeight, Self.rowHeight)
        .frame(height: height)
        .focused(focus, equals: .list)
        .onKeyPress(.return) {
            guard edit == nil, let selection else { return .ignored }
            startEdit(selection)
            return .handled
        }
        .onKeyPress(keys: [.upArrow, .downArrow]) { press in
            guard edit == nil else { return .ignored }
            let delta = press.key == .upArrow ? -1 : 1
            if press.modifiers.contains(.command), press.modifiers.contains(.option) {
                guard let selection else { return .ignored }
                move(selection, by: delta)
                return .handled
            }
            if delta == 1, press.modifiers.isDisjoint(with: [.command, .option, .control, .shift]),
                selection != nil, selection == store.upNext.last?.id {
                onLeaveBottom()
                return .handled
            }
            return .ignored
        }
        .onDeleteCommand {
            guard edit == nil, let selection else { return }
            delete(selection)
        }
        .onChange(of: focus.wrappedValue) { old, new in
            if case .row(let id) = old, new != old, edit?.id == id { commit() }
        }
        .onChange(of: panel.isVisible) { _, isVisible in
            if !isVisible { commit() }
        }
    }

    private func row(_ item: WedgeItem, position: Int) -> some View {
        let isEditing = edit?.id == item.id
        return VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 8) {
                Text(position, format: .number)
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 16, alignment: .trailing)
                if isEditing {
                    TextField(item.text, text: editText)
                        .textFieldStyle(.plain)
                        .focused(focus, equals: .row(item.id))
                        .inputLimit(editText, refused: $refused)
                        .onSubmit { commit() }
                        .onKeyPress(.escape) {
                            cancelEdit()
                            return .handled  // never reaches the panel, which would close
                        }
                        .onAppear { focus.wrappedValue = .row(item.id) }
                        .onDisappear { commit() }  // the row became Now or left the list
                } else {
                    Text(item.text)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(.rect)
                        .onTapGesture { startEdit(item.id) }
                }
            }
            if let message = message(for: item.id) {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.leading, 24)
            }
        }
        .frame(minHeight: Self.rowHeight)
        .accessibilityElement(children: isEditing ? .contain : .ignore)
        .accessibilityLabel(WedgeCopy.rowAccessibility(position, of: store.items.count, item.text))
        .accessibilityAction(named: WedgeCopy.moveUp) { move(item.id, by: -1) }
        .accessibilityAction(named: WedgeCopy.moveDown) { move(item.id, by: 1) }
        .contextMenu {
            Button(WedgeCopy.delete) { delete(item.id) }
        }
    }

    /// Fits the rows up to `maxVisibleRows`, then the list scrolls.
    private var height: CGFloat {
        let rows = CGFloat(min(store.upNext.count, Self.maxVisibleRows)) * Self.rowHeight
        let hasMessage = store.upNext.contains { message(for: $0.id) != nil }
        return rows + (hasMessage ? Self.messageHeight : 0)
    }

    private var editText: Binding<String> {
        Binding(get: { edit?.text ?? "" }, set: { edit?.text = $0 })
    }

    private func message(for id: UUID) -> String? {
        if refused, edit?.id == id { return WedgeCopy.maxCharacters }
        return rowError?.id == id ? rowError?.message : nil
    }

    private func startEdit(_ id: UUID) {
        if edit?.id != id { commit() }
        guard let item = store.items.first(where: { $0.id == id }) else { return }
        rowError = nil
        refused = false
        selection = id
        edit = RowEdit(id: id, text: item.text)
    }

    /// Saves the edit if the text changed; a rejected edit keeps the old text and shows why.
    private func commit() {
        guard let edit else { return }
        self.edit = nil
        refused = false
        if let item = store.items.first(where: { $0.id == edit.id }), item.text != edit.text {
            do {
                try store.update(id: edit.id, text: edit.text)
            } catch {
                rowError = RowError(id: edit.id, message: WedgeCopy.message(for: error))
            }
        }
        if focus.wrappedValue == .row(edit.id) { focus.wrappedValue = .list }
    }

    private func cancelEdit() {
        guard let edit else { return }
        self.edit = nil
        refused = false
        focus.wrappedValue = .list
        selection = edit.id
    }

    /// Deletes the row and selects the one that takes its place (or the new last row).
    private func delete(_ id: UUID) {
        guard let index = store.items.firstIndex(where: { $0.id == id }) else { return }
        if edit?.id == id { edit = nil }
        store.delete(id: id)
        guard selection == id else { return }
        selection = store.upNext.indices.contains(index) ? store.items[index].id : store.upNext.last?.id
    }

    private func move(_ id: UUID, by delta: Int) {
        let before = store.items.firstIndex { $0.id == id }
        store.move(id: id, by: delta)
        guard let after = store.items.firstIndex(where: { $0.id == id }), after != before else { return }
        if after == 0 { selection = nil }  // it is Now, no longer a row
        AccessibilityNotification.Announcement(WedgeCopy.movedTo(after + 1)).post()
    }
}

private struct RowError: Equatable {
    let id: UUID
    let message: String
}
