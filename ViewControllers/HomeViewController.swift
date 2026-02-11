//
//  HomeViewController.swift
//  FlashFlow
//
//  Created by bbdyno on 2/11/26.
//

import UIKit
import SnapKit

final class HomeViewController: UIViewController {
    private let repository: CardRepository

    private let backgroundGradientLayer = CAGradientLayer()
    private let topGlowView = UIView()
    private let bottomGlowView = UIView()

    private let titleLabel = UILabel()
    private let deckButton = UIButton(type: .system)
    private let dueBadgeLabel = UILabel()
    private let glassCardView = GlassCardView()
    private let revealAnswerButton = UIButton(type: .system)
    private let gradePromptLabel = UILabel()
    private let gradeStackView = UIStackView()
    private let emptyStateLabel = UILabel()
    private let reloadButton = UIButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    private lazy var viewModel: HomeViewModel = {
        let viewModel = HomeViewModel(repository: repository)
        viewModel.bind(output: makeOutput())
        return viewModel
    }()

    private var isAnswerRevealed = false
    private var selectedDeckID: UUID?
    private var deckSummaries: [DeckSummary] = []
    private var cardHeightConstraint: Constraint?

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

    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureHierarchy()
        configureStyle()
        configureLayout()
        configureGradeButtons()
        configureNotifications()
        requestInitialData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task { @MainActor [weak self] in
            guard let self else { return }
            await self.viewModel.send(.didTapReload)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradientLayer.frame = view.bounds
        topGlowView.layer.cornerRadius = topGlowView.bounds.height / 2
        bottomGlowView.layer.cornerRadius = bottomGlowView.bounds.height / 2
        updateCardHeightIfNeeded()
    }

    private func makeOutput() -> HomeViewModel.Output {
        HomeViewModel.Output(
            didChangeLoading: { [weak self] isLoading in
                self?.updateLoadingState(isLoading)
            },
            didUpdateDeckSummaries: { [weak self] summaries, selectedDeckID in
                self?.applyDeckSummaries(summaries, selectedDeckID: selectedDeckID)
            },
            didUpdateQueueCounts: { [weak self] counts in
                self?.applyDueSummary(counts)
            },
            didUpdateCard: { [weak self] card in
                self?.render(card: card)
            },
            didShowEmptyState: { [weak self] message in
                self?.showEmptyState(message)
            },
            didReceiveError: { [weak self] message in
                self?.presentErrorAlert(message: message)
            }
        )
    }

    private func configureHierarchy() {
        view.layer.insertSublayer(backgroundGradientLayer, at: 0)

        view.addSubview(topGlowView)
        view.addSubview(bottomGlowView)
        view.addSubview(titleLabel)
        view.addSubview(deckButton)
        view.addSubview(dueBadgeLabel)
        view.addSubview(glassCardView)
        view.addSubview(revealAnswerButton)
        view.addSubview(gradePromptLabel)
        view.addSubview(gradeStackView)
        view.addSubview(emptyStateLabel)
        view.addSubview(reloadButton)
        view.addSubview(loadingIndicator)
    }

    private func configureStyle() {
        AppTheme.applyGradient(to: backgroundGradientLayer)

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

        titleLabel.text = L10n.tr("home.title")
        titleLabel.font = UIFont(name: "AvenirNext-Bold", size: 34) ?? .systemFont(ofSize: 34, weight: .bold)
        titleLabel.textColor = AppTheme.textPrimary

        deckButton.configuration = .plain()
        deckButton.configuration?.image = UIImage(systemName: "chevron.down")
        deckButton.configuration?.imagePlacement = .trailing
        deckButton.configuration?.imagePadding = 6
        deckButton.configuration?.baseForegroundColor = AppTheme.textPrimary
        deckButton.titleLabel?.font = UIFont(name: "AvenirNext-DemiBold", size: 14) ?? .systemFont(ofSize: 14, weight: .semibold)
        deckButton.layer.cornerRadius = 12
        deckButton.layer.cornerCurve = .continuous
        deckButton.layer.borderWidth = 1
        deckButton.layer.borderColor = AppTheme.cardBorder.cgColor
        deckButton.backgroundColor = AppTheme.cardBackground
        deckButton.showsMenuAsPrimaryAction = true
        setDeckButtonTitle(L10n.tr("home.deck.select"))

        dueBadgeLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 13) ?? .systemFont(ofSize: 13, weight: .semibold)
        dueBadgeLabel.textColor = AppTheme.textPrimary
        dueBadgeLabel.textAlignment = .center
        dueBadgeLabel.backgroundColor = AppTheme.cardBackground
        dueBadgeLabel.layer.cornerRadius = 14
        dueBadgeLabel.layer.cornerCurve = .continuous
        dueBadgeLabel.layer.borderWidth = 1
        dueBadgeLabel.layer.borderColor = AppTheme.cardBorder.cgColor
        dueBadgeLabel.clipsToBounds = true
        dueBadgeLabel.text = L10n.tr("home.due.none")

