import XCTest
@testable import SharedKit

final class PromptBuilderTests: XCTestCase {
    func testRendersAllPlaceholders() {
        let template = "前文：{{context_before}}\n原文：{{raw_text}}\n后文：{{context_after}}\nApp：{{host_bundle_id}}"
        let ctx = TextContext(beforeCursor: "你好", afterCursor: "再见", hostBundleID: "com.x")
        let out = PromptBuilder.render(template: template, rawText: "嗯今天天气不错", context: ctx)
        XCTAssertEqual(out, "前文：你好\n原文：嗯今天天气不错\n后文：再见\nApp：com.x")
    }

    func testEmptyContext() {
        let out = PromptBuilder.render(
            template: "[{{context_before}}][{{raw_text}}][{{host_bundle_id}}]",
            rawText: "X",
            context: .empty
        )
        XCTAssertEqual(out, "[][X][]")
    }

    func testRepeatedPlaceholder() {
        let out = PromptBuilder.render(
            template: "{{raw_text}} -- {{raw_text}}",
            rawText: "ABC",
            context: .empty
        )
        XCTAssertEqual(out, "ABC -- ABC")
    }
}
