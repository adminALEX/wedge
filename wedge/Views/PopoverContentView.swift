import AppKit
import SwiftUI

/// Full popover UI: one-thing + up-next list with add, inline edit,
/// delete (swipe or ⌫), drag reorder, and Done (header button or ⌘↩).
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

    private var addPlaceholder: String {
        store.items.isEmpty ? "What's your one thing?" : "Add to up next…"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            list
            addField
        }
        .padding(12)
        .frame(width: 280)
    }

    private var header: some View {
        HStack {
            Text("Wedge")
                .font(.headline)
            Spacer()
            Button("Done") { onDone() }
                .disabled(store.oneThing == nil)
                .keyboardShortcut(.return, modifiers: .command)
        }
    }

    private var list: some View {
        List(selection: $selection) {
            ForEach(store.items) { item in
                itemRow(item)
                    .tag(item.id)
            }
            .onMove { indices, newOffset in
                store.move(from: indices, to: newOffset)
                onChange()
            }
            .onDelete { indexSet in
                for index in indexSet {
                    store.delete(id: store.items[index].id)
                }
                onChange()
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
        .frame(minHeight: 180)
        .onDeleteCommand { deleteSelection() }
    }

    private func itemRow(_ item: WedgeItem) -> some View {
        TextField(
            "Item",
            text: Binding(
                get: { item.text },
                set: { newValue in
                    do {
                        try store.update(id: item.id, text: newValue)
                        onChange()
                    } catch {
                        NSSound.beep()
                    }
                }
            )
        )
        .textFieldStyle(.plain)
        .font(item.id == store.oneThing?.id ? .body.weight(.semibold) : .body)
    }

    private var addField: some View {
        TextField(addPlaceholder, text: $draft)
            .textFieldStyle(.roundedBorder)
            .onSubmit { submitDraft() }
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
