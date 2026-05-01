import Foundation

public protocol VoiceActivityDetector: Sendable {
    mutating func feed(samples: [Float]) -> VADEvent
    mutating func reset()
}

public enum VADEvent: Sendable, Equatable {
    case silence
    case speech
    case speechEnded(silenceDurationMS: Int)
}

public struct EnergyVAD: VoiceActivityDetector {
    private let frameSize: Int
    private let energyThreshold: Float
    private let silenceTimeoutMS: Int
    private var silentMS: Int = 0
    private var inSpeech: Bool = false
    private var residual: [Float] = []

    public init(
        frameSize: Int = 512,
        energyThreshold: Float = 0.005,
        silenceTimeoutMS: Int = 800
    ) {
        self.frameSize = frameSize
        self.energyThreshold = energyThreshold
        self.silenceTimeoutMS = silenceTimeoutMS
    }

    public mutating func feed(samples: [Float]) -> VADEvent {
        residual.append(contentsOf: samples)
        var event: VADEvent = inSpeech ? .speech : .silence
        let frameMS = Int(Double(frameSize) / 16.0)

        while residual.count >= frameSize {
            let frame = Array(residual.prefix(frameSize))
            residual.removeFirst(frameSize)
            var sumSq: Float = 0
            for s in frame { sumSq += s * s }
            let energy = sqrtf(sumSq / Float(frame.count))
            if energy > energyThreshold {
                if !inSpeech { inSpeech = true }
                silentMS = 0
                event = .speech
            } else if inSpeech {
                silentMS += frameMS
                if silentMS >= silenceTimeoutMS {
                    inSpeech = false
                    let total = silentMS
                    silentMS = 0
                    event = .speechEnded(silenceDurationMS: total)
                    break
                }
            }
        }
        return event
    }

    public mutating func reset() {
        residual.removeAll()
        silentMS = 0
        inSpeech = false
    }
}

public struct SileroVAD: VoiceActivityDetector {
    private var inner = EnergyVAD()

    public init() {}

    public mutating func feed(samples: [Float]) -> VADEvent {
        inner.feed(samples: samples)
    }

    public mutating func reset() {
        inner.reset()
    }
}
