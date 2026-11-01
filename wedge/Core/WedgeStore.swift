import Foundation
import Observation
import SwiftUI

enum StoreIssue: Equatable {
    case saveFailed
    case recoveredFromCorruptFile
}

enum WedgeStoreError: Error, Equatable {
    case emptyText
    case textTooLong(max: Int)
}

/// The ordered list of work items: the first is "now", the rest are "up next".
/// Every mutation saves through the persister; failures surface as `issue`.
@Observable
final class WedgeStore {
    static let maxTextLength = 40

    private(set) var items: [WedgeItem]
    private(set) var issue: StoreIssue?

    @ObservationIgnored private let persister: any WedgePersisting
    /// The item removed by the last `completeNow`; any other mutation clears it.
    private var lastDone: WedgeItem?

    var now: WedgeItem? { items.first }
    var upNext: ArraySlice<WedgeItem> { items.dropFirst() }
    var canUndoDone: Bool { lastDone != nil }

    init(persister: any WedgePersisting) {
        self.persister = persister
        do {
            items = try persister.load()
        } catch WedgePersistenceError.corrupt(let backup) {
            Log.store.error("Recovered from corrupt file; backup at \(backup.lastPathComponent, privacy: .public)")
            items = []
            issue = .recoveredFromCorruptFile
        } catch {
            Log.store.error("Could not load items: \(String(describing: error), privacy: .public)")
            items = []
        }
    }

    @discardableResult
    func add(_ text: String) throws -> WedgeItem {
        let normalizedText = try Self.normalized(text)
        let item = WedgeItem(text: normalizedText)
        items.append(item)
        commit()
        return item
    }

    func update(id: UUID, text: String) throws {
        let text = try Self.normalized(text)
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].text = text
        commit()
    }

    func delete(id: UUID) {
        guard items.contains(where: { $0.id == id }) else { return }
        items.removeAll { $0.id == id }
        commit()
    }

    func move(fromOffsets offsets: IndexSet, toOffset offset: Int) {
        items.move(fromOffsets: offsets, toOffset: offset)
        commit()
    }

    /// Moves the item one step (or more) up (negative) or down (positive), clamped to the list ends.
    func move(id: UUID, by delta: Int) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        let target = min(max(index + delta, 0), items.count - 1)
        guard target != index else { return }
        let item = items.remove(at: index)
        items.insert(item, at: target)
        commit()
    }

    @discardableResult
    func completeNow() -> WedgeItem? {
        guard !items.isEmpty else { return nil }
        let done = items.removeFirst()
        commit(keepingUndo: true)
        lastDone = done
        return done
    }

    @discardableResult
    func undoDone() -> Bool {
        guard let item = lastDone else { return false }
        items.insert(item, at: 0)
        commit()
        return true
    }

    /// Collapses newline/tab runs to one space, trims, then enforces 1...40 characters.
    static func normalized(_ text: String) throws -> String {
        let collapsed = text
            .split(whereSeparator: { $0.isNewline || $0 == "\t" })
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !collapsed.isEmpty else { throw WedgeStoreError.emptyText }
        guard collapsed.count <= maxTextLength else {
            throw WedgeStoreError.textTooLong(max: maxTextLength)
        }
        return collapsed
    }

    /// Saves after a mutation and updates `issue`. Clears the Done undo slot unless told otherwise.
    private func commit(keepingUndo: Bool = false) {
        if !keepingUndo { lastDone = nil }
        do {
            try persister.save(items)
            if issue == .saveFailed { issue = nil }
        } catch {
            Log.store.error("Save failed: \(String(describing: error), privacy: .public)")
            issue = .saveFailed
        }
    }
}
