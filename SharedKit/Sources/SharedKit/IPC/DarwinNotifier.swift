import Foundation

public enum DarwinSignal: String, Sendable {
    case resultReady = "com.example.voiceinput.result.ready"
    case sessionCancelled = "com.example.voiceinput.session.cancelled"
    case configChanged = "com.example.voiceinput.config.changed"
}

public final class DarwinNotifier: @unchecked Sendable {
    public static let shared = DarwinNotifier()

    private var observers: [DarwinSignal: [UUID: () -> Void]] = [:]
    private let lock = NSLock()

    private init() {}

    public func post(_ signal: DarwinSignal) {
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        let name = CFNotificationName(signal.rawValue as CFString)
        CFNotificationCenterPostNotification(center, name, nil, nil, true)
    }

    @discardableResult
    public func observe(_ signal: DarwinSignal, handler: @escaping () -> Void) -> UUID {
        lock.lock()
        let token = UUID()
        observers[signal, default: [:]][token] = handler
        let needsRegister = (observers[signal]?.count ?? 0) == 1
        lock.unlock()

        if needsRegister {
            let center = CFNotificationCenterGetDarwinNotifyCenter()
            let name = signal.rawValue as CFString
            let observer = Unmanaged.passUnretained(self).toOpaque()
            CFNotificationCenterAddObserver(
                center,
                observer,
                { _, observer, name, _, _ in
                    guard let observer, let name else { return }
                    let me = Unmanaged<DarwinNotifier>.fromOpaque(observer).takeUnretainedValue()
                    let raw = name.rawValue as String
                    guard let signal = DarwinSignal(rawValue: raw) else { return }
                    me.dispatch(signal)
                },
                name,
                nil,
                .deliverImmediately
            )
        }
        return token
    }

    public func remove(_ token: UUID, signal: DarwinSignal) {
        lock.lock(); defer { lock.unlock() }
        observers[signal]?.removeValue(forKey: token)
    }

    private func dispatch(_ signal: DarwinSignal) {
        lock.lock()
        let handlers = observers[signal]?.values ?? [:].values
        let toRun = Array(handlers)
        lock.unlock()
        for h in toRun { h() }
    }
}
