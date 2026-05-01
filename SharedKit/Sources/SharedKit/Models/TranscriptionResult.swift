import Foundation

public struct ASRChunk: Codable, Hashable, Sendable {
    public let text: String
    public let isFinal: Bool

    public init(text: String, isFinal: Bool) {
        self.text = text
        self.isFinal = isFinal
    }
}

public struct TextContext: Codable, Hashable, Sendable {
    public let beforeCursor: String
    public let afterCursor: String
    public let hostBundleID: String?

    public init(beforeCursor: String, afterCursor: String, hostBundleID: String?) {
        self.beforeCursor = beforeCursor
        self.afterCursor = afterCursor
        self.hostBundleID = hostBundleID
    }

    public static let empty = TextContext(beforeCursor: "", afterCursor: "", hostBundleID: nil)
}

public struct TranscriptionResult: Codable, Hashable, Identifiable, Sendable {
    public let id: UUID
    public let createdAt: Date
    public let rawText: String
    public let finalText: String
    public let promptID: String
    public let asrProviderID: String
    public let llmProviderID: String?
    public let durationMS: Int

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        rawText: String,
        finalText: String,
        promptID: String,
        asrProviderID: String,
        llmProviderID: String?,
        durationMS: Int
    ) {
        self.id = id
        self.createdAt = createdAt
        self.rawText = rawText
        self.finalText = finalText
        self.promptID = promptID
        self.asrProviderID = asrProviderID
        self.llmProviderID = llmProviderID
        self.durationMS = durationMS
    }
}
