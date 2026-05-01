import Foundation

public struct QwenASRProvider: ASRProvider {
    public let id = "qwen3-asr-flash"
    public let displayName = "Qwen3-ASR-Flash"
    public let supportsStreaming = false

    private let session: URLSession
    private let maxBytes = 10 * 1024 * 1024

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func transcribe(
        audio: Data,
        config: ProviderConfig,
        apiKey: String,
        hotwords: [String]
    ) async throws -> AsyncThrowingStream<ASRChunk, Error> {
        guard !apiKey.isEmpty else { throw ASRError.missingAPIKey }
        guard audio.count <= maxBytes else { throw ASRError.audioTooLarge(bytes: audio.count) }

        let endpoint = config.baseURL.appendingPathComponent("audio/transcriptions")
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        request.httpBody = Self.makeMultipartBody(
            boundary: boundary,
            model: config.model,
            audio: audio,
            hotwords: hotwords
        )

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let (data, response) = try await session.data(for: request)
                    guard let http = response as? HTTPURLResponse else {
                        throw ASRError.invalidResponse
                    }
                    guard (200...299).contains(http.statusCode) else {
                        let body = String(data: data, encoding: .utf8) ?? ""
                        throw ASRError.http(status: http.statusCode, body: body)
                    }
                    let parsed = try Self.parseResponse(data)
                    continuation.yield(ASRChunk(text: parsed, isFinal: true))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    private static func makeMultipartBody(
        boundary: String,
        model: String,
        audio: Data,
        hotwords: [String]
    ) -> Data {
        var body = Data()
        let nl = "\r\n"
        func appendField(_ name: String, _ value: String) {
            body.append("--\(boundary)\(nl)".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\(nl)\(nl)".data(using: .utf8)!)
            body.append("\(value)\(nl)".data(using: .utf8)!)
        }
        appendField("model", model)
        if !hotwords.isEmpty {
            appendField("hotwords", hotwords.joined(separator: ","))
        }
        body.append("--\(boundary)\(nl)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\(nl)".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\(nl)\(nl)".data(using: .utf8)!)
        body.append(audio)
        body.append(nl.data(using: .utf8)!)
        body.append("--\(boundary)--\(nl)".data(using: .utf8)!)
        return body
    }

    private static func parseResponse(_ data: Data) throws -> String {
        struct Resp: Decodable { let text: String? }
        if let r = try? JSONDecoder().decode(Resp.self, from: data), let t = r.text {
            return t
        }
        struct DashResp: Decodable {
            struct Output: Decodable {
                struct Choice: Decodable {
                    struct Msg: Decodable { let content: String? }
                    let message: Msg?
                }
                let choices: [Choice]?
                let text: String?
            }
            let output: Output?
        }
        if let r = try? JSONDecoder().decode(DashResp.self, from: data) {
            if let t = r.output?.text { return t }
            if let t = r.output?.choices?.first?.message?.content { return t }
        }
        throw ASRError.invalidResponse
    }
}
