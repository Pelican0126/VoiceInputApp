import Foundation

public protocol LLMProvider: Sendable {
    var id: String { get }
    var displayName: String { get }

    func process(
        rawText: String,
        prompt: PromptTemplate,
        context: TextContext,
        config: ProviderConfig,
        apiKey: String
    ) async throws -> AsyncThrowingStream<String, Error>
}

public enum LLMError: Error, LocalizedError {
    case invalidResponse
    case http(status: Int, body: String)
    case missingAPIKey
    case streamDecodeFailed

    public var errorDescription: String? {
        switch self {
        case .invalidResponse: return "LLM 返回格式异常"
        case .http(let s, let b): return "LLM HTTP \(s): \(b)"
        case .missingAPIKey: return "未配置 API Key"
        case .streamDecodeFailed: return "SSE 流解析失败"
        }
    }
}
