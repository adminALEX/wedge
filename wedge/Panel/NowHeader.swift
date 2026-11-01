import SwiftUI

/// The Now row's layout, shared by `NowHeader` and `DonePopRow` so the Done moment lines up exactly.
enum NowRowStyle {
    static let spacing: CGFloat = 6
    static let ringFont: Font = .title2
    static let titleFont: Font = .title3.weight(.semibold)
    /// The title's horizontal text padding (every row's `EditableTitle` uses it).
    static let titlePadding: CGFloat = 4
}

/// The Now row: a ring that marks it Done, then its title, semibold and larger than other rows.
struct NowHeader<Title: View>: View {
    let item: WedgeItem
    let doneAction: DoneAction
    @ViewBuilder let title: Title

    var body: some View {
        HStack(spacing: NowRowStyle.spacing) {
            Button {
                doneAction.perform()
            } label: {
                Image(systemName: "circle")
                    .font(NowRowStyle.ringFont)
                    .foregroundStyle(.secondary)
                    .contentShape(.circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(WedgeCopy.doneAccessibility(item.text))

            title
        }
    }
}
