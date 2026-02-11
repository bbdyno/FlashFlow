//
//  DeckDetailViewController.swift
//  FlashFlow
//
//  Created by bbdyno on 2/11/26.
//

import UIKit
import SnapKit

final class DeckDetailViewController: UIViewController {
    private let repository: CardRepository
    private let deckID: UUID

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    private var cards: [DeckCard] = []

    private lazy var viewModel: DeckDetailViewModel = {
        let viewModel = DeckDetailViewModel(repository: repository, deckID: deckID)
        viewModel.bind(output: makeOutput())
        return viewModel
    }()

    init(repository: CardRepository, deckID: UUID) {
        self.repository = repository
        self.deckID = deckID
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        Task { @MainActor [weak self] in
            guard let self else { return }
            await self.viewModel.send(.viewDidLoad)
        }
    }

    private func makeOutput() -> DeckDetailViewModel.Output {
        DeckDetailViewModel.Output(
            didChangeLoading: { [weak self] isLoading in
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                } else {
                    self?.loadingIndicator.stopAnimating()
                }
            },
            didUpdateDeckTitle: { [weak self] title in
                self?.title = title
            },
            didUpdateCards: { [weak self] cards in
                self?.cards = cards
                self?.tableView.reloadData()
                self?.emptyLabel.isHidden = !cards.isEmpty
            },
            didReceiveError: { [weak self] message in
                self?.presentError(message)
            }
        )
    }

    private func configureUI() {
        view.backgroundColor = .systemBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(didTapAddCard)
        )

        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 74
        view.addSubview(tableView)

        emptyLabel.text = "카드가 없습니다.\n+ 버튼으로 카드를 추가하세요."
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

    @objc
    private func didTapAddCard() {
        let editor = CardEditorViewController(mode: .create) { [weak self] draft in
            Task { @MainActor [weak self] in
                guard let self else { return }
                await self.viewModel.send(.addCard(draft))
            }
        }
        navigationController?.pushViewController(editor, animated: true)
    }

    private func presentEditor(for card: DeckCard) {
        let editor = CardEditorViewController(mode: .edit(card)) { [weak self] draft in
            Task { @MainActor [weak self] in
                guard let self else { return }
                await self.viewModel.send(.updateCard(cardID: card.id, draft: draft))
            }
        }
        navigationController?.pushViewController(editor, animated: true)
    }

    private func presentError(_ message: String) {
        guard presentedViewController == nil else {
            return
        }
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "닫기", style: .cancel))
        present(alert, animated: true)
    }

    private func stateText(for card: DeckCard) -> String {
        switch card.schedule.state {
        case .new:
            return "NEW"
        case .learning:
            return "LEARNING"
        case .review:
            return "REVIEW"
        case .relearning:
            return "RELEARNING"
        }
    }
}

extension DeckDetailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        cards.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "CardCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .subtitle, reuseIdentifier: identifier)
        let card = cards[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = card.content.title
        content.secondaryText = "\(stateText(for: card)) · Due \(DateFormatter.shortDate.string(from: card.schedule.dueDate))"
        content.secondaryTextProperties.color = .secondaryLabel
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

extension DeckDetailViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        presentEditor(for: cards[indexPath.row])
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let card = cards[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            guard let self else {
                completion(false)
                return
            }
            Task { @MainActor [weak self] in
                guard let self else { return }
                await self.viewModel.send(.deleteCard(card.id))
                completion(true)
            }
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }
}

private extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
}
