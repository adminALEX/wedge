import Foundation

/// One row of the panel's list: an item (Now first, then Up Next), the item just marked Done
/// while it pops out of the Now slot, or the Up Next label.
enum PanelRow: Identifiable, Equatable {
    /// `position` is 1-based: Now is 1, the first Up Next row is 2.
    case item(WedgeItem, position: Int)
    /// The completed Now item, kept in the Now slot for the Done moment (spec §3.2).
    case completing(DoneEvent)
    case upNextLabel

    enum ID: Hashable {
        case item(UUID)
        case upNextLabel
    }

    /// A completing row keeps its item's identity, so it changes in place and then leaves,
    /// letting the next row rise into its slot.
    var id: ID {
        switch self {
        case .item(let item, _): .item(item.id)
        case .completing(let event): .item(event.completed.id)
        case .upNextLabel: .upNextLabel
        }
    }
}

/// The list's display rows, `[now, upNextLabel, up1, up2, …]`, and the mapping from
/// display offsets (what `.onMove` reports) to store offsets.
enum PanelRows {
    /// The label row's display index; present only when Up Next is non-empty.
    static let labelIndex = 1

    /// With `completing`, its item holds the Now slot and the store's items keep the places
    /// they had before Done (numbered from 2) until it leaves.
    static func rows(for items: [WedgeItem], completing: DoneEvent? = nil) -> [PanelRow] {
        let first = completing == nil ? 1 : 2
        var rows = items.enumerated().map { PanelRow.item($0.element, position: $0.offset + first) }
        if let completing { rows.insert(.completing(completing), at: 0) }
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

    /// The selection after the items changed: kept while its item exists, otherwise moved to
    /// the Now row (nil when the list is empty), so ↩ and ⌫ keep working after Done.
    static func retargetedSelection(_ selection: UUID?, in items: [WedgeItem]) -> UUID? {
        guard let selection, !items.contains(where: { $0.id == selection }) else { return selection }
        return items.first?.id
    }
}
