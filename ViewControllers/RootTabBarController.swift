//
//  RootTabBarController.swift
//  FlashFlow
//
//  Created by bbdyno on 2/11/26.
//

import UIKit

final class RootTabBarController: UITabBarController {
    private let repository: CardRepository
    private var hasCheckedOnboarding = false
    private var isPresentingOnboarding = false

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
        configureTabs()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasCheckedOnboarding else {
            return
        }
        hasCheckedOnboarding = true
        presentOnboardingIfNeeded()
    }

    private func configureTabs() {
        let study = HomeViewController(repository: repository)
        let studyNavigation = UINavigationController(rootViewController: study)
        studyNavigation.navigationBar.isHidden = true
        studyNavigation.tabBarItem = UITabBarItem(
            title: "Study",
            image: UIImage(systemName: "bolt.fill"),
            selectedImage: UIImage(systemName: "bolt.fill")
        )

        let decks = DecksViewController(repository: repository)
        let decksNavigation = UINavigationController(rootViewController: decks)
        decksNavigation.navigationBar.prefersLargeTitles = true
        decksNavigation.tabBarItem = UITabBarItem(
            title: "Decks",
            image: UIImage(systemName: "square.stack.3d.up.fill"),
            selectedImage: UIImage(systemName: "square.stack.3d.up.fill")
        )

        viewControllers = [studyNavigation, decksNavigation]
        tabBar.tintColor = .systemCyan
        tabBar.backgroundColor = UIColor(red: 0.07, green: 0.12, blue: 0.20, alpha: 0.96)
    }

    private func presentOnboardingIfNeeded() {
        guard !isPresentingOnboarding else {
            return
        }

        Task { @MainActor [weak self] in
            guard let self else { return }

            do {
                try await self.repository.prepare()
                let hasAnyDeck = try await self.repository.hasAnyDecks()
                guard !hasAnyDeck else {
                    return
                }

                self.isPresentingOnboarding = true
                let onboarding = OnboardingViewController(repository: self.repository)
                onboarding.onCompleted = { [weak self] in
                    guard let self else { return }
                    NotificationCenter.default.post(name: .deckDataDidChange, object: nil)
                    self.isPresentingOnboarding = false
                }

                let navigation = UINavigationController(rootViewController: onboarding)
                navigation.modalPresentationStyle = .fullScreen
                self.present(navigation, animated: true)
            } catch {
                self.isPresentingOnboarding = false
            }
        }
    }
}
