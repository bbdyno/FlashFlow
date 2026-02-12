//
//  DecksViewController.swift
//  FlashForge
//
//  Created by bbdyno on 2/11/26.
//

import UIKit
import SnapKit
import UniformTypeIdentifiers

final class DecksViewController: UIViewController {
    private static let deckImportFileExtension = "ffdeck"

    private let repository: CardRepository

    private let backgroundGradientLayer = CAGradientLayer()
    private let topGlowView = UIView()
    private let bottomGlowView = UIView()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    private var deckSummaries: [DeckSummary] = []

    private lazy var viewModel: DecksViewModel = {
        let viewModel = DecksViewModel(repository: repository)
        viewModel.bind(output: makeOutput())
        return viewModel
    }()

    init(repository: CardRepository) {
        self.repository = repository
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: .deckDataDidChange, object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        configureObserver()
        Task { @MainActor [weak self] in
            guard let self else { return }
            await self.viewModel.send(.viewDidLoad)
        }
    }

    private func makeOutput() -> DecksViewModel.Output {
        DecksViewModel.Output(
            didChangeLoading: { [weak self] isLoading in
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                } else {
                    self?.loadingIndicator.stopAnimating()
                }
            },
            didUpdateDecks: { [weak self] decks in
                self?.deckSummaries = decks
                self?.tableView.reloadData()
                self?.emptyLabel.isHidden = !decks.isEmpty
            },
            didReceiveError: { [weak self] message in
                self?.presentError(message)
            }
        )
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradientLayer.frame = view.bounds
        topGlowView.layer.cornerRadius = topGlowView.bounds.height / 2
        bottomGlowView.layer.cornerRadius = bottomGlowView.bounds.height / 2
    }

    private func configureUI() {
        title = "Decks"
        navigationItem.largeTitleDisplayMode = .automatic

        view.layer.insertSublayer(backgroundGradientLayer, at: 0)
        AppTheme.applyGradient(to: backgroundGradientLayer)
        view.backgroundColor = .clear

        topGlowView.backgroundColor = AppTheme.accent.withAlphaComponent(0.22)
        topGlowView.layer.shadowColor = AppTheme.accent.cgColor
        topGlowView.layer.shadowOpacity = 0.28
        topGlowView.layer.shadowRadius = 52
        topGlowView.layer.shadowOffset = .zero

        bottomGlowView.backgroundColor = AppTheme.accentTeal.withAlphaComponent(0.16)
        bottomGlowView.layer.shadowColor = AppTheme.accentTeal.cgColor
        bottomGlowView.layer.shadowOpacity = 0.28
        bottomGlowView.layer.shadowRadius = 52
        bottomGlowView.layer.shadowOffset = .zero

        view.addSubview(topGlowView)
        view.addSubview(bottomGlowView)

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(didTapAddDeck)
        )
        navigationItem.rightBarButtonItem?.tintColor = AppTheme.textPrimary

        tableView.register(DeckSummaryCell.self, forCellReuseIdentifier: DeckSummaryCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 86
        tableView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 20, right: 0)
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        view.addSubview(tableView)

        emptyLabel.text = "No decks yet.\nTap + to create your first deck."
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 2
        emptyLabel.textColor = AppTheme.textSecondary
        emptyLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)

        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = AppTheme.textPrimary
        view.addSubview(loadingIndicator)

        topGlowView.snp.makeConstraints { make in
            make.size.equalTo(280)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(-120)
            make.trailing.equalToSuperview().offset(120)
        }

        bottomGlowView.snp.makeConstraints { make in
            make.size.equalTo(240)
            make.leading.equalToSuperview().offset(-120)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(90)
        }

        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(24)
        }

        loadingIndicator.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(8)
            make.centerX.equalToSuperview()
        }
    }

    private func configureObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleDeckDataDidChange), name: .deckDataDidChange, object: nil)
    }

    @objc
    private func handleDeckDataDidChange() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            await self.viewModel.send(.didTapReload)
        }
    }

    @objc
    private func didTapAddDeck() {
        let actionSheet = UIAlertController(
            title: "Add Deck",
            message: "Choose how to add a deck.",
            preferredStyle: .actionSheet
        )
        actionSheet.addAction(UIAlertAction(title: "Create Manually", style: .default, handler: { [weak self] _ in
            self?.presentCreateDeckPrompt()
        }))
        actionSheet.addAction(UIAlertAction(title: "Import from File", style: .default, handler: { [weak self] _ in
            self?.presentDeckImportPicker()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        actionSheet.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(actionSheet, animated: true)
    }

    private func presentCreateDeckPrompt() {
        let alert = UIAlertController(title: "New Deck", message: "Enter a deck name.", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "e.g. iOS Interview"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Create", style: .default, handler: { [weak self, weak alert] _ in
            guard let self else { return }
            let title = alert?.textFields?.first?.text ?? ""
            Task { @MainActor [weak self] in
                guard let self else { return }
                await self.viewModel.send(.createDeck(title))
            }
        }))
        present(alert, animated: true)
    }

    private func presentDeckImportPicker() {
        let importType = UTType(filenameExtension: Self.deckImportFileExtension) ?? .json
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [importType, .json])
        picker.delegate = self
        picker.allowsMultipleSelection = false
        present(picker, animated: true)
    }

    private func presentRenamePrompt(for deck: DeckSummary) {
        let alert = UIAlertController(title: "Rename Deck", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = deck.title
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { [weak self, weak alert] _ in
            guard let self else { return }
            let newTitle = alert?.textFields?.first?.text ?? ""
            Task { @MainActor [weak self] in
                guard let self else { return }
                await self.viewModel.send(.renameDeck(deckID: deck.id, title: newTitle))
            }
        }))
        present(alert, animated: true)
    }

    private func presentError(_ message: String) {
        guard presentedViewController == nil else {
            return
        }
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close", style: .cancel))
        present(alert, animated: true)
    }
}

