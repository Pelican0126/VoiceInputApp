import SwiftUI
import SharedKit

struct RecordingView: View {
    let sessionID: String
    @StateObject private var vm = RecordingViewModel()
    @EnvironmentObject var router: SessionRouter

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            statusIcon
                .font(.system(size: 64))
                .foregroundStyle(vm.state.tint)

            Text(vm.state.label)
                .font(.title3)
                .foregroundStyle(.secondary)

            if !vm.streamingText.isEmpty {
                ScrollView {
                    Text(vm.streamingText)
                        .padding()
                }
                .frame(maxHeight: 200)
            }

            Spacer()

            HStack(spacing: 32) {
                Button(role: .cancel) {
                    vm.cancel(sessionID: sessionID)
                    router.route = .home
                } label: {
                    Label("取消", systemImage: "xmark.circle")
                }
                .buttonStyle(.bordered)

                Button {
                    vm.toggleStop()
                } label: {
                    Label(vm.canStop ? "停止" : "结束", systemImage: "stop.circle")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!vm.canStop)
            }
            .padding(.bottom)
        }
        .padding()
        .task { await vm.start(sessionID: sessionID) }
        .onChange(of: vm.didFinish) { _, finished in
            if finished { router.route = .home }
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch vm.state {
        case .idle, .starting: Image(systemName: "mic.slash")
        case .listening: Image(systemName: "waveform")
        case .recognizing: Image(systemName: "ellipsis.message")
        case .polishing: Image(systemName: "sparkles")
        case .delivered: Image(systemName: "checkmark.seal")
        case .failed: Image(systemName: "exclamationmark.triangle")
        }
    }
}
