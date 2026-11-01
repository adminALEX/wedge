import SwiftUI

/// The list: Now as row 1 (the ring header), the Up Next label, then Up Next rows numbered
/// from 2. Rows drag by their whole body (onto the top to become Now); click or ↩ edits in
/// place; ⌫ deletes; ⌥⌘↑/↓ and the VoiceOver Move Up / Move Down actions reorder.
struct ItemList: View {
    static let rowHeight: CGFloat = 28
    static let nowRowHeight: CGFloat = 36
    static let maxVisibleUpNextRows = 8
    private static let messageHeight: CGFloat = 16

    let store: WedgeStore
    let doneAction: DoneAction
    let announce: (String) -> Void
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
            ForEach(PanelRows.rows(for: store.items)) { row in
                switch row {
                case .item(let item, let position):
                    itemRow(item, position: position).tag(item.id)
                case .upNextLabel:
                    VStack(alignment: .leading, spacing: 6) {
                        Divider()
                        SectionLabel(WedgeCopy.upNext)
                    }
                    .frame(height: Self.rowHeight)
                    .moveDisabled(true)
                    .selectionDisabled(true)
                }
            }
            .onMove { offsets, destination in
                let move = PanelRows.storeMove(from: offsets, to: destination)
                guard !move.offsets.isEmpty else { return }
                store.move(fromOffsets: move.offsets, toOffset: move.destination)
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollBounceBehavior(.basedOnSize)
        .environment(\.defaultMinListRowHeight, Self.rowHeight)
        .frame(height: height)
        .focused(focus, equals: .list)
        .modifier(ItemListKeys(list: self))
        .onChange(of: focus.wrappedValue) { old, new in
            if case .row(let id) = old, new != old, edit?.id == id { commit() }
        }
        .onChange(of: panel.isVisible) { _, isVisible in
            if !isVisible { commit() }  // hiding by any route but Esc saves the edit
        }
        .onChange(of: edit?.id) { _, id in
            panel.cancelEdit = id == nil ? nil : { cancelEditIfAny() }
        }
        .onDisappear { panel.cancelEdit = nil }
    }

    @ViewBuilder
    private func itemRow(_ item: WedgeItem, position: Int) -> some View {
        let isNow = position == 1
        let isEditing = edit?.id == item.id
        let title = EditableTitle(
            item: item,
            font: isNow ? .title3.weight(.semibold) : .body,
            isEditing: isEditing,
            text: editText,
            refused: $refused,
            message: message(for: item.id),
            focus: focus,
            titleAccessibilityLabel: isNow ? WedgeCopy.nowAccessibility(item.text) : nil,
            onStart: { startEdit(item.id) },
            onCommit: { commit() },
            onCancel: { cancelEdit() }
        )
        Group {
            if isNow {
                NowHeader(item: item, doneAction: doneAction) { title }
                    .frame(minHeight: Self.nowRowHeight)
            } else {
                HStack(spacing: 4) {
                    Text(position, format: .number)
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 20, alignment: .trailing)
                    title
                }
                .frame(minHeight: Self.rowHeight)
            }
        }
        // The Now row keeps its ring and title reachable; other rows read as one element.
        .accessibilityElement(children: isNow || isEditing ? .contain : .ignore)
        .accessibilityLabel(WedgeCopy.rowAccessibility(position, of: store.items.count, item.text))
        .accessibilityAction(named: WedgeCopy.moveUp) { move(item.id, by: -1) }
        .accessibilityAction(named: WedgeCopy.moveDown) { move(item.id, by: 1) }
        .contextMenu {
            Button(WedgeCopy.delete) { delete(item.id) }
        }
    }

    /// Fits Now, the label and up to `maxVisibleUpNextRows` rows, then the list scrolls.
    private var height: CGFloat {
        guard !store.items.isEmpty else { return 0 }
        let upNext = store.upNext.count
        let label = upNext > 0 ? Self.rowHeight : 0
        let rows = CGFloat(min(upNext, Self.maxVisibleUpNextRows)) * Self.rowHeight
        let hasMessage = store.items.contains { message(for: $0.id) != nil }
        return Self.nowRowHeight + label + rows + (hasMessage ? Self.messageHeight : 0)
    }

    private var editText: Binding<String> {
        Binding(get: { edit?.text ?? "" }, set: { edit?.text = $0 })
    }

    private func message(for id: UUID) -> String? {
        if refused, edit?.id == id { return WedgeCopy.maxCharacters }
        return rowError?.id == id ? rowError?.message : nil
    }

    func startEdit(_ id: UUID) {
        if edit?.id != id { commit() }
        guard let item = store.items.first(where: { $0.id == id }) else { return }
        rowError = nil
        refused = false
        selection = id
        edit = RowEdit(id: id, text: item.text)
    }

    /// Saves the edit when its normalized text differs; a rejected edit keeps the old text and shows why.
    private func commit() {
        guard let edit else { return }
        self.edit = nil
        refused = false
        if let item = store.items.first(where: { $0.id == edit.id }) {
            do {
                let text = try WedgeStore.normalized(edit.text)
                if text != item.text { try store.update(id: edit.id, text: text) }
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

    /// For `PanelController.cancelEdit`: cancels an open edit and reports whether there was one.
    private func cancelEditIfAny() -> Bool {
        guard edit != nil else { return false }
        cancelEdit()
        return true
    }

    /// Deletes the item and selects the one that takes its place (or the new last row).
    func delete(_ id: UUID) {
        guard let index = store.items.firstIndex(where: { $0.id == id }) else { return }
        if edit?.id == id {
            edit = nil
            focus.wrappedValue = .list  // the focused field goes away with the row
        }
        store.delete(id: id)
        guard selection == id else { return }
        selection = store.items.indices.contains(index) ? store.items[index].id : store.items.last?.id
    }

    func move(_ id: UUID, by delta: Int) {
        let before = store.items.firstIndex { $0.id == id }
        store.move(id: id, by: delta)
        guard let after = store.items.firstIndex(where: { $0.id == id }), after != before else { return }
        announce(WedgeCopy.movedTo(after + 1))
    }
}

private struct RowError: Equatable {
    let id: UUID
    let message: String
}
