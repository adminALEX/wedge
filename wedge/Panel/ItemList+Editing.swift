import SwiftUI

/// The list's row actions: the inline edit's lifecycle (start, commit, cancel), delete and move.
extension ItemList {
    func startEdit(_ id: UUID) {
        if edit?.id != id { commit() }
        guard let item = store.items.first(where: { $0.id == id }) else { return }
        rowError = nil
        refused = false
        selection = id
        edit = RowEdit(id: id, text: item.text)
    }

    /// Saves the edit when its normalized text differs; a rejected edit keeps the old text and shows why.
    func commit() {
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

    func cancelEdit() {
        guard let edit else { return }
        self.edit = nil
        refused = false
        focus.wrappedValue = .list
        selection = edit.id
    }

    /// For `PanelController.cancelEdit`: cancels an open edit and reports whether there was one.
    func cancelEditIfAny() -> Bool {
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

/// A rejected edit: which row, and why.
struct RowError: Equatable {
    let id: UUID
    let message: String
}
