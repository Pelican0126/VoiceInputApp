import Foundation
import SwiftUI
import SharedKit

@MainActor
final class RecordingViewModel: ObservableObject {
    enum State {
        case idle, starting, listening, recognizing, polishing, delivered, failed(String)

        var label: String {
            switch self {
            case .idle: return "准备中"
            case .starting: return "启动中…"
            case .listening: return "正在聆听"
            case .recognizing: return "识别中"
            case .polishing: return "润色中"
            case .delivered: return "已写入键盘"
            case .failed(let m): return "失败：\(m)"
            }
        }

        var tint: Color {
            switch self {
            case .listening: return .red
            case .recognizing, .polishing: return .blue
            case .delivered: return .green
            case .failed: return .orange
            default: return .gray
            }
        }
    }

    @Published var state: State = .idle
    @Published var streamingText: String = ""
    @Published var didFinish: Bool = false
    var canStop: Bool {
        if case .listening = state { return true }
        return false
    }

    private let recorder = AudioRecorder()
    private var vad = SileroVAD()
    private var pipelineTask: Task<Void, Never>?

    func start(sessionID: String) async {
        state = .starting
        do {
            try recorder.configureSession()
            try recorder.start()
            state = .listening

            recorder.onSamples = { [weak self] samples in
                guard let self else { return }
                let event = self.vad.feed(samples: samples)
                if case .speechEnded = event {
                    Task { @MainActor in self.toggleStop() }
                }
            }
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func toggleStop() {
        guard canStop else { return }
        recorder.stop()
        state = .recognizing
        runPipeline()
    }

    func cancel(sessionID: String) {
        pipelineTask?.cancel()
        recorder.stop()
        SharedStore.shared.clearPending()
    }

    private func runPipeline() {
        let store = SharedStore.shared
        guard let sessionID = store.string(for: .pendingSession) else {
            state = .failed("缺少会话信息")
            return
        }
        let context = TextContext(
            beforeCursor: store.string(for: .pendingContextBefore) ?? "",
            afterCursor: store.string(for: .pendingContextAfter) ?? "",
            hostBundleID: store.string(for: .pendingHostBundleID)
        )
        let promptID = store.string(for: .pendingPromptID) ?? PromptTemplate.BuiltInID.general.rawValue
        let prompts = PromptLoader.loadBuiltIns()
        let prompt = prompts.first { $0.id == promptID } ?? prompts.first ?? PromptTemplate(
            id: "general", name: "通用", system: "整理文本。", userTemplate: "{{raw_text}}"
        )

        let asrCfg = ProviderConfig.defaultQwenASR
        let llmCfg = ProviderConfig.defaultMiMoLLM
        let asrKey = (try? KeychainStore.shared.get(asrCfg.apiKeyRef)) ?? ""
        let llmKey = (try? KeychainStore.shared.get(llmCfg.apiKeyRef)) ?? ""

        let samples = recorder.drainPCM()
        let wav = WAVEncoder.encode(samples: samples)

        pipelineTask = Task { [weak self] in
            guard let self else { return }
            let pipeline = TranscriptionPipeline()
            let cfg = TranscriptionPipeline.Configuration(
                asr: asrCfg,
                llm: llmKey.isEmpty ? nil : llmCfg,
                prompt: prompt,
                asrAPIKey: asrKey,
                llmAPIKey: llmKey.isEmpty ? nil : llmKey
            )
            do {
                for try await event in await pipeline.run(audio: wav, context: context, config: cfg) {
                    await MainActor.run {
                        switch event {
                        case .asrFinal(let t):
                            self.streamingText = t
                            self.state = .polishing
                        case .asrPartial(let t):
                            self.streamingText = t
                        case .llmDelta(let d):
                            self.streamingText += d
                        case .completed(let result):
                            try? store.writeResult(result, sessionID: sessionID)
                            DarwinNotifier.shared.post(.resultReady)
                            self.state = .delivered
                            self.didFinish = true
                        case .failed(let msg):
                            self.state = .failed(msg)
                        }
                    }
                }
            } catch {
                await MainActor.run { self.state = .failed(error.localizedDescription) }
            }
        }
    }
}
