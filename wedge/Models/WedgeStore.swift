import Foundation
import Observation
import SwiftUI

enum WedgeStoreError: Error, Equatable {
    case emptyText
    case textTooLong(max: Int)
}

@Observable
final class WedgeStore {
    static let maxTextLength = 40

    private(set) var items: [WedgeItem]

    var oneThing: WedgeItem? { items.first }

    init(items: [WedgeItem] = []) {
        self.items = items
    }

    func replaceAll(_ items: [WedgeItem]) {
        self.items = items
    }

    @discardableResult
    func add(_ rawText: String) throws -> WedgeItem {
        let text = try Self.validatedText(rawText)
        let item = WedgeItem(text: text)
        items.append(item)
        return item
    }

    func update(id: UUID, text rawText: String) throws {
        let text = try Self.validatedText(rawText)
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].text = text
    }

    func delete(id: UUID) {
        items.removeAll { $0.id == id }
    }

    func move(from offsets: IndexSet, to offset: Int) {
        items.move(fromOffsets: offsets, toOffset: offset)
    }

    @discardableResult
    func completeOneThing() -> WedgeItem? {
        guard !items.isEmpty else { return nil }
        return items.removeFirst()
    }

    private static func validatedText(_ rawText: String) throws -> String {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw WedgeStoreError.emptyText }
        guard text.count <= maxTextLength else {
            throw WedgeStoreError.textTooLong(max: maxTextLength)
        }
        return text
    }
}
