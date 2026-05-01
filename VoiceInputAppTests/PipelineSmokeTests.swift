import XCTest
@testable import SharedKit

final class PipelineSmokeTests: XCTestCase {
    func testRegistryHasDefaults() {
        let registry = ProviderRegistry.shared
        XCTAssertNotNil(registry.asr("qwen3-asr-flash"))
        XCTAssertNotNil(registry.llm("mimo-v2.5"))
    }

    func testWAVEncoderProducesValidHeader() {
        let samples: [Float] = Array(repeating: 0, count: 16_000)
        let wav = WAVEncoder.encode(samples: samples)
        XCTAssertGreaterThan(wav.count, 44)
        let riff = wav.prefix(4)
        XCTAssertEqual(String(data: riff, encoding: .ascii), "RIFF")
    }
}
