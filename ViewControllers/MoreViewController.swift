//
//  MoreViewController.swift
//  FlashForge
//
//  Created by bbdyno on 2/11/26.
//

import UIKit
import SnapKit
import UniformTypeIdentifiers

final class MoreViewController: UIViewController {
    private static let backupFileExtension = "ffbackup"

    private let repository: CardRepository

    private let backgroundGradientLayer = CAGradientLayer()
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()

    private let reminderCard = UIView()
    private let reminderTitleLabel = UILabel()
    private let reminderDescriptionLabel = UILabel()
    private let reminderSwitch = UISwitch()
    private let reminderTimePicker = UIDatePicker()
    private let reminderStatusLabel = UILabel()

    private let dataCard = UIView()
    private let dataTitleLabel = UILabel()
    private let backupButton = UIButton(type: .system)
    private let restoreButton = UIButton(type: .system)
    private let resetButton = UIButton(type: .system)
    private let dataStatusLabel = UILabel()

    private let developerCard = UIView()
    private let developerTitleLabel = UILabel()
    private let generateSamplesButton = UIButton(type: .system)
    private let developerStatusLabel = UILabel()

    private let appInfoCard = UIView()
    private let appInfoTitleLabel = UILabel()
    private let appInfoBodyLabel = UILabel()

