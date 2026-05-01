import Foundation

public protocol ASRProvider: Sendable {
    var id: String { get }
    var displayName: String { get }
    var supportsStreaming: Bool { get }

    func transcribe(
        audio: Data,
        config: ProviderConfig,
        apiKey: String,
        hotwords: [String]
    ) async throws -> AsyncThrowingStream<ASRChunk, Error>
}

public enum ASRError: Error, LocalizedError {
    case invalidResponse
    case http(status: Int, body: String)
    case audioTooLarge(bytes: Int)
    case missingAPIKey

    public var errorDescription: String? {
        switch self {
        case .invalidResponse: return "ASR 返回格式异常"
        case .http(let status, let body): return "ASR HTTP \(status): \(body)"
        case .audioTooLarge(let n): return "音频过大 (\(n) 字节)，请缩短录音"
        case .missingAPIKey: return "未配置 API Key"
        }
    }
}
