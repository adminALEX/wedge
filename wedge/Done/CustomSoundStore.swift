import AVFoundation
import Foundation

enum CustomSoundError: Error, Equatable {
    case unsupportedType
    case unreadable
    case tooLong
}

/// Holds the single user-chosen Done sound as `custom-done.<ext>` in `directory`.
struct CustomSoundStore {
    static let maxDuration: TimeInterval = 3
    static let allowedExtensions: Set<String> = ["aiff", "aif", "wav", "mp3", "m4a", "caf"]
    private static let baseName = "custom-done"

    let directory: URL

    /// Validates `source`, replaces any previous custom file, and returns the new file name.
    func install(from source: URL) async throws -> String {
        let ext = source.pathExtension.lowercased()
        guard Self.allowedExtensions.contains(ext) else { throw CustomSoundError.unsupportedType }
        try await Self.validateDuration(of: source)

        let fileManager = FileManager.default
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        // Stage first: the chosen file may be the current custom file itself.
        let staging = directory.appending(path: ".\(Self.baseName)-\(UUID().uuidString).\(ext)")
        try fileManager.copyItem(at: source, to: staging)
        do {
            try removeExistingCustomFiles()
            let name = "\(Self.baseName).\(ext)"
            try fileManager.moveItem(at: staging, to: directory.appending(path: name))
            return name
        } catch {
            try? fileManager.removeItem(at: staging)
            throw error
        }
    }

    func remove(fileName: String) {
        try? FileManager.default.removeItem(at: directory.appending(path: fileName))
    }

    /// The file's URL, or nil when `fileName` is nil, blank, or missing on disk.
    func url(for fileName: String?) -> URL? {
        guard let name = fileName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            return nil
        }
        let url = directory.appending(path: name)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    private func removeExistingCustomFiles() throws {
        let existing = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        for url in existing where url.lastPathComponent.hasPrefix("\(Self.baseName).") {
            try FileManager.default.removeItem(at: url)
        }
    }

    private static func validateDuration(of url: URL) async throws {
        let seconds: Double
        do {
            seconds = try await AVURLAsset(url: url).load(.duration).seconds
        } catch {
            throw CustomSoundError.unreadable
        }
        guard seconds.isFinite, seconds > 0 else { throw CustomSoundError.unreadable }
        guard seconds <= maxDuration else { throw CustomSoundError.tooLong }
    }
}
