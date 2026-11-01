import SwiftUI

/// The list's own keys (spec §6), active while the list has focus and no row is being edited:
/// ↩ edits the selected row, ⌫ deletes it, ⌥⌘↑/↓ moves it, ↓ on the last row returns to the add field.
struct ItemListKeys: ViewModifier {
    let list: ItemList

    func body(content: Content) -> some View {
        content
            .onKeyPress(.return) {
                guard list.edit == nil, let id = list.selection else { return .ignored }
                list.startEdit(id)
                return .handled
            }
            .onKeyPress(keys: [.upArrow, .downArrow]) { press in
                guard list.edit == nil else { return .ignored }
                let delta = press.key == .upArrow ? -1 : 1
                if press.modifiers.contains(.command), press.modifiers.contains(.option) {
                    guard let id = list.selection else { return .ignored }
                    list.move(id, by: delta)
                    return .handled
                }
                if delta == 1, press.modifiers.isDisjoint(with: [.command, .option, .control, .shift]),
                    list.selection != nil, list.selection == list.store.items.last?.id {
                    list.onLeaveBottom()
                    return .handled
                }
                return .ignored
            }
            .onDeleteCommand {
                guard list.edit == nil, let id = list.selection else { return }
                list.delete(id)
            }
    }
}
