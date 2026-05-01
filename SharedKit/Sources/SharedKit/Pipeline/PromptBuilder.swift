import Foundation

public enum PromptBuilder {
    public static func render(
        template: String,
        rawText: String,
        context: TextContext
    ) -> String {
        var out = template
        let pairs: [(String, String)] = [
            ("{{raw_text}}", rawText),
            ("{{context_before}}", context.beforeCursor),
            ("{{context_after}}", context.afterCursor),
            ("{{host_bundle_id}}", context.hostBundleID ?? ""),
        ]
        for (key, value) in pairs {
            out = out.replacingOccurrences(of: key, with: value)
        }
        return out
    }
}
