import SwiftUI
import SharedKit

struct ProviderSettingsView: View {
    @State private var qwenKey: String = ""
    @State private var mimoKey: String = ""
    @State private var customBaseURL: String = ""
    @State private var customModel: String = ""
    @State private var customKey: String = ""
    @State private var savedToast: Bool = false

    var body: some View {
        Form {
            Section("默认 ASR") {
                LabeledContent("Provider", value: ProviderConfig.defaultQwenASR.displayName)
                LabeledContent("Endpoint", value: ProviderConfig.defaultQwenASR.baseURL.absoluteString)
                LabeledContent("Model", value: ProviderConfig.defaultQwenASR.model)
                SecureField("API Key", text: $qwenKey)
            }
            Section("默认 LLM") {
                LabeledContent("Provider", value: ProviderConfig.defaultMiMoLLM.displayName)
                LabeledContent("Endpoint", value: ProviderConfig.defaultMiMoLLM.baseURL.absoluteString)
                LabeledContent("Model", value: ProviderConfig.defaultMiMoLLM.model)
                SecureField("API Key", text: $mimoKey)
            }
            Section("自定义 LLM (OpenAI 兼容)") {
                TextField("Base URL", text: $customBaseURL).autocapitalization(.none)
                TextField("Model", text: $customModel).autocapitalization(.none)
                SecureField("API Key", text: $customKey)
                Text("DeepSeek / Kimi / vLLM 自部署等均兼容。")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Section {
                Button("保存") { save() }
            }
        }
        .navigationTitle("模型配置")
        .task { load() }
        .alert("已保存", isPresented: $savedToast) {
            Button("好") {}
        }
    }

    private func load() {
        let kc = KeychainStore.shared
        qwenKey = (try? kc.get(ProviderConfig.defaultQwenASR.apiKeyRef)) ?? ""
        mimoKey = (try? kc.get(ProviderConfig.defaultMiMoLLM.apiKeyRef)) ?? ""
    }

    private func save() {
        let kc = KeychainStore.shared
        try? kc.set(qwenKey, for: ProviderConfig.defaultQwenASR.apiKeyRef)
        try? kc.set(mimoKey, for: ProviderConfig.defaultMiMoLLM.apiKeyRef)

        if !customBaseURL.isEmpty, !customKey.isEmpty, let url = URL(string: customBaseURL) {
            let cfg = ProviderConfig(
                id: "custom-llm",
                displayName: "Custom",
                baseURL: url,
                model: customModel.isEmpty ? "gpt-3.5-turbo" : customModel,
                apiKeyRef: "custom.llm.apiKey"
            )
            try? kc.set(customKey, for: cfg.apiKeyRef)
            try? SharedStore.shared.setCodable(cfg, for: .providerConfigs)
        }
        savedToast = true
    }
}
