import Foundation

public actor TranscriptionPipeline {
    public struct Configuration: Sendable {
        public var asr: ProviderConfig
        public var llm: ProviderConfig?
        public var prompt: PromptTemplate
        public var asrAPIKey: String
        public var llmAPIKey: String?

        public init(
            asr: ProviderConfig,
            llm: ProviderConfig?,
            prompt: PromptTemplate,
            asrAPIKey: String,
            llmAPIKey: String?
        ) {
            self.asr = asr
            self.llm = llm
            self.prompt = prompt
            self.asrAPIKey = asrAPIKey
            self.llmAPIKey = llmAPIKey
        }
    }

    public enum Event: Sendable {
        case asrPartial(String)
        case asrFinal(String)
        case llmDelta(String)
        case completed(TranscriptionResult)
        case failed(String)
    }

    private let registry: ProviderRegistry

    public init(registry: ProviderRegistry = .shared) {
        self.registry = registry
    }

    public func run(
        audio: Data,
        context: TextContext,
        config: Configuration
    ) -> AsyncThrowingStream<Event, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                let start = Date()
                do {
                    guard let asrProvider = registry.asr(config.asr.id) else {
                        throw ASRError.invalidResponse
                    }
                    var rawText = ""
                    let asrStream = try await asrProvider.transcribe(
                        audio: audio,
                        config: config.asr,
                        apiKey: config.asrAPIKey,
                        hotwords: config.prompt.hotwords
                    )
                    for try await chunk in asrStream {
                        if chunk.isFinal {
                            rawText = chunk.text
                            continuation.yield(.asrFinal(chunk.text))
                        } else {
                            continuation.yield(.asrPartial(chunk.text))
                        }
                    }

                    var finalText = rawText
                    if let llmCfg = config.llm,
                       let llmKey = config.llmAPIKey,
                       let llmProvider = registry.llm(llmCfg.id) {
                        finalText = ""
                        let llmStream = try await llmProvider.process(
                            rawText: rawText,
                            prompt: config.prompt,
                            context: context,
                            config: llmCfg,
                            apiKey: llmKey
                        )
                        for try await delta in llmStream {
                            finalText += delta
                            continuation.yield(.llmDelta(delta))
                        }
                    }

                    let result = TranscriptionResult(
                        rawText: rawText,
                        finalText: finalText,
                        promptID: config.prompt.id,
                        asrProviderID: config.asr.id,
                        llmProviderID: config.llm?.id,
                        durationMS: Int(Date().timeIntervalSince(start) * 1000)
                    )
                    continuation.yield(.completed(result))
                    continuation.finish()
                } catch {
                    continuation.yield(.failed(error.localizedDescription))
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
