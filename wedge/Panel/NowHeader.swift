import SwiftUI

/// The Now item: a ring that marks it Done, then its title, semibold and larger than rows.
struct NowHeader: View {
    let item: WedgeItem
    let doneAction: DoneAction

    var body: some View {
        HStack(spacing: 10) {
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

            Text(item.text)
                .font(.title3.weight(.semibold))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel(WedgeCopy.nowAccessibility(item.text))
        }
    }
}
