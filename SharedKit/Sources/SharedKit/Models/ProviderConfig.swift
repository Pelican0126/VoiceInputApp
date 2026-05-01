import Foundation

public struct ProviderConfig: Codable, Hashable, Sendable {
    public var id: String
    public var displayName: String
    public var baseURL: URL
    public var model: String
    public var apiKeyRef: String
    public var extra: [String: String]

    public init(
        id: String,
        displayName: String,
        baseURL: URL,
        model: String,
        apiKeyRef: String,
        extra: [String: String] = [:]
    ) {
        self.id = id
        self.displayName = displayName
        self.baseURL = baseURL
        self.model = model
        self.apiKeyRef = apiKeyRef
        self.extra = extra
    }
}

public extension ProviderConfig {
    static let defaultQwenASR = ProviderConfig(
        id: "qwen3-asr-flash",
        displayName: "Qwen3-ASR-Flash",
        baseURL: URL(string: "https://dashscope.aliyuncs.com/compatible-mode/v1")!,
        model: "qwen3-asr-flash",
        apiKeyRef: "qwen.dashscope.apiKey"
    )

    static let defaultMiMoLLM = ProviderConfig(
        id: "mimo-v2.5",
        displayName: "MiMo-V2.5",
        baseURL: URL(string: "https://api.xiaomimimo.com/v1")!,
        model: "mimo-v2.5",
        apiKeyRef: "mimo.apiKey"
    )
}
