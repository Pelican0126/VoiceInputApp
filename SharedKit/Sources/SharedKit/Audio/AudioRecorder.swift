import AVFoundation
import Foundation

public final class AudioRecorder: @unchecked Sendable {
    public enum State: Equatable, Sendable {
        case idle
        case recording
        case stopped
        case failed(String)
    }

    public private(set) var state: State = .idle

    private let engine = AVAudioEngine()
    private let targetSampleRate: Double = 16_000
    private var converter: AVAudioConverter?
    private var pcmFloatBuffer: [Float] = []
    private let bufferLock = NSLock()

    public var onSamples: (([Float]) -> Void)?

    public init() {}

    public func configureSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try session.setPreferredSampleRate(targetSampleRate)
        try session.setActive(true, options: [])
    }

    public func start() throws {
        guard state != .recording else { return }

        let input = engine.inputNode
        let inputFormat = input.outputFormat(forBus: 0)
        guard let target = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: targetSampleRate,
            channels: 1,
            interleaved: false
        ) else {
            throw NSError(domain: "AudioRecorder", code: -1)
        }
        converter = AVAudioConverter(from: inputFormat, to: target)

        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 4_096, format: inputFormat) { [weak self] buffer, _ in
            guard let self else { return }
            self.process(buffer: buffer, target: target)
        }

        engine.prepare()
        try engine.start()
        state = .recording
    }

    public func stop() {
        guard state == .recording else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        state = .stopped
    }

    public func drainPCM() -> [Float] {
        bufferLock.lock(); defer { bufferLock.unlock() }
        let out = pcmFloatBuffer
        pcmFloatBuffer.removeAll(keepingCapacity: true)
        return out
    }

    public func snapshotPCM() -> [Float] {
        bufferLock.lock(); defer { bufferLock.unlock() }
        return pcmFloatBuffer
    }

    private func process(buffer: AVAudioPCMBuffer, target: AVAudioFormat) {
        guard let converter else { return }
        let outCapacity = AVAudioFrameCount(Double(buffer.frameLength) * target.sampleRate / buffer.format.sampleRate) + 1024
        guard let outBuffer = AVAudioPCMBuffer(pcmFormat: target, frameCapacity: outCapacity) else { return }

        var error: NSError?
        var supplied = false
        converter.convert(to: outBuffer, error: &error) { _, status in
            if supplied {
                status.pointee = .noDataNow
                return nil
            }
            supplied = true
            status.pointee = .haveData
            return buffer
        }
        if error != nil { return }

        let frames = Int(outBuffer.frameLength)
        guard frames > 0, let chData = outBuffer.floatChannelData?.pointee else { return }
        let samples = Array(UnsafeBufferPointer(start: chData, count: frames))

        bufferLock.lock()
        pcmFloatBuffer.append(contentsOf: samples)
        bufferLock.unlock()
        onSamples?(samples)
    }
}

public enum WAVEncoder {
    public static func encode(samples: [Float], sampleRate: Int = 16_000) -> Data {
        let pcm16 = samples.map { sample -> Int16 in
            let clamped = max(-1.0, min(1.0, sample))
            return Int16(clamped * Float(Int16.max))
        }
        var data = Data()
        let byteRate = sampleRate * 2
        let dataSize = pcm16.count * 2

        data.append("RIFF".data(using: .ascii)!)
        data.append(UInt32(36 + dataSize).littleEndianData)
        data.append("WAVE".data(using: .ascii)!)
        data.append("fmt ".data(using: .ascii)!)
        data.append(UInt32(16).littleEndianData)
        data.append(UInt16(1).littleEndianData)
        data.append(UInt16(1).littleEndianData)
        data.append(UInt32(sampleRate).littleEndianData)
        data.append(UInt32(byteRate).littleEndianData)
        data.append(UInt16(2).littleEndianData)
        data.append(UInt16(16).littleEndianData)
        data.append("data".data(using: .ascii)!)
        data.append(UInt32(dataSize).littleEndianData)
        pcm16.withUnsafeBufferPointer { buf in
            data.append(buf.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: dataSize) {
                Data(bytes: $0, count: dataSize)
            })
        }
        return data
    }
}

private extension UInt32 {
    var littleEndianData: Data {
        var v = self.littleEndian
        return Data(bytes: &v, count: 4)
    }
}

private extension UInt16 {
    var littleEndianData: Data {
        var v = self.littleEndian
        return Data(bytes: &v, count: 2)
    }
}
