import SwiftUI

/// The Now row: a ring that marks it Done, then its title, semibold and larger than other rows.
struct NowHeader<Title: View>: View {
    let item: WedgeItem
    let doneAction: DoneAction
    @ViewBuilder let title: Title

    var body: some View {
        HStack(spacing: 6) {
            Button {
                doneAction.perform()
            } label: {
                Image(systemName: "circle")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                    .contentShape(.circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(WedgeCopy.doneAccessibility(item.text))

            title
        }
    }
}
