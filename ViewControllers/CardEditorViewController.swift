//
//  CardEditorViewController.swift
//  FlashFlow
//
//  Created by bbdyno on 2/11/26.
//

import UIKit
import SnapKit

final class CardEditorViewController: UIViewController {
    enum Mode {
        case create
        case edit(DeckCard)
    }

    private let mode: Mode
    private let onSave: @MainActor (DeckDetailViewModel.CardDraft) -> Void

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()

    private let frontField = UITextField()
    private let backTextView = UITextView()
    private let noteField = UITextField()
    private let backPlaceholder = UILabel()

    init(
        mode: Mode,
        onSave: @escaping @MainActor (DeckDetailViewModel.CardDraft) -> Void
    ) {
        self.mode = mode
        self.onSave = onSave
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        applyInitialValues()
    }

    private func configureUI() {
        view.backgroundColor = .systemBackground
        title = modeTitle
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Save",
            style: .done,
            target: self,
            action: #selector(didTapSave)
        )

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)

        scrollView.keyboardDismissMode = .interactive
        stackView.axis = .vertical
        stackView.spacing = 14

        frontField.placeholder = "Front"
        frontField.borderStyle = .roundedRect
        frontField.autocapitalizationType = .sentences
        frontField.clearButtonMode = .whileEditing

        noteField.placeholder = "Note (optional)"
        noteField.borderStyle = .roundedRect
        noteField.autocapitalizationType = .sentences
        noteField.clearButtonMode = .whileEditing

        backTextView.font = UIFont.systemFont(ofSize: 16)
        backTextView.layer.borderColor = UIColor.separator.cgColor
        backTextView.layer.borderWidth = 1
        backTextView.layer.cornerRadius = 10
        backTextView.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        backTextView.delegate = self

        backPlaceholder.text = "Back"
        backPlaceholder.textColor = .placeholderText
        backPlaceholder.font = UIFont.systemFont(ofSize: 16)

        let backContainer = UIView()
        backContainer.addSubview(backTextView)
        backContainer.addSubview(backPlaceholder)

        stackView.addArrangedSubview(frontField)
        stackView.addArrangedSubview(backContainer)
        stackView.addArrangedSubview(noteField)

        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(20)
        }

        frontField.snp.makeConstraints { make in
            make.height.equalTo(44)
        }

        backContainer.snp.makeConstraints { make in
            make.height.equalTo(180)
        }

        backTextView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        backPlaceholder.snp.makeConstraints { make in
            make.top.equalTo(backTextView).offset(13)
            make.leading.equalTo(backTextView).offset(15)
        }

        noteField.snp.makeConstraints { make in
            make.height.equalTo(44)
            make.bottom.equalToSuperview()
        }
    }

    private func applyInitialValues() {
        guard case let .edit(card) = mode else {
            return
        }

        frontField.text = card.content.title
        backTextView.text = card.content.detail
        noteField.text = card.content.subtitle == "No Note" ? "" : card.content.subtitle
        backPlaceholder.isHidden = !(backTextView.text ?? "").isEmpty
    }

    private var modeTitle: String {
        switch mode {
        case .create:
            return "Add Card"
        case .edit:
            return "Edit Card"
        }
    }

    @objc
    private func didTapSave() {
        let draft = DeckDetailViewModel.CardDraft(
            front: frontField.text ?? "",
            back: backTextView.text ?? "",
            note: noteField.text ?? ""
        )
        onSave(draft)
        navigationController?.popViewController(animated: true)
    }
}

extension CardEditorViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        backPlaceholder.isHidden = !(textView.text ?? "").isEmpty
    }
}
