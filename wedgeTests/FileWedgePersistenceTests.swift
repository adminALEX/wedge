import Foundation
import Testing

@testable import wedge

@Suite("FileWedgePersistence")
@MainActor
final class FileWedgePersistenceTests {
    let tmp: URL

    init() throws {
        tmp = FileManager.default.temporaryDirectory
            .appending(path: "wedge-tests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: tmp, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: tmp)
    }

    @Test func roundTrip() throws {
        let p = FileWedgePersistence(directory: tmp)
        let items = [WedgeItem(text: "A"), WedgeItem(text: "B")]
        try p.save(items)
        #expect(try FileWedgePersistence(directory: tmp).load() == items)
    }

    @Test func missingFileLoadsEmpty() throws {
        #expect(try FileWedgePersistence(directory: tmp).load().isEmpty)
    }

    @Test func saveCreatesMissingDirectory() throws {
        let dir = tmp.appending(path: "Wedge")
        try FileWedgePersistence(directory: dir).save([WedgeItem(text: "A")])
        #expect(FileManager.default.fileExists(atPath: dir.appending(path: "wedge.json").path))
    }

    @Test func fileURLIsWedgeJSONInDirectory() {
        #expect(FileWedgePersistence(directory: tmp).fileURL.lastPathComponent == "wedge.json")
        #expect(FileWedgePersistence(directory: tmp).fileURL.deletingLastPathComponent().path == tmp.path)
    }

    @Test func writesVersionOne() throws {
        let p = FileWedgePersistence(directory: tmp)
        let item = WedgeItem(text: "A")
        try p.save([item])
        let raw = try JSONSerialization.jsonObject(with: Data(contentsOf: p.fileURL))
        let json = try #require(raw as? [String: Any])
        #expect(json["version"] as? Int == 1)
        let items = try #require(json["items"] as? [[String: Any]])
        #expect(items.count == 1)
        #expect(items.first?["id"] as? String == item.id.uuidString)
        #expect(items.first?["text"] as? String == "A")
    }

    @Test func corruptFileIsBackedUp() throws {
        try Data("not json".utf8).write(to: tmp.appending(path: "wedge.json"))
        let error = #expect(throws: WedgePersistenceError.self) {
            try FileWedgePersistence(directory: tmp).load()
        }
        guard case .corrupt(let backup) = error else {
            Issue.record("expected .corrupt, got \(String(describing: error))")
            return
        }
        let names = try FileManager.default.contentsOfDirectory(atPath: tmp.path)
        #expect(names.contains { $0.hasPrefix("wedge.corrupt-") && $0.hasSuffix(".json") })
        #expect(names.contains(backup.lastPathComponent))
        #expect(!names.contains("wedge.json"))
    }

    @Test func unknownVersionThrows() throws {
        let file = tmp.appending(path: "wedge.json")
        try Data(#"{"version":2,"items":[]}"#.utf8).write(to: file)
        #expect(throws: WedgePersistenceError.unsupportedVersion(2)) {
            try FileWedgePersistence(directory: tmp).load()
        }
        #expect(FileManager.default.fileExists(atPath: file.path))
    }
}
