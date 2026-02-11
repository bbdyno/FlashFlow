//
//  DecksViewController.swift
//  FlashFlow
//
//  Created by bbdyno on 2/11/26.
//

import UIKit
import SnapKit

final class DecksViewController: UIViewController {
    private let repository: CardRepository

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    private var deckSummaries: [DeckSummary] = []
    private var schedulerMode: SchedulerMode = .sm2

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
            didUpdateSchedulerMode: { [weak self] mode in
                self?.schedulerMode = mode
                self?.rebuildSchedulerMenu()
            },
            didReceiveError: { [weak self] message in
                self?.presentError(message)
            }
        )
    }

    private func configureUI() {
        title = "Decks"
        navigationItem.largeTitleDisplayMode = .always

        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(didTapAddDeck)
        )
        rebuildSchedulerMenu()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DeckCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 70
        view.addSubview(tableView)

        emptyLabel.text = "아직 덱이 없습니다.\n우측 상단 + 버튼으로 새 덱을 만들어주세요."
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 2
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)

        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)

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

    private func rebuildSchedulerMenu() {
        let actions = SchedulerMode.allCases.map { mode in
            UIAction(title: mode.title, state: mode == schedulerMode ? .on : .off) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    await self.viewModel.send(.didSelectSchedulerMode(mode))
                }
            }
        }

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: schedulerMode.shortLabel,
            menu: UIMenu(title: "Algorithm", options: .singleSelection, children: actions)
        )
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
        let alert = UIAlertController(title: "새 덱", message: "덱 이름을 입력하세요.", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "예: iOS Interview"
        }
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "생성", style: .default, handler: { [weak self, weak alert] _ in
            guard let self else { return }
            let title = alert?.textFields?.first?.text ?? ""
            Task { @MainActor [weak self] in
                guard let self else { return }
                await self.viewModel.send(.createDeck(title))
            }
        }))
        present(alert, animated: true)
    }

    private func presentRenamePrompt(for deck: DeckSummary) {
        let alert = UIAlertController(title: "덱 이름 변경", message: nil, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.text = deck.title
        }
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "저장", style: .default, handler: { [weak self, weak alert] _ in
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
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "닫기", style: .cancel))
        present(alert, animated: true)
    }
}

extension DecksViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        deckSummaries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeckCell", for: indexPath)
        let deck = deckSummaries[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = deck.title
        content.secondaryText = "Cards \(deck.totalCardCount) · L \(deck.dueCounts.learning) / R \(deck.dueCounts.review)"
        content.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
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
