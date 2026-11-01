import AVFoundation
import Foundation

enum CustomSoundError: Error, Equatable {
    case unsupportedType
    case unreadable
    case tooLong
}

/// Holds the single user-chosen Done sound as `custom-done-<UUID>.<ext>` in `directory`. Every
/// install gets a new name, so choosing another file always changes the setting, and the player
/// reloads even when the new file has the same extension as the old one.
struct CustomSoundStore {
    static let maxDuration: TimeInterval = 3
    static let allowedExtensions: Set<String> = ["aiff", "aif", "wav", "mp3", "m4a", "caf"]
    private static let baseName = "custom-done"

    let directory: URL

    /// Validates `source`, copies it in under a new name, then removes any previous custom file
    /// (the chosen file may be the current custom file itself). Returns the new file name.
    func install(from source: URL) async throws -> String {
        let ext = source.pathExtension.lowercased()
        guard Self.allowedExtensions.contains(ext) else { throw CustomSoundError.unsupportedType }
        try await Self.validateDuration(of: source)

        let fileManager = FileManager.default
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let name = "\(Self.baseName)-\(UUID().uuidString).\(ext)"
        let destination = directory.appending(path: name)
        do {
            try fileManager.copyItem(at: source, to: destination)
        } catch {
            try? fileManager.removeItem(at: destination)
            throw error
        }
        removeCustomFiles(except: name)
        return name
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

    /// Best effort: a file left behind is harmless and goes on the next install.
    private func removeCustomFiles(except keep: String) {
        let fileManager = FileManager.default
        let existing = (try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        for url in existing where url.lastPathComponent.hasPrefix(Self.baseName) && url.lastPathComponent != keep {
            try? fileManager.removeItem(at: url)
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