    private let service = StudyReminderService.shared

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
        applySettings(service.loadSettings())
        updateAppInfo()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradientLayer.frame = view.bounds
    }

    private func configureUI() {
        title = FlashForgeStrings.More.title
        navigationItem.largeTitleDisplayMode = .automatic

        view.layer.insertSublayer(backgroundGradientLayer, at: 0)
        AppTheme.applyGradient(to: backgroundGradientLayer)
        view.backgroundColor = .clear

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(stackView)

        scrollView.backgroundColor = .clear
        contentView.backgroundColor = .clear
        stackView.axis = .vertical
        stackView.spacing = 14

        configureReminderCard()
        configureDataCard()
        configureDeveloperCard()
        configureAppInfoCard()

        stackView.addArrangedSubview(reminderCard)
        stackView.addArrangedSubview(dataCard)
        stackView.addArrangedSubview(developerCard)
        stackView.addArrangedSubview(appInfoCard)

        let footerLabel = UILabel()
        footerLabel.text = FlashForgeStrings.More.footer
        footerLabel.font = UIFont(name: "AvenirNext-Medium", size: 12) ?? .systemFont(ofSize: 12, weight: .medium)
        footerLabel.textColor = AppTheme.textSecondary
        footerLabel.numberOfLines = 0
        stackView.addArrangedSubview(footerLabel)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }

        stackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().inset(20)
        }
    }

    private func configureReminderCard() {
        reminderCard.backgroundColor = AppTheme.cardBackground
        reminderCard.layer.borderWidth = 1
        reminderCard.layer.borderColor = AppTheme.cardBorder.cgColor
        reminderCard.layer.cornerRadius = 16
        reminderCard.layer.cornerCurve = .continuous

        reminderTitleLabel.text = FlashForgeStrings.More.Reminder.title
        reminderTitleLabel.font = UIFont(name: "AvenirNext-Bold", size: 19) ?? .systemFont(ofSize: 19, weight: .bold)
        reminderTitleLabel.textColor = AppTheme.textPrimary

        reminderDescriptionLabel.text = FlashForgeStrings.More.Reminder.description
        reminderDescriptionLabel.font = UIFont(name: "AvenirNext-Medium", size: 14) ?? .systemFont(ofSize: 14, weight: .medium)
        reminderDescriptionLabel.textColor = AppTheme.textSecondary
        reminderDescriptionLabel.numberOfLines = 0

        reminderSwitch.onTintColor = AppTheme.accent
        reminderSwitch.addTarget(self, action: #selector(didChangeReminderSwitch(_:)), for: .valueChanged)

        reminderTimePicker.datePickerMode = .time
        reminderTimePicker.preferredDatePickerStyle = .wheels
        reminderTimePicker.locale = Locale(identifier: "en_US_POSIX")
        reminderTimePicker.tintColor = AppTheme.accent
        reminderTimePicker.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        reminderTimePicker.layer.cornerRadius = 12
        reminderTimePicker.layer.cornerCurve = .continuous
        reminderTimePicker.overrideUserInterfaceStyle = .dark
        reminderTimePicker.setValue(AppTheme.textPrimary, forKey: "textColor")
        reminderTimePicker.addTarget(self, action: #selector(didChangeReminderTime(_:)), for: .valueChanged)

        reminderStatusLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 13) ?? .systemFont(ofSize: 13, weight: .semibold)
        reminderStatusLabel.textColor = AppTheme.textSecondary
        reminderStatusLabel.numberOfLines = 2

        let headerRow = UIStackView()
        headerRow.axis = .horizontal
        headerRow.alignment = .center
        headerRow.spacing = 8
        headerRow.addArrangedSubview(reminderTitleLabel)
        headerRow.addArrangedSubview(UIView())
        headerRow.addArrangedSubview(reminderSwitch)

        reminderCard.addSubview(headerRow)
        reminderCard.addSubview(reminderDescriptionLabel)
        reminderCard.addSubview(reminderTimePicker)
        reminderCard.addSubview(reminderStatusLabel)

        headerRow.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        reminderDescriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(headerRow.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        reminderTimePicker.snp.makeConstraints { make in
            make.top.equalTo(reminderDescriptionLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(8)
        }

        reminderStatusLabel.snp.makeConstraints { make in
            make.top.equalTo(reminderTimePicker.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(16)
        }
    }

    private func configureDataCard() {
        dataCard.backgroundColor = AppTheme.cardBackground
        dataCard.layer.borderWidth = 1
        dataCard.layer.borderColor = AppTheme.cardBorder.cgColor
        dataCard.layer.cornerRadius = 16
        dataCard.layer.cornerCurve = .continuous

        dataTitleLabel.text = FlashForgeStrings.More.Data.title
        dataTitleLabel.font = UIFont(name: "AvenirNext-Bold", size: 19) ?? .systemFont(ofSize: 19, weight: .bold)
        dataTitleLabel.textColor = AppTheme.textPrimary

        configureActionButton(backupButton, title: FlashForgeStrings.More.Data.export, tint: AppTheme.accent)
        backupButton.accessibilityIdentifier = "more.backupButton"
        backupButton.addTarget(self, action: #selector(didTapBackup), for: .touchUpInside)

        configureActionButton(restoreButton, title: FlashForgeStrings.More.Data.`import`, tint: AppTheme.infoBlue)
        restoreButton.accessibilityIdentifier = "more.restoreButton"
        restoreButton.addTarget(self, action: #selector(didTapRestore), for: .touchUpInside)

        configureActionButton(resetButton, title: FlashForgeStrings.More.Data.reset, tint: AppTheme.dangerRed)
        resetButton.accessibilityIdentifier = "more.resetButton"
        resetButton.addTarget(self, action: #selector(didTapReset), for: .touchUpInside)

        dataStatusLabel.font = UIFont(name: "AvenirNext-Medium", size: 13) ?? .systemFont(ofSize: 13, weight: .medium)
        dataStatusLabel.textColor = AppTheme.textSecondary
        dataStatusLabel.text = FlashForgeStrings.More.Data.description
        dataStatusLabel.numberOfLines = 2

        let buttonStack = UIStackView(arrangedSubviews: [backupButton, restoreButton, resetButton])
        buttonStack.axis = .vertical
        buttonStack.spacing = 10

        dataCard.addSubview(dataTitleLabel)
        dataCard.addSubview(buttonStack)
        dataCard.addSubview(dataStatusLabel)

        dataTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        buttonStack.snp.makeConstraints { make in
            make.top.equalTo(dataTitleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        [backupButton, restoreButton, resetButton].forEach { button in
            button.snp.makeConstraints { make in
                make.height.equalTo(42)
            }
        }

        dataStatusLabel.snp.makeConstraints { make in
            make.top.equalTo(buttonStack.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(16)
        }
    }

    private func configureAppInfoCard() {
        appInfoCard.backgroundColor = AppTheme.cardBackground
        appInfoCard.layer.borderWidth = 1
        appInfoCard.layer.borderColor = AppTheme.cardBorder.cgColor
        appInfoCard.layer.cornerRadius = 16
        appInfoCard.layer.cornerCurve = .continuous

        appInfoTitleLabel.text = FlashForgeStrings.More.Appinfo.title
        appInfoTitleLabel.font = UIFont(name: "AvenirNext-Bold", size: 19) ?? .systemFont(ofSize: 19, weight: .bold)
        appInfoTitleLabel.textColor = AppTheme.textPrimary

        appInfoBodyLabel.font = UIFont(name: "AvenirNext-Medium", size: 14) ?? .systemFont(ofSize: 14, weight: .medium)
        appInfoBodyLabel.textColor = AppTheme.textSecondary
        appInfoBodyLabel.numberOfLines = 0

        appInfoCard.addSubview(appInfoTitleLabel)
        appInfoCard.addSubview(appInfoBodyLabel)

        appInfoTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        appInfoBodyLabel.snp.makeConstraints { make in
            make.top.equalTo(appInfoTitleLabel.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(16)
        }
    }

    private func configureDeveloperCard() {
        developerCard.backgroundColor = AppTheme.cardBackground
        developerCard.layer.borderWidth = 1
        developerCard.layer.borderColor = AppTheme.cardBorder.cgColor
        developerCard.layer.cornerRadius = 16
        developerCard.layer.cornerCurve = .continuous

        developerTitleLabel.text = FlashForgeStrings.More.Developer.title
        developerTitleLabel.font = UIFont(name: "AvenirNext-Bold", size: 19) ?? .systemFont(ofSize: 19, weight: .bold)
        developerTitleLabel.textColor = AppTheme.textPrimary

        configureActionButton(generateSamplesButton, title: FlashForgeStrings.More.Developer.generateSamples, tint: AppTheme.accentTeal)
        generateSamplesButton.addTarget(self, action: #selector(didTapGenerateSamples), for: .touchUpInside)

        developerStatusLabel.font = UIFont(name: "AvenirNext-Medium", size: 13) ?? .systemFont(ofSize: 13, weight: .medium)
        developerStatusLabel.textColor = AppTheme.textSecondary
        developerStatusLabel.text = FlashForgeStrings.More.Developer.description
        developerStatusLabel.numberOfLines = 2

        developerCard.addSubview(developerTitleLabel)
        developerCard.addSubview(generateSamplesButton)
        developerCard.addSubview(developerStatusLabel)

        developerTitleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        generateSamplesButton.snp.makeConstraints { make in
            make.top.equalTo(developerTitleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(42)
        }

        developerStatusLabel.snp.makeConstraints { make in
            make.top.equalTo(generateSamplesButton.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(16)
        }
    }

    private func configureActionButton(_ button: UIButton, title: String, tint: UIColor) {
        button.setTitle(title, for: .normal)
        button.setTitleColor(AppTheme.textPrimary, for: .normal)
        button.titleLabel?.font = UIFont(name: "AvenirNext-DemiBold", size: 14) ?? .systemFont(ofSize: 14, weight: .semibold)
        button.backgroundColor = tint.withAlphaComponent(0.40)
        button.layer.cornerRadius = 12
        button.layer.cornerCurve = .continuous
        button.layer.borderWidth = 1
        button.layer.borderColor = AppTheme.cardBorder.cgColor
    }

    private func applySettings(_ settings: StudyReminderSettings) {
        reminderSwitch.setOn(settings.isEnabled, animated: false)
        reminderTimePicker.date = makeDate(hour: settings.hour, minute: settings.minute)
        reminderTimePicker.isEnabled = settings.isEnabled

        if settings.isEnabled {
            reminderStatusLabel.text = FlashForgeStrings.More.Reminder.Status.on(
                settings.hour,
                settings.minute
            )
        } else {
            reminderStatusLabel.text = FlashForgeStrings.More.Reminder.Status.off
        }
    }

    private func updateAppInfo() {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "-"
        let build = info?["CFBundleVersion"] as? String ?? "-"
        appInfoBodyLabel.text = FlashForgeStrings.More.Appinfo.body(version, build)
    }

    @objc
    private func didChangeReminderSwitch(_ sender: UISwitch) {
        updateReminder(isEnabled: sender.isOn)
    }

    @objc
    private func didChangeReminderTime(_ sender: UIDatePicker) {
        guard reminderSwitch.isOn else {
            return
        }
        updateReminder(isEnabled: true)
    }

    @objc
    private func didTapBackup() {
        setDataButtonsEnabled(false)

        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.setDataButtonsEnabled(true) }

            do {
                let backupData = try await self.repository.exportBackupData()
                let fileURL = try self.writeBackupFile(data: backupData)
                self.presentShareSheet(fileURL: fileURL, sourceView: self.backupButton)
                self.dataStatusLabel.text = FlashForgeStrings.More.Data.Export.done
            } catch {
                self.dataStatusLabel.text = Self.userFacingMessage(from: error)
            }
        }
    }

    @objc
    private func didTapGenerateSamples() {
        generateSamplesButton.isEnabled = false
        generateSamplesButton.alpha = 0.55

        Task { @MainActor [weak self] in
            guard let self else { return }
            defer {
                self.generateSamplesButton.isEnabled = true
                self.generateSamplesButton.alpha = 1.0
            }

            do {
                let created = try await self.repository.createSampleDecksIfNeeded()
                self.developerStatusLabel.text = FlashForgeStrings.More.Developer.createdResult(created)
                NotificationCenter.default.post(name: .deckDataDidChange, object: nil)
            } catch {
                self.developerStatusLabel.text = Self.userFacingMessage(from: error)
            }
        }
    }

    @objc
    private func didTapRestore() {
        let backupType = UTType(filenameExtension: Self.backupFileExtension) ?? .data
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [backupType])
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }

    @objc
    private func didTapReset() {
        let alert = UIAlertController(
            title: FlashForgeStrings.More.Data.Reset.Confirm.title,
            message: FlashForgeStrings.More.Data.Reset.Confirm.message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: FlashForgeStrings.More.Common.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: FlashForgeStrings.More.Data.Reset.Confirm.action, style: .destructive, handler: { [weak self] _ in
            self?.resetAllData()
        }))
        present(alert, animated: true)
    }

    private func resetAllData() {
        setDataButtonsEnabled(false)

        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.setDataButtonsEnabled(true) }

            do {
                try await self.repository.resetAllData()
                self.service.disableWithoutPrompt()
                self.applySettings(self.service.loadSettings())
                self.dataStatusLabel.text = FlashForgeStrings.More.Data.Reset.done
                NotificationCenter.default.post(name: .deckDataDidChange, object: nil)
            } catch {
                self.dataStatusLabel.text = Self.userFacingMessage(from: error)
            }
        }
    }

    private func updateReminder(isEnabled: Bool) {
        setControlsEnabled(false)
        let selectedTime = reminderTimePicker.date

        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.setControlsEnabled(true) }

            do {
                let settings = try await self.service.update(isEnabled: isEnabled, time: selectedTime)
                self.applySettings(settings)
            } catch let error as StudyReminderError {
                self.reminderSwitch.setOn(false, animated: true)
                self.reminderTimePicker.isEnabled = false
                self.reminderStatusLabel.text = error.errorDescription
                if error == .permissionDenied {
                    self.presentPermissionAlert()
                }
            } catch {
                self.reminderSwitch.setOn(false, animated: true)
                self.reminderTimePicker.isEnabled = false
                self.reminderStatusLabel.text = FlashForgeStrings.Error.generic
            }
        }
    }

    private func setControlsEnabled(_ isEnabled: Bool) {
        reminderSwitch.isEnabled = isEnabled
        reminderTimePicker.isEnabled = isEnabled && reminderSwitch.isOn
    }

    private func setDataButtonsEnabled(_ isEnabled: Bool) {
        backupButton.isEnabled = isEnabled
        restoreButton.isEnabled = isEnabled
        resetButton.isEnabled = isEnabled
        [backupButton, restoreButton, resetButton].forEach { button in
            button.alpha = isEnabled ? 1.0 : 0.55
        }
    }

    private func presentPermissionAlert() {
        let alert = UIAlertController(
            title: FlashForgeStrings.More.Reminder.Permission.title,
            message: FlashForgeStrings.More.Reminder.Permission.message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: FlashForgeStrings.More.Common.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: FlashForgeStrings.More.Common.openSettings, style: .default, handler: { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            UIApplication.shared.open(url)
        }))
        present(alert, animated: true)
    }

    private func makeDate(hour: Int, minute: Int) -> Date {
        let now = Date()
        var components = Calendar.current.dateComponents([.year, .month, .day], from: now)
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? now
    }

    private func writeBackupFile(data: Data) throws -> URL {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmm"
        let fileName = "FlashForge-backup-\(formatter.string(from: Date())).\(Self.backupFileExtension)"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }

    private func presentShareSheet(fileURL: URL, sourceView: UIView) {
        let controller = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        controller.popoverPresentationController?.sourceView = sourceView
        controller.popoverPresentationController?.sourceRect = sourceView.bounds
        present(controller, animated: true)
    }

    private static func userFacingMessage(from error: Error) -> String {
        if let localized = error as? LocalizedError,
           let description = localized.errorDescription,
           !description.isEmpty {
            return description
        }
        return FlashForgeStrings.Error.generic
    }

    private func presentImportConfirmation(data: Data, preview: BackupPreview) {
        let previewText = FlashForgeStrings.More.Data.Import.preview(
            preview.deckCount,
            preview.cardCount,
            preview.reviewCount
        )
        let message = FlashForgeStrings.More.Data.Import.Confirm.message(previewText)
        let alert = UIAlertController(
            title: FlashForgeStrings.More.Data.Import.Confirm.title,
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: FlashForgeStrings.More.Common.cancel, style: .cancel))
        alert.addAction(UIAlertAction(title: FlashForgeStrings.More.Data.Import.Confirm.action, style: .default, handler: { [weak self] _ in
            self?.importBackupData(data)
        }))
        present(alert, animated: true)
    }

    private func importBackupData(_ data: Data) {
        setDataButtonsEnabled(false)
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.setDataButtonsEnabled(true) }

            do {
                try await self.repository.importBackupData(data)
                self.dataStatusLabel.text = FlashForgeStrings.More.Data.Import.done
                NotificationCenter.default.post(name: .deckDataDidChange, object: nil)
            } catch {
                self.dataStatusLabel.text = Self.userFacingMessage(from: error)
            }
        }
    }
}

extension MoreViewController: UIDocumentPickerDelegate {
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        dataStatusLabel.text = FlashForgeStrings.More.Data.Import.cancelled
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let fileURL = urls.first else {
            dataStatusLabel.text = FlashForgeStrings.More.Data.Import.invalidSelection
            return
        }

        setDataButtonsEnabled(false)
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.setDataButtonsEnabled(true) }

            let didStartAccessing = fileURL.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    fileURL.stopAccessingSecurityScopedResource()
                }
            }

            do {
                guard fileURL.pathExtension.lowercased() == Self.backupFileExtension else {
                    self.dataStatusLabel.text = FlashForgeStrings.More.Data.Import.invalidSelection
                    return
                }
                let data = try Data(contentsOf: fileURL)
                let preview = try await self.repository.previewBackupData(data)
                self.dataStatusLabel.text = FlashForgeStrings.More.Data.Import.preview(
                    preview.deckCount,
                    preview.cardCount,
                    preview.reviewCount
                )
                self.presentImportConfirmation(data: data, preview: preview)
            } catch {
                self.dataStatusLabel.text = Self.userFacingMessage(from: error)
            }
        }
    }
}
