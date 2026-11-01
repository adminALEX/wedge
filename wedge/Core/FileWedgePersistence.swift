import Foundation

/// Stores items as `{"version":1,"items":[…]}` in `<directory>/wedge.json`.
final class FileWedgePersistence: WedgePersisting {
    private static let currentVersion = 1

    private struct Header: Decodable {
        let version: Int
    }

    private struct Envelope: Codable {
        let version: Int
        let items: [WedgeItem]
    }

    private let directory: URL

    init(directory: URL) {
        self.directory = directory
    }

    var fileURL: URL {
        directory.appending(path: "wedge.json", directoryHint: .notDirectory)
    }

    /// `Application Support/Wedge` (inside the container when sandboxed).
    static func defaultDirectory() -> URL {
        URL.applicationSupportDirectory.appending(path: "Wedge", directoryHint: .isDirectory)
    }

    func load() throws -> [WedgeItem] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()

        let header: Header
        do {
            header = try decoder.decode(Header.self, from: data)
        } catch {
            throw try backUpCorruptFile(underlying: error)
        }
        guard header.version == Self.currentVersion else {
            throw WedgePersistenceError.unsupportedVersion(header.version)
        }
        do {
            return try decoder.decode(Envelope.self, from: data).items
        } catch {
            throw try backUpCorruptFile(underlying: error)
        }
    }

    func save(_ items: [WedgeItem]) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(Envelope(version: Self.currentVersion, items: items))
        try data.write(to: fileURL, options: .atomic)
    }

    /// Moves the unreadable file aside so the next save cannot overwrite it.
    private func backUpCorruptFile(underlying: Error) throws -> WedgePersistenceError {
        Log.store.error("wedge.json is unreadable: \(String(describing: underlying), privacy: .public)")
        let backup = uniqueBackupURL()
        try FileManager.default.moveItem(at: fileURL, to: backup)
        return .corrupt(backup: backup)
    }

    private func uniqueBackupURL() -> URL {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let stamp = formatter.string(from: Date())

        var candidate = directory.appending(path: "wedge.corrupt-\(stamp).json", directoryHint: .notDirectory)
        var suffix = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = directory.appending(path: "wedge.corrupt-\(stamp)-\(suffix).json", directoryHint: .notDirectory)
            suffix += 1
        }
        return candidate
    }
}
