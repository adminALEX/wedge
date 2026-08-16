import Foundation

struct WedgeItem: Identifiable, Equatable, Codable, Sendable {
    let id: UUID
    var text: String

    init(id: UUID = UUID(), text: String) {
        self.id = id
        self.text = text
    }
}
