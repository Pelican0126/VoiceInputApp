import Foundation

public struct OpenAICompatLLMProvider: LLMProvider {
    public let id: String
    public let displayName: String
    public let disableThinking: Bool

    private let session: URLSession

    public init(
        id: String = "openai-compat",
        displayName: String = "OpenAI Compatible",
        disableThinking: Bool = false,
        session: URLSession = .shared
    ) {
        self.id = id
        self.displayName = displayName
        self.disableThinking = disableThinking
        self.session = session
    }

    public static let mimo = OpenAICompatLLMProvider(
        id: "mimo-v2.5",
        displayName: "MiMo-V2.5",
        disableThinking: true
    )

    public func process(
        rawText: String,
        prompt: PromptTemplate,
        context: TextContext,
        config: ProviderConfig,
        apiKey: String
    ) async throws -> AsyncThrowingStream<String, Error> {
        guard !apiKey.isEmpty else { throw LLMError.missingAPIKey }

        let userMessage = PromptBuilder.render(
            template: prompt.userTemplate,
            rawText: rawText,
            context: context
        )

        let endpoint = config.baseURL.appendingPathComponent("chat/completions")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")

        var payload: [String: Any] = [
            "model": config.model,
            "messages": [
                ["role": "system", "content": prompt.system],
                ["role": "user", "content": userMessage],
            ],
            "stream": true,
            "temperature": 0.3,
        ]
        if disableThinking {
            payload["extra_body"] = ["thinking": ["type": "disabled"]]
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let (bytes, response) = try await session.bytes(for: request)
                    guard let http = response as? HTTPURLResponse else {
                        throw LLMError.invalidResponse
                    }
                    guard (200...299).contains(http.statusCode) else {
                        var body = ""
                        for try await line in bytes.lines { body += line + "\n" }
                        throw LLMError.http(status: http.statusCode, body: body)
                    }
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let payload = String(line.dropFirst(6))
                        if payload == "[DONE]" { break }
                        guard let data = payload.data(using: .utf8) else { continue }
                        if let delta = Self.extractDelta(from: data) {
                            continuation.yield(delta)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private static func extractDelta(from data: Data) -> String? {
        struct Chunk: Decodable {
            struct Choice: Decodable {
                struct Delta: Decodable { let content: String? }
                let delta: Delta?
            }
            let choices: [Choice]?
        }
        guard let c = try? JSONDecoder().decode(Chunk.self, from: data) else { return nil }
        return c.choices?.first?.delta?.content
    }
}
