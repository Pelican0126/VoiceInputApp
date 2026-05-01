import UIKit

final class KeyboardView: UIView {
    private let micButton = UIButton(type: .system)
    private let deleteButton = UIButton(type: .system)
    private let spaceButton = UIButton(type: .system)
    private let returnButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)
    private let hintLabel = UILabel()

    private let onMicTap: () -> Void
    private let onNext: () -> Void
    private let onDelete: () -> Void
    private let onSpace: () -> Void
    private let onReturn: () -> Void

    init(
        onMicTap: @escaping () -> Void,
        onNext: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onSpace: @escaping () -> Void,
        onReturn: @escaping () -> Void
    ) {
        self.onMicTap = onMicTap
        self.onNext = onNext
        self.onDelete = onDelete
        self.onSpace = onSpace
        self.onReturn = onReturn
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        backgroundColor = UIColor.systemGroupedBackground

        configure(button: micButton, systemImage: "mic.fill", action: #selector(micTap))
        configure(button: deleteButton, systemImage: "delete.left", action: #selector(deleteTap))
        configure(button: spaceButton, title: "空格", action: #selector(spaceTap))
        configure(button: returnButton, title: "换行", action: #selector(returnTap))
        configure(button: nextButton, systemImage: "globe", action: #selector(nextTap))

        let topRow = UIStackView(arrangedSubviews: [nextButton, micButton, deleteButton])
        topRow.axis = .horizontal
        topRow.distribution = .equalCentering
        topRow.alignment = .center

        let bottomRow = UIStackView(arrangedSubviews: [spaceButton, returnButton])
        bottomRow.axis = .horizontal
        bottomRow.distribution = .fillEqually
        bottomRow.spacing = 8

        hintLabel.font = .systemFont(ofSize: 12)
        hintLabel.textColor = .secondaryLabel
        hintLabel.numberOfLines = 2
        hintLabel.textAlignment = .center

        let main = UIStackView(arrangedSubviews: [hintLabel, topRow, bottomRow])
        main.axis = .vertical
        main.spacing = 12
        main.translatesAutoresizingMaskIntoConstraints = false
        addSubview(main)
        NSLayoutConstraint.activate([
            main.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            main.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            main.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            main.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            micButton.heightAnchor.constraint(equalToConstant: 64),
            micButton.widthAnchor.constraint(equalToConstant: 64),
        ])
        micButton.layer.cornerRadius = 32
        micButton.backgroundColor = .systemBlue
        micButton.tintColor = .white
    }

    private func configure(button: UIButton, systemImage: String? = nil, title: String? = nil, action: Selector) {
        if let img = systemImage {
            button.setImage(UIImage(systemName: img), for: .normal)
        }
        if let t = title {
            button.setTitle(t, for: .normal)
        }
        button.addTarget(self, action: action, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
    }

    func showHint(_ text: String) {
        hintLabel.text = text
    }

    func flashSuccess() {
        let original = micButton.backgroundColor
        micButton.backgroundColor = .systemGreen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.micButton.backgroundColor = original
        }
    }

    @objc private func micTap() { onMicTap() }
    @objc private func nextTap() { onNext() }
    @objc private func deleteTap() { onDelete() }
    @objc private func spaceTap() { onSpace() }
    @objc private func returnTap() { onReturn() }
}
