import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("入门") {
                    NavigationLink("启用键盘指引") { OnboardingView(forceShow: true) }
                }
                Section("配置") {
                    NavigationLink("模型与 API Key") { ProviderSettingsView() }
                    NavigationLink("Prompt 模板") { PromptListView() }
                }
                Section("数据") {
                    NavigationLink("历史记录") { HistoryListView() }
                }
            }
            .navigationTitle("语音输入")
        }
    }
}