extension DecksViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let fileURL = urls.first else {
            presentError("Please select a deck file.")
            return
        }

        Task { @MainActor [weak self] in
            guard let self else { return }

            let didStartAccessing = fileURL.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    fileURL.stopAccessingSecurityScopedResource()
                }
            }

            do {
                let data = try Data(contentsOf: fileURL)
                await self.viewModel.send(.importDeckData(data))
            } catch {
                self.presentError("Failed to read the selected file.")
            }
        }
    }
}

extension DecksViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        deckSummaries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: DeckSummaryCell.reuseIdentifier,
            for: indexPath
        ) as? DeckSummaryCell else {
            return UITableViewCell()
        }
        let deck = deckSummaries[indexPath.row]

        let dueToday = deck.dueCounts.total
        let remaining = max(0, deck.totalCardCount - dueToday)
        cell.configure(
            title: deck.title,
            subtitle: "Today \(dueToday) · New \(deck.dueCounts.learning) / Review \(deck.dueCounts.review) · Remaining \(remaining)"
        )
        return cell
    }
}

extension DecksViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let deck = deckSummaries[indexPath.row]
        let detail = DeckDetailViewController(repository: repository, deckID: deck.id)
        navigationController?.pushViewController(detail, animated: true)
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let deck = deckSummaries[indexPath.row]

        let rename = UIContextualAction(style: .normal, title: "Rename") { [weak self] _, _, completion in
            self?.presentRenamePrompt(for: deck)
            completion(true)
        }
        rename.backgroundColor = .systemBlue

        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            guard let self else {
                completion(false)
                return
            }
            Task { @MainActor [weak self] in
                guard let self else { return }
                await self.viewModel.send(.deleteDeck(deck.id))
                completion(true)
            }
        }

        let config = UISwipeActionsConfiguration(actions: [delete, rename])
        config.performsFirstActionWithFullSwipe = false
        return config
    }
}

private final class DeckSummaryCell: UITableViewCell {
    static let reuseIdentifier = "DeckSummaryCell"

    private let cardView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let chevronImageView = UIImageView(image: UIImage(systemName: "chevron.right"))

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
        configureLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, subtitle: String) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }

    private func configureUI() {
        backgroundColor = .clear
        selectionStyle = .none
        contentView.backgroundColor = .clear

        cardView.backgroundColor = AppTheme.cardBackground
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = AppTheme.cardBorder.cgColor
        cardView.layer.cornerRadius = 14
        cardView.layer.cornerCurve = .continuous

        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = AppTheme.textPrimary

        subtitleLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        subtitleLabel.textColor = AppTheme.textSecondary
        subtitleLabel.numberOfLines = 1

        chevronImageView.tintColor = AppTheme.textSecondary
        chevronImageView.contentMode = .scaleAspectFit

        contentView.addSubview(cardView)
        cardView.addSubview(titleLabel)
        cardView.addSubview(subtitleLabel)
        cardView.addSubview(chevronImageView)
    }

    private func configureLayout() {
        cardView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(6)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        chevronImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(14)
            make.width.equalTo(10)
            make.height.equalTo(16)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.leading.equalToSuperview().inset(14)
            make.trailing.lessThanOrEqualTo(chevronImageView.snp.leading).offset(-10)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.leading.equalTo(titleLabel)
            make.trailing.lessThanOrEqualTo(chevronImageView.snp.leading).offset(-10)
            make.bottom.equalToSuperview().inset(12)
        }
    }
}
