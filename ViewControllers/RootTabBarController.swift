//
//  RootTabBarController.swift
//  FlashFlow
//
//  Created by bbdyno on 2/11/26.
//

import UIKit

enum AppTheme {
    static let backgroundTop = UIColor(red: 0.05, green: 0.11, blue: 0.21, alpha: 1.0)
    static let backgroundMid = UIColor(red: 0.08, green: 0.18, blue: 0.33, alpha: 1.0)
    static let backgroundBottom = UIColor(red: 0.03, green: 0.07, blue: 0.14, alpha: 1.0)
    static let cardBackground = UIColor.white.withAlphaComponent(0.10)
    static let cardBorder = UIColor.white.withAlphaComponent(0.18)
    static let textPrimary = UIColor.white.withAlphaComponent(0.95)
    static let textSecondary = UIColor.white.withAlphaComponent(0.72)
    static let accent = UIColor(red: 0.23, green: 0.80, blue: 0.87, alpha: 1.0)
    static let accentTeal = UIColor(red: 0.20, green: 0.71, blue: 0.77, alpha: 1.0)
    static let infoBlue = UIColor(red: 0.19, green: 0.52, blue: 0.94, alpha: 1.0)
    static let dangerRed = UIColor(red: 0.86, green: 0.28, blue: 0.28, alpha: 1.0)
    static let gradeAgain = UIColor(red: 0.20, green: 0.27, blue: 0.38, alpha: 1.0)
    static let gradeHard = UIColor(red: 0.21, green: 0.34, blue: 0.47, alpha: 1.0)
    static let gradeGood = UIColor(red: 0.17, green: 0.45, blue: 0.55, alpha: 1.0)
    static let gradeEasy = UIColor(red: 0.15, green: 0.58, blue: 0.64, alpha: 1.0)

    static func applyGradient(to layer: CAGradientLayer) {
        layer.colors = [backgroundTop.cgColor, backgroundMid.cgColor, backgroundBottom.cgColor]
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint = CGPoint(x: 1, y: 1)
    }

    @MainActor
    static func makeNavigationAppearance() -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.titleTextAttributes = [.foregroundColor: textPrimary]
        appearance.largeTitleTextAttributes = [.foregroundColor: textPrimary]
        appearance.backgroundColor = .clear
        return appearance
    }
}

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
        let navigationAppearance = AppTheme.makeNavigationAppearance()
        UINavigationBar.appearance().standardAppearance = navigationAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationAppearance
        UINavigationBar.appearance().compactAppearance = navigationAppearance
        UINavigationBar.appearance().tintColor = AppTheme.textPrimary

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

        let more = MoreViewController(repository: repository)
        let moreNavigation = UINavigationController(rootViewController: more)
        moreNavigation.navigationBar.prefersLargeTitles = true
        moreNavigation.tabBarItem = UITabBarItem(
            title: "More",
            image: UIImage(systemName: "ellipsis.circle"),
            selectedImage: UIImage(systemName: "ellipsis.circle.fill")
        )

        viewControllers = [studyNavigation, decksNavigation, moreNavigation]
        tabBar.tintColor = AppTheme.accent
        tabBar.unselectedItemTintColor = AppTheme.textSecondary
        tabBar.backgroundColor = AppTheme.backgroundTop.withAlphaComponent(0.96)
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
