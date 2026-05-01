import Foundation

public struct PromptTemplate: Codable, Hashable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public var system: String
    public var userTemplate: String
    public var hotwords: [String]

    public init(
        id: String,
        name: String,
        system: String,
        userTemplate: String,
        hotwords: [String] = []
    ) {
        self.id = id
        self.name = name
        self.system = system
        self.userTemplate = userTemplate
        self.hotwords = hotwords
    }
}

public extension PromptTemplate {
    enum BuiltInID: String, CaseIterable, Sendable {
        case general
        case soeOfficial = "soe_official"
        case wechat
        case email
    }
}
