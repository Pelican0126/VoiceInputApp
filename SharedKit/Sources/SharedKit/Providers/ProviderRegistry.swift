import Foundation

public final class ProviderRegistry: @unchecked Sendable {
    public static let shared = ProviderRegistry()

    private var asrProviders: [String: ASRProvider] = [:]
    private var llmProviders: [String: LLMProvider] = [:]
    private let lock = NSLock()

    private init() {
        registerDefaults()
    }

    private func registerDefaults() {
        register(asr: QwenASRProvider())
        register(asr: MiMoASRProvider())
        register(llm: OpenAICompatLLMProvider.mimo)
        register(llm: OpenAICompatLLMProvider(id: "openai-compat", displayName: "Custom (OpenAI 兼容)"))
    }

    public func register(asr: ASRProvider) {
        lock.lock(); defer { lock.unlock() }
        asrProviders[asr.id] = asr
    }

    public func register(llm: LLMProvider) {
        lock.lock(); defer { lock.unlock() }
        llmProviders[llm.id] = llm
    }

    public func asr(_ id: String) -> ASRProvider? {
        lock.lock(); defer { lock.unlock() }
        return asrProviders[id]
    }

    public func llm(_ id: String) -> LLMProvider? {
        lock.lock(); defer { lock.unlock() }
        return llmProviders[id]
    }

    public func allASR() -> [ASRProvider] {
        lock.lock(); defer { lock.unlock() }
        return Array(asrProviders.values)
    }

    public func allLLM() -> [LLMProvider] {
        lock.lock(); defer { lock.unlock() }
        return Array(llmProviders.values)
    }
}
