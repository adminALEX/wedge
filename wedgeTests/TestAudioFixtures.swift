import Foundation

enum TestAudioFixtures {
    /// Minimal mono 16-bit PCM WAV (silence) for duration / install tests.
    static func writeSilenceWAV(to url: URL, seconds: Double, sampleRate: Int = 8_000) throws {
        let frameCount = max(1, Int((Double(sampleRate) * seconds).rounded()))
        let dataSize = frameCount * 2
        var data = Data()
        data.reserveCapacity(44 + dataSize)

        func appendASCII(_ s: String) {
            data.append(contentsOf: s.utf8)
        }
        func appendUInt16(_ v: UInt16) {
            var le = v.littleEndian
            withUnsafeBytes(of: &le) { data.append(contentsOf: $0) }
        }
        func appendUInt32(_ v: UInt32) {
            var le = v.littleEndian
            withUnsafeBytes(of: &le) { data.append(contentsOf: $0) }
        }

        appendASCII("RIFF")
        appendUInt32(UInt32(36 + dataSize))
        appendASCII("WAVE")
        appendASCII("fmt ")
        appendUInt32(16)
        appendUInt16(1) // PCM
        appendUInt16(1) // mono
        appendUInt32(UInt32(sampleRate))
        appendUInt32(UInt32(sampleRate * 2))
        appendUInt16(2) // block align
        appendUInt16(16) // bits
        appendASCII("data")
        appendUInt32(UInt32(dataSize))
        data.append(Data(count: dataSize))
        try data.write(to: url)
    }
}
