import Foundation

/// One row of the panel's list: an item (Now first, then Up Next) or the Up Next label.
enum PanelRow: Identifiable, Equatable {
    /// `position` is 1-based: Now is 1, the first Up Next row is 2.
    case item(WedgeItem, position: Int)
    case upNextLabel

    enum ID: Hashable {
        case item(UUID)
        case upNextLabel
    }

    var id: ID {
        switch self {
        case .item(let item, _): .item(item.id)
        case .upNextLabel: .upNextLabel
        }
    }
}

/// The list's display rows, `[now, upNextLabel, up1, up2, …]`, and the mapping from
/// display offsets (what `.onMove` reports) to store offsets.
enum PanelRows {
    /// The label row's display index; present only when Up Next is non-empty.
    static let labelIndex = 1

    static func rows(for items: [WedgeItem]) -> [PanelRow] {
        var rows = items.enumerated().map { PanelRow.item($0.element, position: $0.offset + 1) }
        if rows.count > 1 { rows.insert(.upNextLabel, at: labelIndex) }
        return rows
    }

    /// Display move → store move. The label row is never a source. A destination at the label
    /// (just below Now) or just below it is store offset 1; destination 0 makes the row Now.
    static func storeMove(from offsets: IndexSet, to destination: Int) -> (offsets: IndexSet, destination: Int) {
        let source = offsets.filter { $0 != labelIndex }.map { $0 < labelIndex ? $0 : $0 - 1 }
        let target = destination <= labelIndex ? destination : destination - 1
        return (IndexSet(source), target)
    }
}
