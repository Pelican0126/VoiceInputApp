import UIKit
import SharedKit

final class KeyboardViewController: UIInputViewController {
    private var keyboardView: KeyboardView!
    private var resultObserver: UUID?
    private var pendingSessionID: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        keyboardView = KeyboardView(
            onMicTap: { [weak self] in self?.startVoiceSession() },
            onNext: { [weak self] in self?.advanceToNextInputMode() },
            onDelete: { [weak self] in self?.deletePrevious() },
            onSpace: { [weak self] in self?.textDocumentProxy.insertText(" ") },
            onReturn: { [weak self] in self?.textDocumentProxy.insertText("\n") }
        )
        keyboardView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(keyboardView)
        NSLayoutConstraint.activate([
            keyboardView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            keyboardView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            keyboardView.topAnchor.constraint(equalTo: view.topAnchor),
            keyboardView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        resultObserver = DarwinNotifier.shared.observe(.resultReady) { [weak self] in
            DispatchQueue.main.async { self?.deliverResult() }
        }
    }

    deinit {
        if let resultObserver {
            DarwinNotifier.shared.remove(resultObserver, signal: .resultReady)
        }
    }

    override func textWillChange(_ textInput: UITextInput?) {}
    override func textDidChange(_ textInput: UITextInput?) {}

    private func deletePrevious() {
        textDocumentProxy.deleteBackward()
    }

    private func startVoiceSession() {
        guard hasFullAccess else {
            keyboardView.showHint("请先在「设置 → 通用 → 键盘 → 语音输入」打开「允许完全访问」")
            return
        }
        let sessionID = UUID().uuidString
        pendingSessionID = sessionID

        let store = SharedStore.shared
        store.setString(sessionID, for: .pendingSession)
        store.setString(textDocumentProxy.documentContextBeforeInput ?? "", for: .pendingContextBefore)
        store.setString(textDocumentProxy.documentContextAfterInput ?? "", for: .pendingContextAfter)
        store.setString(nil, for: .pendingHostBundleID)
        store.setString(PromptTemplate.BuiltInID.general.rawValue, for: .pendingPromptID)

        let url = URL(string: "\(SharedKit.urlScheme)://record?session=\(sessionID)")!
        openURL(url)
    }

    private func openURL(_ url: URL) {
        var responder: UIResponder? = self
        while let r = responder {
            if let app = r as? UIApplication {
                app.open(url, options: [:], completionHandler: nil)
                return
            }
            responder = r.next
        }
        extensionContext?.open(url) { _ in }
    }

    private func deliverResult() {
        guard let sessionID = pendingSessionID,
              let result = SharedStore.shared.consumeResult(sessionID: sessionID) else {
            return
        }
        textDocumentProxy.insertText(result.finalText)
        pendingSessionID = nil
        keyboardView.flashSuccess()
    }
}
