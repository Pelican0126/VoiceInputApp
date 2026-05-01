import SwiftUI
import AVFoundation
import SharedKit

struct OnboardingView: View {
    @EnvironmentObject var router: SessionRouter
    @State private var step: Step = .permissions
    @State private var qwenKey: String = ""
    @State private var mimoKey: String = ""

    var forceShow: Bool = false

    enum Step: Int, CaseIterable {
        case permissions, apiKeys, enableKeyboard

        var title: String {
            switch self {
            case .permissions: return "授权麦克风"
            case .apiKeys: return "填写 API Key"
            case .enableKeyboard: return "启用键盘"
            }
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            ProgressView(value: Double(step.rawValue + 1), total: Double(Step.allCases.count))
                .padding(.top)

            Text(step.title).font(.title.bold())

            Group {
                switch step {
                case .permissions: permissionsStep
                case .apiKeys: apiKeysStep
                case .enableKeyboard: enableKeyboardStep
                }
            }
            .frame(maxHeight: .infinity)

            HStack {
                if step != .permissions {
                    Button("上一步") { previous() }
                }
                Spacer()
                Button(step == .enableKeyboard ? "完成" : "下一步") {
                    next()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .padding()
    }

    private var permissionsStep: some View {
        VStack(spacing: 16) {
            Text("需要麦克风权限以录制语音。所有音频在你的设备上处理，仅在调用你配置的 API 时上传。")
                .multilineTextAlignment(.center)
            Button("请求麦克风权限") {
                AVAudioApplication.requestRecordPermission { _ in }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private var apiKeysStep: some View {
        Form {
            Section("Qwen3-ASR-Flash (DashScope)") {
                SecureField("sk-...", text: $qwenKey)
            }
            Section("MiMo-V2.5 (小米)") {
                SecureField("sk-...", text: $mimoKey)
            }
            Section {
                Text("Key 仅保存在本机 Keychain，不会上传任何服务器。后续可在设置里修改或新增 Provider。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var enableKeyboardStep: some View {
        VStack(spacing: 16) {
            Text("打开「设置 → 通用 → 键盘 → 添加新键盘 → 语音输入」启用键盘，并打开「允许完全访问」。")
                .multilineTextAlignment(.center)
            Button("打开系统设置") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    private func next() {
        switch step {
        case .permissions:
            step = .apiKeys
        case .apiKeys:
            saveKeys()
            step = .enableKeyboard
        case .enableKeyboard:
            if forceShow {
                router.route = .home
            } else {
                router.finishOnboarding()
            }
        }
    }

    private func previous() {
        if let prev = Step(rawValue: step.rawValue - 1) {
            step = prev
        }
    }

    private func saveKeys() {
        let keychain = KeychainStore.shared
        if !qwenKey.isEmpty {
            try? keychain.set(qwenKey, for: ProviderConfig.defaultQwenASR.apiKeyRef)
        }
        if !mimoKey.isEmpty {
            try? keychain.set(mimoKey, for: ProviderConfig.defaultMiMoLLM.apiKeyRef)
        }
    }
}
