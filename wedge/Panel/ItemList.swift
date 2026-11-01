import SwiftUI

/// The list: Now as row 1 (the ring header), the Up Next label, then Up Next rows numbered
/// from 2. Rows drag by their whole body (onto the top to become Now); click or ↩ edits in
/// place; ⌫ deletes; ⌥⌘↑/↓ and the VoiceOver Move Up / Move Down actions reorder.
/// During the Done moment the completed item holds the Now slot; rows keep their identity
/// (`item.id`), so when it leaves the List animates the next row up into its place.
struct ItemList: View {
    static let rowHeight: CGFloat = 28
    static let nowRowHeight: CGFloat = 36
    static let maxVisibleUpNextRows = 8
    private static let messageHeight: CGFloat = 16

    let store: WedgeStore
    let doneAction: DoneAction
    let announce: (String) -> Void
    /// The Done whose completed item still holds the Now slot (see `DoneMoment`).
    let completing: DoneEvent?
    @Binding var selection: UUID?
    @Binding var edit: RowEdit?
    var focus: FocusState<PanelFocus?>.Binding
    /// ↓ from the last row.
    let onLeaveBottom: () -> Void

    @Environment(PanelController.self) private var panel
    // Not private: the row actions in ItemList+Editing.swift update them.
    @State var refused = false
    /// The last rejected edit, shown under its row until the next edit starts.
    @State var rowError: RowError?

    var body: some View {
        List(selection: $selection) {
            ForEach(PanelRows.rows(for: store.items, completing: completing)) { row in
                switch row {
                case .item(let item, let position):
                    itemRow(item, position: position).tag(item.id)
                case .completing(let event):
                    DonePopRow(event: event)
                        .frame(minHeight: Self.nowRowHeight)
                        .moveDisabled(true)
                        .selectionDisabled(true)
                        .accessibilityHidden(true)  // Done already announced the result
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
                guard completing == nil else { return }  // display offsets don't map to the store yet
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
        .modifier(ItemListKeys(list: self))
        .onChange(of: store.items) { _, items in
            selection = PanelRows.retargetedSelection(selection, in: items)
        }
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
            font: isNow ? NowRowStyle.titleFont : .body,
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
        .accessibilityIdentifier(isNow ? AccessibilityID.nowHeader : AccessibilityID.upNextRow(position))
        .accessibilityAction(named: WedgeCopy.moveUp) { move(item.id, by: -1) }
        .accessibilityAction(named: WedgeCopy.moveDown) { move(item.id, by: 1) }
        .contextMenu {
            Button(WedgeCopy.delete) { delete(item.id) }
        }
    }

    /// Fits Now, the label and up to `maxVisibleUpNextRows` rows, then the list scrolls.
    private var height: CGFloat {
        let count = store.items.count + (completing == nil ? 0 : 1)
        guard count > 0 else { return 0 }
        let upNext = count - 1
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
}
