import SwiftUI

/// Adds to the bottom of the list. Shows the n/40 counter from 30 characters and inline errors.
struct AddField: View {
    let store: WedgeStore
    @Binding var draft: String
    var focus: FocusState<PanelFocus?>.Binding
    /// ↑ from this field: select the last Up Next row.
    let onMoveUp: () -> Void
    /// Esc from this field.
    let onClose: () -> Void

    @State private var refused = false
    /// Why the last submit was rejected; cleared by the next change to the draft.
    @State private var submitError: String?

    private var message: String? { refused ? WedgeCopy.maxCharacters : submitError }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                TextField(
                    store.items.isEmpty ? WedgeCopy.addNowPlaceholder : WedgeCopy.addUpNextPlaceholder,
                    text: $draft
                )
                .textFieldStyle(.plain)
                .focused(focus, equals: .add)
                .inputLimit($draft, refused: $refused)
                .onSubmit { submit() }
                .onKeyPress(.upArrow) {
                    onMoveUp()
                    return .handled
                }
                .onKeyPress(.escape) {
                    onClose()
                    return .handled
                }

                if let counter = InputLimit.counter(for: draft) {
                    Text(counter)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(.quaternary, in: .rect(cornerRadius: 8))

            if let message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .onChange(of: draft) { submitError = nil }
    }

    private func submit() {
        guard !draft.isEmpty else { return }
        do {
            try store.add(draft)
            draft = ""
        } catch {
            submitError = WedgeCopy.message(for: error)
        }
        focus.wrappedValue = .add
    }
}
