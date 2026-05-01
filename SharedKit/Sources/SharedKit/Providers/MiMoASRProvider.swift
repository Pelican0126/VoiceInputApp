import Foundation

public struct MiMoASRProvider: ASRProvider {
    public let id = "mimo-asr"
    public let displayName = "MiMo-V2.5-ASR"
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

        var body = Data()
        let nl = "\r\n"
        body.append("--\(boundary)\(nl)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\(nl)\(nl)\(config.model)\(nl)".data(using: .utf8)!)
        body.append("--\(boundary)\(nl)".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\(nl)".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\(nl)\(nl)".data(using: .utf8)!)
        body.append(audio)
        body.append(nl.data(using: .utf8)!)
        body.append("--\(boundary)--\(nl)".data(using: .utf8)!)
        request.httpBody = body

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let (data, response) = try await session.data(for: request)
                    guard let http = response as? HTTPURLResponse else {
                        throw ASRError.invalidResponse
                    }
                    guard (200...299).contains(http.statusCode) else {
                        let bodyStr = String(data: data, encoding: .utf8) ?? ""
                        throw ASRError.http(status: http.statusCode, body: bodyStr)
                    }
                    struct Resp: Decodable { let text: String? }
                    let r = try JSONDecoder().decode(Resp.self, from: data)
                    guard let text = r.text else { throw ASRError.invalidResponse }
                    continuation.yield(ASRChunk(text: text, isFinal: true))
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
