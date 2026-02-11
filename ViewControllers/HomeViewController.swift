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
    private let algorithmBadgeLabel = UILabel()
    private let dueBadgeLabel = UILabel()
    private let queueSegmentedControl = UISegmentedControl(items: StudyQueue.allCases.map(\.title))
    private let heatmapView = ReviewHeatmapView()
    private let glassCardView = GlassCardView()
    private let gradeStackView = UIStackView()
    private let emptyStateLabel = UILabel()
    private let reloadButton = UIButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    private lazy var panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handleCardPan(_:)))
    private lazy var viewModel: HomeViewModel = {
        let viewModel = HomeViewModel(repository: repository)
        viewModel.bind(output: makeOutput())
        return viewModel
    }()

    private var isSwipeAnimating = false
    private var selectedQueue: StudyQueue = .learning
    private var selectedDeckID: UUID?
    private var deckSummaries: [DeckSummary] = []

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
        configureGestures()
        configureGradeButtons()
        configureNotifications()
        requestInitialData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundGradientLayer.frame = view.bounds
        topGlowView.layer.cornerRadius = topGlowView.bounds.height / 2
        bottomGlowView.layer.cornerRadius = bottomGlowView.bounds.height / 2
    }

    private func makeOutput() -> HomeViewModel.Output {
        HomeViewModel.Output(
            didChangeLoading: { [weak self] isLoading in
                self?.updateLoadingState(isLoading)
            },
            didUpdateDeckSummaries: { [weak self] summaries, selectedDeckID in
                self?.applyDeckSummaries(summaries, selectedDeckID: selectedDeckID)
            },
            didUpdateQueueSelection: { [weak self] queue in
                self?.applyQueueSelection(queue)
            },
            didUpdateSchedulerMode: { [weak self] mode in
                self?.algorithmBadgeLabel.text = mode.shortLabel
            },
            didUpdateQueueCounts: { [weak self] counts in
                self?.dueBadgeLabel.text = "L \(counts.learning) · R \(counts.review)"
            },
            didUpdateCard: { [weak self] card in
                self?.render(card: card)
            },
            didUpdateHeatmap: { [weak self] heatmap in
                self?.heatmapView.update(reviewCountByDate: heatmap, totalDays: 140)
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
        view.addSubview(algorithmBadgeLabel)
        view.addSubview(dueBadgeLabel)
        view.addSubview(queueSegmentedControl)
        view.addSubview(heatmapView)
        view.addSubview(glassCardView)
        view.addSubview(gradeStackView)
        view.addSubview(emptyStateLabel)
        view.addSubview(reloadButton)
        view.addSubview(loadingIndicator)
    }

    private func configureStyle() {
        backgroundGradientLayer.colors = [
            UIColor(red: 0.04, green: 0.10, blue: 0.20, alpha: 1.0).cgColor,
            UIColor(red: 0.10, green: 0.23, blue: 0.40, alpha: 1.0).cgColor,
            UIColor(red: 0.02, green: 0.06, blue: 0.12, alpha: 1.0).cgColor
        ]
        backgroundGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        backgroundGradientLayer.endPoint = CGPoint(x: 1, y: 1)

        topGlowView.backgroundColor = UIColor.systemCyan.withAlphaComponent(0.2)
        topGlowView.layer.shadowColor = UIColor.systemCyan.cgColor
        topGlowView.layer.shadowOpacity = 0.28
        topGlowView.layer.shadowRadius = 52
        topGlowView.layer.shadowOffset = .zero

        bottomGlowView.backgroundColor = UIColor.systemMint.withAlphaComponent(0.15)
        bottomGlowView.layer.shadowColor = UIColor.systemMint.cgColor
        bottomGlowView.layer.shadowOpacity = 0.28
        bottomGlowView.layer.shadowRadius = 52
        bottomGlowView.layer.shadowOffset = .zero

        titleLabel.text = "FlashFlow"
        titleLabel.font = UIFont(name: "AvenirNext-Bold", size: 34) ?? .systemFont(ofSize: 34, weight: .bold)
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.96)

        deckButton.configuration = .plain()
        deckButton.configuration?.image = UIImage(systemName: "chevron.down")
        deckButton.configuration?.imagePlacement = .trailing
        deckButton.configuration?.imagePadding = 6
        deckButton.configuration?.baseForegroundColor = .white
        deckButton.titleLabel?.font = UIFont(name: "AvenirNext-DemiBold", size: 14) ?? .systemFont(ofSize: 14, weight: .semibold)
        deckButton.layer.cornerRadius = 12
        deckButton.layer.cornerCurve = .continuous
        deckButton.layer.borderWidth = 1
        deckButton.layer.borderColor = UIColor.white.withAlphaComponent(0.20).cgColor
        deckButton.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        deckButton.showsMenuAsPrimaryAction = true
        setDeckButtonTitle("덱 선택")

        algorithmBadgeLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 12) ?? .systemFont(ofSize: 12, weight: .semibold)
        algorithmBadgeLabel.textColor = UIColor.white.withAlphaComponent(0.92)
        algorithmBadgeLabel.textAlignment = .center
        algorithmBadgeLabel.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.28)
        algorithmBadgeLabel.layer.cornerRadius = 14
        algorithmBadgeLabel.layer.cornerCurve = .continuous
        algorithmBadgeLabel.layer.borderWidth = 1
        algorithmBadgeLabel.layer.borderColor = UIColor.white.withAlphaComponent(0.20).cgColor
        algorithmBadgeLabel.clipsToBounds = true
        algorithmBadgeLabel.text = "SM-2"

        dueBadgeLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 13) ?? .systemFont(ofSize: 13, weight: .semibold)
        dueBadgeLabel.textColor = UIColor.white.withAlphaComponent(0.92)
        dueBadgeLabel.textAlignment = .center
        dueBadgeLabel.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        dueBadgeLabel.layer.cornerRadius = 14
        dueBadgeLabel.layer.cornerCurve = .continuous
        dueBadgeLabel.layer.borderWidth = 1
        dueBadgeLabel.layer.borderColor = UIColor.white.withAlphaComponent(0.20).cgColor
        dueBadgeLabel.clipsToBounds = true
        dueBadgeLabel.text = "L 0 · R 0"

        queueSegmentedControl.selectedSegmentIndex = selectedQueue.rawValue
        queueSegmentedControl.selectedSegmentTintColor = UIColor.white.withAlphaComponent(0.24)
        queueSegmentedControl.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        queueSegmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        queueSegmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        queueSegmentedControl.addTarget(self, action: #selector(didChangeQueueSegment(_:)), for: .valueChanged)

        gradeStackView.axis = .horizontal
        gradeStackView.alignment = .fill
        gradeStackView.distribution = .fillEqually
        gradeStackView.spacing = 10

        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 3
        emptyStateLabel.font = UIFont(name: "AvenirNext-DemiBold", size: 18) ?? .systemFont(ofSize: 18, weight: .semibold)
        emptyStateLabel.textColor = UIColor.white.withAlphaComponent(0.90)
        emptyStateLabel.isHidden = true

        reloadButton.setTitle("새로고침", for: .normal)
        reloadButton.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 15) ?? .systemFont(ofSize: 15, weight: .bold)
        reloadButton.setTitleColor(.white, for: .normal)
        reloadButton.backgroundColor = UIColor.white.withAlphaComponent(0.16)
        reloadButton.layer.cornerRadius = 14
        reloadButton.layer.cornerCurve = .continuous
        reloadButton.layer.borderWidth = 1
        reloadButton.layer.borderColor = UIColor.white.withAlphaComponent(0.20).cgColor
        reloadButton.isHidden = true
        reloadButton.addTarget(self, action: #selector(didTapReloadButton), for: .touchUpInside)

        loadingIndicator.color = UIColor.white.withAlphaComponent(0.90)
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
        }

        dueBadgeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(titleLabel)
            make.trailing.equalToSuperview().inset(24)
            make.height.equalTo(30)
            make.width.greaterThanOrEqualTo(104)
        }

        algorithmBadgeLabel.snp.makeConstraints { make in
            make.centerY.equalTo(dueBadgeLabel)
            make.trailing.equalTo(dueBadgeLabel.snp.leading).offset(-8)
            make.height.equalTo(30)
            make.width.greaterThanOrEqualTo(72)
        }

        deckButton.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(10)
            make.leading.equalToSuperview().inset(24)
            make.height.equalTo(32)
            make.width.greaterThanOrEqualTo(120)
        }

        queueSegmentedControl.snp.makeConstraints { make in
            make.centerY.equalTo(deckButton)
            make.trailing.equalToSuperview().inset(24)
            make.leading.greaterThanOrEqualTo(deckButton.snp.trailing).offset(12)
            make.width.equalTo(210)
            make.height.equalTo(32)
        }

        heatmapView.snp.makeConstraints { make in
            make.top.equalTo(deckButton.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(162)
        }

        glassCardView.snp.makeConstraints { make in
            make.top.equalTo(heatmapView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(glassCardView.snp.width).multipliedBy(1.1)
        }

        gradeStackView.snp.makeConstraints { make in
            make.top.equalTo(glassCardView.snp.bottom).offset(14)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(44)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).inset(12)
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

    private func configureGestures() {
        glassCardView.addGestureRecognizer(panGestureRecognizer)
    }

    private func configureGradeButtons() {
        let configs: [(title: String, grade: UserGrade, tint: UIColor)] = [
            ("Again", .again, UIColor(red: 0.96, green: 0.39, blue: 0.40, alpha: 0.95)),
            ("Hard", .hard, UIColor(red: 0.97, green: 0.66, blue: 0.31, alpha: 0.95)),
            ("Good", .good, UIColor(red: 0.35, green: 0.80, blue: 0.46, alpha: 0.95)),
            ("Easy", .easy, UIColor(red: 0.20, green: 0.72, blue: 0.78, alpha: 0.95))
        ]

        configs.forEach { config in
            let button = UIButton(type: .system)
            button.setTitle(config.title, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 14) ?? .systemFont(ofSize: 14, weight: .bold)
            button.backgroundColor = config.tint.withAlphaComponent(0.78)
            button.layer.cornerRadius = 12
            button.layer.cornerCurve = .continuous
            button.layer.borderWidth = 1
            button.layer.borderColor = UIColor.white.withAlphaComponent(0.16).cgColor
            button.tag = config.grade.rawValue
            button.addTarget(self, action: #selector(didTapGradeButton(_:)), for: .touchUpInside)
            gradeStackView.addArrangedSubview(button)
        }
    }

    private func configureNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleDeckDataDidChange), name: .deckDataDidChange, object: nil)
    }

    private func requestInitialData() {
        // ViewModel은 @MainActor로 격리되어 있어 Task 경계에서도 UI 상태 갱신이 안전합니다.
        Task { @MainActor [weak self] in
            guard let self else { return }
            await self.viewModel.send(.viewDidLoad)
        }
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
            setDeckButtonTitle("덱 선택")
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
        deckButton.menu = UIMenu(title: "덱 선택", children: actions)
    }

    private func applyQueueSelection(_ queue: StudyQueue) {
        selectedQueue = queue
        queueSegmentedControl.selectedSegmentIndex = queue.rawValue
    }

    private func render(card: StudyCard) {
        glassCardView.configure(with: card)
        setDeckButtonTitle(card.deckTitle)

        glassCardView.isHidden = false
        gradeStackView.isHidden = false
        emptyStateLabel.isHidden = true
        reloadButton.isHidden = true
        panGestureRecognizer.isEnabled = true

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
        gradeStackView.isHidden = true
        emptyStateLabel.isHidden = false
        reloadButton.isHidden = false
        panGestureRecognizer.isEnabled = false
        emptyStateLabel.text = message
    }

    private func updateLoadingState(_ isLoading: Bool) {
        if isLoading {
            loadingIndicator.startAnimating()
            panGestureRecognizer.isEnabled = false
            gradeStackView.isUserInteractionEnabled = false
            queueSegmentedControl.isEnabled = false
            deckButton.isEnabled = false
        } else {
            loadingIndicator.stopAnimating()
            gradeStackView.isUserInteractionEnabled = true
            queueSegmentedControl.isEnabled = true
            deckButton.isEnabled = true
            if !glassCardView.isHidden {
                panGestureRecognizer.isEnabled = true
            }
        }
    }

    private func setDeckButtonTitle(_ title: String) {
        var configuration = deckButton.configuration ?? .plain()
        configuration.title = " \(title) "
        deckButton.configuration = configuration
    }

    private func presentErrorAlert(message: String) {
        guard presentedViewController == nil else {
            return
        }

        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "닫기", style: .cancel))
        alert.addAction(UIAlertAction(title: "재시도", style: .default, handler: { [weak self] _ in
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
        guard let grade = UserGrade(rawValue: sender.tag), !isSwipeAnimating else {
            return
        }

        Task { @MainActor [weak self] in
            guard let self else { return }
            await self.viewModel.send(.didSelectGrade(grade))
        }
    }

    @objc
    private func didChangeQueueSegment(_ sender: UISegmentedControl) {
        guard let queue = StudyQueue(rawValue: sender.selectedSegmentIndex) else {
            return
        }
        Task { @MainActor [weak self] in
            guard let self else { return }
            await self.viewModel.send(.didSelectQueue(queue))
        }
    }

    @objc
    private func handleCardPan(_ recognizer: UIPanGestureRecognizer) {
        guard !glassCardView.isHidden, !isSwipeAnimating else {
            return
        }

        let translation = recognizer.translation(in: view)
        let velocity = recognizer.velocity(in: view)

        switch recognizer.state {
        case .changed:
            glassCardView.applyDragTranslation(translation, in: view.bounds)
        case .ended, .cancelled, .failed:
            let threshold = view.bounds.width * 0.23
            guard abs(translation.x) >= threshold else {
                glassCardView.resetTransformWithSpring(velocity: velocity)
                return
            }

            let direction: SwipeDirection = translation.x > 0 ? .right : .left
            animateSwipeDismiss(direction: direction, velocity: velocity)
        default:
            break
        }
    }

    private func animateSwipeDismiss(direction: SwipeDirection, velocity: CGPoint) {
        isSwipeAnimating = true

        let horizontalOffset = direction == .right ? view.bounds.width * 1.35 : -view.bounds.width * 1.35
        let rotation: CGFloat = direction == .right ? 0.2 : -0.2

        UIView.animate(
            withDuration: 0.28,
            delay: 0,
            options: [.allowUserInteraction, .curveEaseIn]
        ) { [weak self] in
            guard let self else { return }
            self.glassCardView.transform = CGAffineTransform(translationX: horizontalOffset, y: velocity.y * 0.05).rotated(by: rotation)
            self.glassCardView.layer.transform = CATransform3DIdentity
            self.glassCardView.alpha = 0
        } completion: { [weak self] _ in
            guard let self else { return }
            self.glassCardView.transform = .identity
            self.glassCardView.layer.transform = CATransform3DIdentity
            self.glassCardView.alpha = 1
            self.isSwipeAnimating = false

            Task { @MainActor [weak self] in
                guard let self else { return }
                await self.viewModel.send(.didSwipeCard(direction))
            }
        }
    }
}
