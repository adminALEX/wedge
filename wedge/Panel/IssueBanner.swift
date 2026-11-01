import SwiftUI

/// The store's save/load problem, shown at the top of the panel until the store clears it.
struct IssueBanner: View {
    let issue: StoreIssue

    var body: some View {
        Label(Self.message(for: issue), systemImage: "exclamationmark.triangle.fill")
            .font(.callout)
            .symbolRenderingMode(.multicolor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(.quaternary, in: .rect(cornerRadius: 8))
    }

    static func message(for issue: StoreIssue) -> String {
        switch issue {
        case .saveFailed: WedgeCopy.saveFailed
        case .recoveredFromCorruptFile: WedgeCopy.recoveredFromCorruptFile
        case .loadFailed: WedgeCopy.loadFailed
        }
    }
}
