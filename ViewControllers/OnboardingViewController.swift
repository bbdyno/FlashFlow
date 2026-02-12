//
//  OnboardingViewController.swift
//  FlashFlow
//
//  Created by bbdyno on 2/11/26.
//

import UIKit
import SnapKit
import UniformTypeIdentifiers

final class OnboardingViewController: UIViewController {
    private static let backupFileExtension = "ffbackup"

    private struct OnboardingDraft {
        let deckTitle: String
        let front: String
        let back: String
        let note: String
    }

    private let repository: CardRepository
    var onCompleted: (() -> Void)?

    private let backgroundGradientLayer = CAGradientLayer()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()

    private let deckField = UITextField()
    private let frontField = UITextField()
    private let backField = UITextField()
    private let noteField = UITextField()
    private let startButton = UIButton(type: .system)
    private let importButton = UIButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    init(repository: CardRepository) {
        self.repository = repository
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradientLayer.frame = view.bounds
    }

    private func configureUI() {
        view.layer.insertSublayer(backgroundGradientLayer, at: 0)
        view.backgroundColor = .clear
        navigationItem.hidesBackButton = true

        AppTheme.applyGradient(to: backgroundGradientLayer)

        titleLabel.text = "Welcome to FlashFlow"
        titleLabel.textColor = AppTheme.textPrimary
        titleLabel.numberOfLines = 2
        titleLabel.font = UIFont(name: "AvenirNext-Bold", size: 30) ?? .systemFont(ofSize: 30, weight: .bold)

        subtitleLabel.text = "Create your first deck and card to start studying right away."
        subtitleLabel.textColor = AppTheme.textSecondary
        subtitleLabel.numberOfLines = 2
        subtitleLabel.font = UIFont(name: "AvenirNext-Medium", size: 16) ?? .systemFont(ofSize: 16, weight: .medium)

        [deckField, frontField, backField, noteField].forEach { field in
            field.backgroundColor = AppTheme.cardBackground
            field.textColor = AppTheme.textPrimary
            field.autocapitalizationType = .sentences
            field.clearButtonMode = .whileEditing
            field.layer.borderWidth = 1
            field.layer.borderColor = AppTheme.cardBorder.cgColor
            field.layer.cornerRadius = 12
            field.layer.cornerCurve = .continuous
            field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 1))
            field.leftViewMode = .always
        }

        deckField.placeholder = "Deck name (e.g. Vocabulary)"
        frontField.placeholder = "First card front"
        backField.placeholder = "First card back"
        noteField.placeholder = "Note (optional)"

        [deckField, frontField, backField, noteField].forEach { field in
            field.attributedPlaceholder = NSAttributedString(
                string: field.placeholder ?? "",
                attributes: [.foregroundColor: AppTheme.textSecondary]
            )
        }

        startButton.setTitle("Create First Deck", for: .normal)
        startButton.setTitleColor(AppTheme.textPrimary, for: .normal)
        startButton.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 16) ?? .systemFont(ofSize: 16, weight: .bold)
        startButton.backgroundColor = AppTheme.accent.withAlphaComponent(0.86)
        startButton.layer.cornerRadius = 14
        startButton.layer.cornerCurve = .continuous
        startButton.addTarget(self, action: #selector(didTapStart), for: .touchUpInside)

        importButton.setTitle("Import Backup Instead", for: .normal)
        importButton.setTitleColor(AppTheme.textPrimary, for: .normal)
        importButton.titleLabel?.font = UIFont(name: "AvenirNext-DemiBold", size: 15) ?? .systemFont(ofSize: 15, weight: .semibold)
        importButton.backgroundColor = AppTheme.infoBlue.withAlphaComponent(0.42)
        importButton.layer.cornerRadius = 12
        importButton.layer.cornerCurve = .continuous
        importButton.layer.borderWidth = 1
        importButton.layer.borderColor = AppTheme.cardBorder.cgColor
        importButton.addTarget(self, action: #selector(didTapImportBackup), for: .touchUpInside)

        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = AppTheme.textPrimary

        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(deckField)
        view.addSubview(frontField)
        view.addSubview(backField)
        view.addSubview(noteField)
        view.addSubview(startButton)
        view.addSubview(importButton)
        startButton.addSubview(loadingIndicator)

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(30)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.leading.trailing.equalTo(titleLabel)
        }

        deckField.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(30)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(48)
        }

        frontField.snp.makeConstraints { make in
            make.top.equalTo(deckField.snp.bottom).offset(12)
            make.leading.trailing.height.equalTo(deckField)
        }

        backField.snp.makeConstraints { make in
            make.top.equalTo(frontField.snp.bottom).offset(12)
            make.leading.trailing.height.equalTo(deckField)
        }

        noteField.snp.makeConstraints { make in
            make.top.equalTo(backField.snp.bottom).offset(12)
            make.leading.trailing.height.equalTo(deckField)
        }

        startButton.snp.makeConstraints { make in
            make.top.equalTo(noteField.snp.bottom).offset(20)
            make.leading.trailing.equalTo(deckField)
            make.height.equalTo(50)
        }

        importButton.snp.makeConstraints { make in
            make.top.equalTo(startButton.snp.bottom).offset(10)
            make.leading.trailing.equalTo(deckField)
            make.height.equalTo(44)
        }

        loadingIndicator.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(16)
        }
    }

    @objc
    private func didTapStart() {
        guard let draft = normalizedDraft() else {
            return
        }

        setLoading(true)
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.setLoading(false) }

            do {
                try await self.repository.prepare()
                let deck = try await self.repository.createDeck(title: draft.deckTitle)
                _ = try await self.repository.addCard(
                    to: deck.id,
                    front: draft.front,
                    back: draft.back,
                    note: draft.note
                )
                self.onCompleted?()
                self.dismiss(animated: true)
            } catch {
                self.presentError(message: Self.userFacingMessage(from: error))
            }
        }
    }

    @objc
    private func didTapImportBackup() {
        let backupType = UTType(filenameExtension: Self.backupFileExtension) ?? .data
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [backupType])
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }

    private func normalizedDraft() -> OnboardingDraft? {
        let deckTitle = CardTextSanitizer.normalizeSingleLine(deckField.text ?? "")
        let front = CardTextSanitizer.normalizeMultiline(frontField.text ?? "")
        let back = CardTextSanitizer.normalizeMultiline(backField.text ?? "")
        let note = CardTextSanitizer.normalizeSingleLine(noteField.text ?? "")

        guard !deckTitle.isEmpty else {
            presentValidationError(
                title: "Invalid Deck Name",
                message: "Please enter a deck title."
            )
            return nil
        }

        guard !front.isEmpty, !back.isEmpty else {
            presentValidationError(
                title: "Invalid Card",
                message: "Front and back must contain text."
            )
            return nil
        }

        deckField.text = deckTitle
        frontField.text = front
        backField.text = back
        noteField.text = note

        return OnboardingDraft(
            deckTitle: deckTitle,
            front: front,
            back: back,
            note: note
        )
    }

    private func setLoading(_ isLoading: Bool) {
        if isLoading {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }

        [deckField, frontField, backField, noteField, startButton, importButton].forEach { $0.isUserInteractionEnabled = !isLoading }
    }

    private func presentError(message: String) {
        guard presentedViewController == nil else {
            return
        }

        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

    private func presentValidationError(title: String, message: String) {
        guard presentedViewController == nil else {
            return
        }

        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func presentImportConfirmation(data: Data, preview: BackupPreview) {
        guard presentedViewController == nil else {
            return
        }

        let message = "Decks: \(preview.deckCount)\nCards: \(preview.cardCount)\nReviews: \(preview.reviewCount)\n\nImport this backup now?"
        let alert = UIAlertController(
            title: "Import Backup",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Import", style: .default, handler: { [weak self] _ in
            self?.importBackupData(data)
        }))
        present(alert, animated: true)
    }

    private func importBackupData(_ data: Data) {
        setLoading(true)
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.setLoading(false) }

            do {
                try await self.repository.importBackupData(data)
                NotificationCenter.default.post(name: .deckDataDidChange, object: nil)
                self.onCompleted?()
                self.dismiss(animated: true)
            } catch {
                self.presentError(message: Self.userFacingMessage(from: error))
            }
        }
    }

    private static func userFacingMessage(from error: Error) -> String {
        if let localized = error as? LocalizedError,
           let description = localized.errorDescription,
           !description.isEmpty {
            return description
        }
        return "An error occurred during onboarding."
    }
}

extension OnboardingViewController: UIDocumentPickerDelegate {
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {}

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let fileURL = urls.first else {
            presentValidationError(
                title: "Invalid Backup",
                message: "Please select a valid backup file."
            )
            return
        }

        setLoading(true)
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.setLoading(false) }

            let didStartAccessing = fileURL.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    fileURL.stopAccessingSecurityScopedResource()
                }
            }

            do {
                guard fileURL.pathExtension.lowercased() == Self.backupFileExtension else {
                    self.presentValidationError(
                        title: "Invalid Backup",
                        message: "File extension must be .\(Self.backupFileExtension)."
                    )
                    return
                }

                let data = try Data(contentsOf: fileURL)
                let preview = try await self.repository.previewBackupData(data)
                self.presentImportConfirmation(data: data, preview: preview)
            } catch {
                self.presentError(message: Self.userFacingMessage(from: error))
            }
        }
    }
}
