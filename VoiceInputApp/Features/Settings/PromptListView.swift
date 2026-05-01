import SwiftUI
import SharedKit

struct PromptListView: View {
    @State private var prompts: [PromptTemplate] = []

    var body: some View {
        List(prompts) { p in
            NavigationLink(p.name) {
                PromptDetailView(prompt: p)
            }
        }
        .navigationTitle("Prompt 模板")
        .task {
            prompts = PromptLoader.loadBuiltIns()
        }
    }
}

struct PromptDetailView: View {
    let prompt: PromptTemplate

    var body: some View {
        Form {
            Section("System") {
                Text(prompt.system).font(.callout.monospaced())
            }
            Section("User Template") {
                Text(prompt.userTemplate).font(.callout.monospaced())
            }
            if !prompt.hotwords.isEmpty {
                Section("Hotwords") {
                    Text(prompt.hotwords.joined(separator: ", "))
                }
            }
        }
        .navigationTitle(prompt.name)
    }
}
