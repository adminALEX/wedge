import SwiftUI

/// A row's title: text that edits in place when clicked. While editing, ↩ commits, Esc cancels
/// (consumed here, so it never closes the panel), and the field leaving the screen commits.
/// An inline message (limit or rejected edit) shows underneath.
struct EditableTitle: View {
    private static let cornerRadius: CGFloat = 5

    let item: WedgeItem
    let font: Font
    let isEditing: Bool
    @Binding var text: String
    @Binding var refused: Bool
    let message: String?
    var focus: FocusState<PanelFocus?>.Binding
    /// VoiceOver label for the title when not editing; the item's text when nil.
    var titleAccessibilityLabel: String?
    let onStart: () -> Void
    let onCommit: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if isEditing {
                field
            } else {
                Text(item.text)
                    .font(font)
                    .lineLimit(1)
                    .padding(.horizontal, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(.rect)
                    .onTapGesture(perform: onStart)
                    .accessibilityLabel(titleAccessibilityLabel ?? item.text)
            }
            if let message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 4)
            }
        }
    }

    private var field: some View {
        TextField(item.text, text: $text)
            .textFieldStyle(.plain)
            .font(font)
            // Fixed colours: the row may be drawn selected, which would flip `.primary` to white.
            .foregroundStyle(Color(nsColor: .textColor))
            .focused(focus, equals: .row(item.id))
            .inputLimit($text, refused: $refused)
            .onSubmit { onCommit() }
            .onKeyPress(.escape) {
                onCancel()
                return .handled
            }
            .onExitCommand { onCancel() }
            .onAppear { focus.wrappedValue = .row(item.id) }
            .onDisappear { onCommit() }  // the row was deleted, completed or the list went away
            .padding(.horizontal, 4)
            .background(Color(nsColor: .textBackgroundColor), in: .rect(cornerRadius: Self.cornerRadius))
            .focusIndicator(focus.wrappedValue == .row(item.id), cornerRadius: Self.cornerRadius)
    }
}
