import Foundation
import Testing

@testable import wedge

@Suite("CustomSoundStore")
@MainActor
struct CustomSoundStoreTests {
    private func makeTempDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("wedge-sound-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func customFiles(in directory: URL) throws -> [String] {
        try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .map(\.lastPathComponent)
            .sorted()
    }

    @Test("install copies the file and url(for:) finds it; remove deletes it")
    func installAndRemove() async throws {
        let tmp = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tmp) }
        let source = tmp.appendingPathComponent("sample.wav")
        try TestAudioFixtures.writeSilenceWAV(to: source, seconds: 0.25)
        let store = CustomSoundStore(directory: tmp.appendingPathComponent("Support", isDirectory: true))

        let name = try await store.install(from: source)
        #expect(name == "custom-done.wav")
        #expect(store.url(for: name) != nil)

        store.remove(fileName: name)
        #expect(store.url(for: name) == nil)
    }

    @Test("accepts a sound of exactly three seconds")
    func acceptsExactlyThreeSeconds() async throws {
        let tmp = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tmp) }
        let source = tmp.appendingPathComponent("exact.wav")
        try TestAudioFixtures.writeSilenceWAV(to: source, seconds: 3.0)
        let store = CustomSoundStore(directory: tmp.appendingPathComponent("Support", isDirectory: true))

        #expect(try await store.install(from: source) == "custom-done.wav")
    }

    @Test("rejects a sound longer than three seconds and installs nothing")
    func rejectsTooLong() async throws {
        let tmp = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tmp) }
        let source = tmp.appendingPathComponent("long.wav")
        try TestAudioFixtures.writeSilenceWAV(to: source, seconds: 3.1)
        let support = tmp.appendingPathComponent("Support", isDirectory: true)
        let store = CustomSoundStore(directory: support)

        await #expect(throws: CustomSoundError.tooLong) {
            _ = try await store.install(from: source)
        }
        #expect(!FileManager.default.fileExists(atPath: support.path))
    }

    @Test("rejects an unsupported file type")
    func rejectsUnsupportedType() async throws {
        let tmp = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tmp) }
        let source = tmp.appendingPathComponent("notes.txt")
        try Data("hello".utf8).write(to: source)
        let store = CustomSoundStore(directory: tmp.appendingPathComponent("Support", isDirectory: true))

        await #expect(throws: CustomSoundError.unsupportedType) {
            _ = try await store.install(from: source)
        }
    }

    @Test("rejects an unreadable audio payload")
    func rejectsUnreadable() async throws {
        let tmp = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tmp) }
        let source = tmp.appendingPathComponent("fake.wav")
        try Data([0, 1, 2, 3]).write(to: source)
        let store = CustomSoundStore(directory: tmp.appendingPathComponent("Support", isDirectory: true))

        await #expect(throws: CustomSoundError.unreadable) {
            _ = try await store.install(from: source)
        }
    }

    @Test("install replaces the previous custom file, even one of another type")
    func installReplacesPrevious() async throws {
        let tmp = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tmp) }
        let support = tmp.appendingPathComponent("Support", isDirectory: true)
        try FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        try Data([1]).write(to: support.appendingPathComponent("custom-done.mp3"))
        let first = tmp.appendingPathComponent("first.wav")
        let second = tmp.appendingPathComponent("second.wav")
        try TestAudioFixtures.writeSilenceWAV(to: first, seconds: 0.2)
        try TestAudioFixtures.writeSilenceWAV(to: second, seconds: 0.4)
        let store = CustomSoundStore(directory: support)

        _ = try await store.install(from: first)
        _ = try await store.install(from: second)

        #expect(try customFiles(in: support) == ["custom-done.wav"])
    }

    @Test("reinstalling the current custom file keeps it")
    func reinstallCurrentFile() async throws {
        let tmp = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tmp) }
        let source = tmp.appendingPathComponent("sample.wav")
        try TestAudioFixtures.writeSilenceWAV(to: source, seconds: 0.2)
        let support = tmp.appendingPathComponent("Support", isDirectory: true)
        let store = CustomSoundStore(directory: support)

        let name = try await store.install(from: source)
        let again = try await store.install(from: try #require(store.url(for: name)))

        #expect(again == name)
        #expect(try customFiles(in: support) == ["custom-done.wav"])
    }

    @Test("url(for:) is nil for nil, blank, and missing names")
    func urlIsNilWhenAbsent() throws {
        let tmp = try makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tmp) }
        let store = CustomSoundStore(directory: tmp)

        #expect(store.url(for: nil) == nil)
        #expect(store.url(for: "   ") == nil)
        #expect(store.url(for: "custom-done.wav") == nil)
    }
}
