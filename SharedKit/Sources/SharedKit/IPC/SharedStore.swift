import Foundation

public final class SharedStore: @unchecked Sendable {
    public static let shared = SharedStore()

    private let appGroupID: String
    private let lock = NSLock()
    private let defaults: UserDefaults?

    public init(appGroupID: String = SharedKit.appGroupID) {
        self.appGroupID = appGroupID
        self.defaults = UserDefaults(suiteName: appGroupID)
    }

    public enum Key: String, Sendable {
        case pendingSession = "pending.session.id"
        case pendingHostBundleID = "pending.host.bundleID"
        case pendingContextBefore = "pending.context.before"
        case pendingContextAfter = "pending.context.after"
        case pendingPromptID = "pending.prompt.id"
        case latestResult = "latest.result"
        case latestSessionID = "latest.session.id"
        case selectedASRProviderID = "config.asr.provider"
        case selectedLLMProviderID = "config.llm.provider"
        case providerConfigs = "config.providers"
        case userPrompts = "config.prompts"
    }

    public func setString(_ value: String?, for key: Key) {
        defaults?.set(value, forKey: key.rawValue)
    }

    public func string(for key: Key) -> String? {
        defaults?.string(forKey: key.rawValue)
    }

    public func setData(_ value: Data?, for key: Key) {
        defaults?.set(value, forKey: key.rawValue)
    }

    public func data(for key: Key) -> Data? {
        defaults?.data(forKey: key.rawValue)
    }

    public func setCodable<T: Encodable>(_ value: T?, for key: Key) throws {
        if let value {
            let data = try JSONEncoder().encode(value)
            setData(data, for: key)
        } else {
            setData(nil, for: key)
        }
    }

    public func codable<T: Decodable>(_ type: T.Type, for key: Key) -> T? {
        guard let data = data(for: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    public func clearPending() {
        for k in [Key.pendingSession, .pendingHostBundleID, .pendingContextBefore, .pendingContextAfter, .pendingPromptID] {
            defaults?.removeObject(forKey: k.rawValue)
        }
    }

    public func writeResult(_ result: TranscriptionResult, sessionID: String) throws {
        lock.lock(); defer { lock.unlock() }
        try setCodable(result, for: .latestResult)
        setString(sessionID, for: .latestSessionID)
    }

    public func consumeResult(sessionID: String) -> TranscriptionResult? {
        lock.lock(); defer { lock.unlock() }
        guard string(for: .latestSessionID) == sessionID else { return nil }
        let result = codable(TranscriptionResult.self, for: .latestResult)
        setData(nil, for: .latestResult)
        setString(nil, for: .latestSessionID)
        return result
    }
}
