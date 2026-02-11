//
//  OnboardingViewController.swift
//  FlashFlow
//
//  Created by bbdyno on 2/11/26.
//

import UIKit
import SnapKit

final class OnboardingViewController: UIViewController {
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
        view.backgroundColor = .black
        navigationItem.hidesBackButton = true

        backgroundGradientLayer.colors = [
            UIColor(red: 0.04, green: 0.10, blue: 0.20, alpha: 1.0).cgColor,
            UIColor(red: 0.07, green: 0.18, blue: 0.32, alpha: 1.0).cgColor,
            UIColor(red: 0.02, green: 0.05, blue: 0.11, alpha: 1.0).cgColor
        ]
        backgroundGradientLayer.startPoint = CGPoint(x: 0, y: 0)
        backgroundGradientLayer.endPoint = CGPoint(x: 1, y: 1)

        titleLabel.text = "FlashFlow에 오신 것을 환영합니다"
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2
        titleLabel.font = UIFont(name: "AvenirNext-Bold", size: 30) ?? .systemFont(ofSize: 30, weight: .bold)

        subtitleLabel.text = "첫 덱과 첫 카드를 만들면 바로 학습을 시작할 수 있습니다."
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.82)
        subtitleLabel.numberOfLines = 2
        subtitleLabel.font = UIFont(name: "AvenirNext-Medium", size: 16) ?? .systemFont(ofSize: 16, weight: .medium)

        [deckField, frontField, backField, noteField].forEach { field in
            field.borderStyle = .roundedRect
            field.backgroundColor = UIColor.white.withAlphaComponent(0.9)
            field.autocapitalizationType = .sentences
            field.clearButtonMode = .whileEditing
            field.layer.cornerRadius = 12
        }

        deckField.placeholder = "덱 이름 (예: iOS)"
        frontField.placeholder = "첫 카드 앞면"
        backField.placeholder = "첫 카드 뒷면"
        noteField.placeholder = "노트 (선택)"

        startButton.setTitle("첫 덱 생성하기", for: .normal)
        startButton.setTitleColor(.white, for: .normal)
        startButton.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 16) ?? .systemFont(ofSize: 16, weight: .bold)
        startButton.backgroundColor = UIColor.systemCyan.withAlphaComponent(0.82)
        startButton.layer.cornerRadius = 14
        startButton.layer.cornerCurve = .continuous
        startButton.addTarget(self, action: #selector(didTapStart), for: .touchUpInside)

        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = .white

        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(deckField)
        view.addSubview(frontField)
        view.addSubview(backField)
        view.addSubview(noteField)
        view.addSubview(startButton)
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

        loadingIndicator.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(16)
        }
    }

    @objc
    private func didTapStart() {
        setLoading(true)
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.setLoading(false) }

            do {
                try await self.repository.prepare()
                let deck = try await self.repository.createDeck(title: self.deckField.text ?? "")
                _ = try await self.repository.addCard(
                    to: deck.id,
                    front: self.frontField.text ?? "",
                    back: self.backField.text ?? "",
                    note: self.noteField.text ?? ""
                )
                self.onCompleted?()
                self.dismiss(animated: true)
            } catch {
                self.presentError(message: Self.userFacingMessage(from: error))
            }
        }
    }

    private func setLoading(_ isLoading: Bool) {
        if isLoading {
            loadingIndicator.startAnimating()
        } else {
            loadingIndicator.stopAnimating()
        }

        [deckField, frontField, backField, noteField, startButton].forEach { $0.isUserInteractionEnabled = !isLoading }
    }

    private func presentError(message: String) {
        guard presentedViewController == nil else {
            return
        }

        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .cancel))
        present(alert, animated: true)
    }

    private static func userFacingMessage(from error: Error) -> String {
        if let localized = error as? LocalizedError,
           let description = localized.errorDescription,
           !description.isEmpty {
            return description
        }
        return "온보딩 처리 중 오류가 발생했습니다."
    }
}