        revealAnswerButton.setTitle(L10n.tr("home.reveal"), for: .normal)
        revealAnswerButton.setTitleColor(AppTheme.textPrimary, for: .normal)
        revealAnswerButton.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 15) ?? .systemFont(ofSize: 15, weight: .bold)
        revealAnswerButton.backgroundColor = AppTheme.accent.withAlphaComponent(0.55)
        revealAnswerButton.layer.cornerRadius = 12
        revealAnswerButton.layer.cornerCurve = .continuous
        revealAnswerButton.layer.borderWidth = 1
        revealAnswerButton.layer.borderColor = AppTheme.cardBorder.cgColor
        revealAnswerButton.addTarget(self, action: #selector(didTapRevealAnswer), for: .touchUpInside)
        revealAnswerButton.isHidden = true

        gradePromptLabel.text = L10n.tr("home.grade.prompt")
        gradePromptLabel.textColor = AppTheme.textSecondary
        gradePromptLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 13) ?? .systemFont(ofSize: 13, weight: .semibold)
        gradePromptLabel.textAlignment = .center
        gradePromptLabel.numberOfLines = 2
        gradePromptLabel.isHidden = true

        gradeStackView.axis = .horizontal
        gradeStackView.alignment = .fill
        gradeStackView.distribution = .fillEqually
        gradeStackView.spacing = 10
        gradeStackView.isHidden = true

        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 3
        emptyStateLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 18) ?? .systemFont(ofSize: 18, weight: .semibold)
        emptyStateLabel.textColor = AppTheme.textPrimary
        emptyStateLabel.isHidden = true

        reloadButton.setTitle(L10n.tr("home.reload"), for: .normal)
        reloadButton.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 15) ?? .systemFont(ofSize: 15, weight: .bold)
        reloadButton.setTitleColor(AppTheme.textPrimary, for: .normal)
        reloadButton.backgroundColor = AppTheme.cardBackground
        reloadButton.layer.cornerRadius = 14
        reloadButton.layer.cornerCurve = .continuous
        reloadButton.layer.borderWidth = 1
        reloadButton.layer.borderColor = AppTheme.cardBorder.cgColor
        reloadButton.isHidden = true
        reloadButton.addTarget(self, action: #selector(didTapReloadButton), for: .touchUpInside)

        loadingIndicator.color = AppTheme.textPrimary
        loadingIndicator.hidesWhenStopped = true
    }

    private func configureLayout() {
        topGlowView.snp.makeConstraints { make in
            make.size.equalTo(280)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(-110)
            make.trailing.equalToSuperview().offset(120)
        }

        bottomGlowView.snp.makeConstraints { make in
            make.size.equalTo(240)
            make.leading.equalToSuperview().offset(-120)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(90)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.leading.equalToSuperview().inset(24)
            make.trailing.lessThanOrEqualTo(dueBadgeLabel.snp.leading).offset(-12)
        }

        dueBadgeLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(14)
            make.trailing.equalToSuperview().inset(24)
            make.height.equalTo(30)
            make.width.greaterThanOrEqualTo(104)
        }

        deckButton.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.leading.equalToSuperview().inset(24)
            make.height.equalTo(32)
            make.width.greaterThanOrEqualTo(120)
            make.trailing.lessThanOrEqualToSuperview().inset(24)
        }

        glassCardView.snp.makeConstraints { make in
            make.top.equalTo(deckButton.snp.bottom).offset(18)
            make.leading.trailing.equalToSuperview().inset(24)
            cardHeightConstraint = make.height.equalTo(280).constraint
        }

        revealAnswerButton.snp.makeConstraints { make in
            make.top.equalTo(glassCardView.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(44)
        }

        gradeStackView.snp.makeConstraints { make in
            make.top.equalTo(gradePromptLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(96)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).inset(12)
        }

        gradePromptLabel.snp.makeConstraints { make in
            make.top.equalTo(revealAnswerButton.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        emptyStateLabel.snp.makeConstraints { make in
            make.top.equalTo(glassCardView.snp.bottom).offset(18)
            make.leading.trailing.equalToSuperview().inset(24)
        }

        reloadButton.snp.makeConstraints { make in
            make.top.equalTo(emptyStateLabel.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            make.width.greaterThanOrEqualTo(120)
            make.height.equalTo(40)
        }

        loadingIndicator.snp.makeConstraints { make in
            make.center.equalTo(glassCardView)
        }
    }

    private func configureGradeButtons() {
        let configs: [(title: String, subtitle: String, grade: UserGrade, tint: UIColor)] = [
            (L10n.tr("home.grade.again.title"), L10n.tr("home.grade.again.subtitle"), .again, AppTheme.gradeAgain),
            (L10n.tr("home.grade.hard.title"), L10n.tr("home.grade.hard.subtitle"), .hard, AppTheme.gradeHard),
            (L10n.tr("home.grade.good.title"), L10n.tr("home.grade.good.subtitle"), .good, AppTheme.gradeGood),
            (L10n.tr("home.grade.easy.title"), L10n.tr("home.grade.easy.subtitle"), .easy, AppTheme.gradeEasy)
        ]

        let topRow = UIStackView()
        topRow.axis = .horizontal
        topRow.alignment = .fill
        topRow.distribution = .fillEqually
        topRow.spacing = 10

        let bottomRow = UIStackView()
        bottomRow.axis = .horizontal
        bottomRow.alignment = .fill
        bottomRow.distribution = .fillEqually
        bottomRow.spacing = 10

        gradeStackView.axis = .vertical
        gradeStackView.alignment = .fill
        gradeStackView.distribution = .fillEqually
        gradeStackView.spacing = 10
        gradeStackView.addArrangedSubview(topRow)
        gradeStackView.addArrangedSubview(bottomRow)

        configs.forEach { config in
            let button = UIButton(type: .system)
            var buttonConfig = UIButton.Configuration.filled()
            buttonConfig.title = config.title
            buttonConfig.subtitle = config.subtitle
            buttonConfig.titleAlignment = .center
            buttonConfig.baseForegroundColor = .white
            buttonConfig.baseBackgroundColor = config.tint.withAlphaComponent(0.90)
            buttonConfig.cornerStyle = .large
            buttonConfig.background.strokeWidth = 1
            buttonConfig.background.strokeColor = UIColor.white.withAlphaComponent(0.16)
            button.configuration = buttonConfig
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 14) ?? .systemFont(ofSize: 14, weight: .bold)
            button.tag = config.grade.rawValue
            button.addTarget(self, action: #selector(didTapGradeButton(_:)), for: .touchUpInside)
            if config.grade == .again || config.grade == .hard {
                topRow.addArrangedSubview(button)
            } else {
                bottomRow.addArrangedSubview(button)
            }
        }

        glassCardView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapRevealAnswer))
        glassCardView.addGestureRecognizer(tap)
    }

    private func configureNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleDeckDataDidChange), name: .deckDataDidChange, object: nil)
    }

    private func requestInitialData() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            await self.viewModel.send(.viewDidLoad)
        }
    }

    private func updateCardHeightIfNeeded() {
        let availableHeight = view.safeAreaLayoutGuide.layoutFrame.height
        let widthBased = max(220, (view.bounds.width - 48) * 0.76)
        let heightCap = max(220, availableHeight * 0.40)
        cardHeightConstraint?.update(offset: min(widthBased, heightCap))
    }

    @objc
    private func handleDeckDataDidChange() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            await self.viewModel.send(.didReceiveExternalDataChange)
        }
    }

    private func applyDeckSummaries(_ summaries: [DeckSummary], selectedDeckID: UUID?) {
        deckSummaries = summaries
        self.selectedDeckID = selectedDeckID

        if let selectedDeckID,
           let summary = summaries.first(where: { $0.id == selectedDeckID }) {
            setDeckButtonTitle(summary.title)
        } else {
            setDeckButtonTitle(L10n.tr("home.deck.select"))
        }

        rebuildDeckMenu()
    }

    private func rebuildDeckMenu() {
        guard !deckSummaries.isEmpty else {
            deckButton.menu = nil
            return
        }

        let actions = deckSummaries.map { summary in
            UIAction(title: summary.title, state: summary.id == selectedDeckID ? .on : .off) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    await self.viewModel.send(.didSelectDeck(summary.id))
                }
            }
        }
        deckButton.menu = UIMenu(title: L10n.tr("home.deck.select"), children: actions)
    }

    private func render(card: StudyCard) {
        glassCardView.configure(with: card)
        glassCardView.setFace(.front, animated: false)
        setDeckButtonTitle(card.deckTitle)
        isAnswerRevealed = false

        glassCardView.isHidden = false
        revealAnswerButton.isHidden = false
        gradePromptLabel.isHidden = true
        gradeStackView.isHidden = true
        emptyStateLabel.isHidden = true
        reloadButton.isHidden = true

        glassCardView.alpha = 0
        glassCardView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        glassCardView.layer.transform = CATransform3DIdentity

        UIView.animate(
            withDuration: 0.42,
            delay: 0,
            usingSpringWithDamping: 0.84,
            initialSpringVelocity: 0.9,
            options: [.allowUserInteraction, .beginFromCurrentState]
        ) { [weak self] in
            self?.glassCardView.alpha = 1
            self?.glassCardView.transform = .identity
        }
    }

    private func showEmptyState(_ message: String) {
        glassCardView.isHidden = true
        revealAnswerButton.isHidden = true
        gradeStackView.isHidden = true
        gradePromptLabel.isHidden = true
        emptyStateLabel.isHidden = false
        reloadButton.isHidden = false
        emptyStateLabel.text = message
    }

    private func updateLoadingState(_ isLoading: Bool) {
        if isLoading {
            loadingIndicator.startAnimating()
            gradeStackView.isUserInteractionEnabled = false
            revealAnswerButton.isEnabled = false
            deckButton.isEnabled = false
        } else {
            loadingIndicator.stopAnimating()
            gradeStackView.isUserInteractionEnabled = true
            revealAnswerButton.isEnabled = true
            deckButton.isEnabled = true
        }
    }

    private func setDeckButtonTitle(_ title: String) {
        var configuration = deckButton.configuration ?? .plain()
        configuration.title = " \(title) "
        deckButton.configuration = configuration
    }

    private func applyDueSummary(_ counts: QueueDueCounts) {
        if counts.total == 0 {
            dueBadgeLabel.text = L10n.tr("home.due.none")
            return
        }
        dueBadgeLabel.text = String(
            format: L10n.tr("home.due.summary"),
            counts.total,
            counts.learning,
            counts.review
        )
    }

    private func presentErrorAlert(message: String) {
        guard presentedViewController == nil else {
            return
        }

        let alert = UIAlertController(title: L10n.tr("home.error.title"), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.tr("home.error.close"), style: .cancel))
        alert.addAction(UIAlertAction(title: L10n.tr("home.error.retry"), style: .default, handler: { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                await self.viewModel.send(.didTapReload)
            }
        }))
        present(alert, animated: true)
    }

    @objc
    private func didTapReloadButton() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            await self.viewModel.send(.didTapReload)
        }
    }

    @objc
    private func didTapGradeButton(_ sender: UIButton) {
        guard isAnswerRevealed, let grade = UserGrade(rawValue: sender.tag) else {
            return
        }

        Task { @MainActor [weak self] in
            guard let self else { return }
            await self.viewModel.send(.didSelectGrade(grade))
        }
    }

    @objc
    private func didTapRevealAnswer() {
        guard !glassCardView.isHidden, !isAnswerRevealed else {
            return
        }
        isAnswerRevealed = true
        glassCardView.setFace(.back, animated: true)
        revealAnswerButton.isHidden = true
        gradePromptLabel.isHidden = false
        gradeStackView.isHidden = false
    }

}
