import Foundation
import SwiftData

@Model
final class HistoryEntry {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var rawText: String
    var finalText: String
    var promptID: String
    var asrProviderID: String
    var llmProviderID: String?
    var durationMS: Int

    init(
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
