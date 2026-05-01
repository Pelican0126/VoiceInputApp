import XCTest
@testable import SharedKit

final class SharedStoreTests: XCTestCase {
    private let testGroup = "group.com.example.voiceinput.tests"

    override func setUp() {
        super.setUp()
        UserDefaults(suiteName: testGroup)?.removePersistentDomain(forName: testGroup)
    }

    func testWriteAndConsumeResult() throws {
        let store = SharedStore(appGroupID: testGroup)
        let result = TranscriptionResult(
            rawText: "原始",
            finalText: "最终",
            promptID: "general",
            asrProviderID: "qwen3-asr-flash",
            llmProviderID: "mimo-v2.5",
            durationMS: 1234
        )
        try store.writeResult(result, sessionID: "S1")

        XCTAssertNil(store.consumeResult(sessionID: "S2"))
        let consumed = store.consumeResult(sessionID: "S1")
        XCTAssertEqual(consumed?.finalText, "最终")
        XCTAssertNil(store.consumeResult(sessionID: "S1"))
    }

    func testClearPending() {
        let store = SharedStore(appGroupID: testGroup)
        store.setString("S1", for: .pendingSession)
        store.setString("ctx", for: .pendingContextBefore)
        store.clearPending()
        XCTAssertNil(store.string(for: .pendingSession))
        XCTAssertNil(store.string(for: .pendingContextBefore))
    }
}
