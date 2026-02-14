//
//  RootTabBarController.swift
//  FlashForge
//
//  Created by bbdyno on 2/11/26.
//

import UIKit

enum AppTheme {
    private static func dynamic(_ light: UIColor, _ dark: UIColor) -> UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? dark : light
        }
    }

    static let backgroundTop = dynamic(
        UIColor(red: 0.93, green: 0.96, blue: 1.00, alpha: 1.0),
        UIColor(red: 0.05, green: 0.11, blue: 0.21, alpha: 1.0)
    )
    static let backgroundMid = dynamic(
        UIColor(red: 0.87, green: 0.92, blue: 0.99, alpha: 1.0),
        UIColor(red: 0.08, green: 0.18, blue: 0.33, alpha: 1.0)
    )
    static let backgroundBottom = dynamic(
        UIColor(red: 0.82, green: 0.89, blue: 0.98, alpha: 1.0),
        UIColor(red: 0.03, green: 0.07, blue: 0.14, alpha: 1.0)
    )

    static let cardBackground = dynamic(
        UIColor.white.withAlphaComponent(0.84),
        UIColor.white.withAlphaComponent(0.10)
    )
    static let cardBorder = dynamic(
        UIColor(red: 0.14, green: 0.24, blue: 0.37, alpha: 0.24),
        UIColor.white.withAlphaComponent(0.18)
    )
    static let textPrimary = dynamic(
        UIColor(red: 0.07, green: 0.14, blue: 0.24, alpha: 0.96),
        UIColor.white.withAlphaComponent(0.95)
    )
    static let textSecondary = dynamic(
        UIColor(red: 0.13, green: 0.23, blue: 0.36, alpha: 0.90),
        UIColor.white.withAlphaComponent(0.72)
    )

    static let accent = dynamic(
        UIColor(red: 0.08, green: 0.56, blue: 0.72, alpha: 1.0),
        UIColor(red: 0.23, green: 0.80, blue: 0.87, alpha: 1.0)
    )
    static let accentTeal = dynamic(
        UIColor(red: 0.06, green: 0.49, blue: 0.58, alpha: 1.0),
        UIColor(red: 0.20, green: 0.71, blue: 0.77, alpha: 1.0)
    )
    static let infoBlue = dynamic(
        UIColor(red: 0.11, green: 0.43, blue: 0.87, alpha: 1.0),
        UIColor(red: 0.19, green: 0.52, blue: 0.94, alpha: 1.0)
    )
    static let dangerRed = dynamic(
        UIColor(red: 0.78, green: 0.20, blue: 0.18, alpha: 1.0),
        UIColor(red: 0.86, green: 0.28, blue: 0.28, alpha: 1.0)
    )

    static let gradeAgain = dynamic(
        UIColor(red: 0.20, green: 0.28, blue: 0.42, alpha: 1.0),
        UIColor(red: 0.20, green: 0.27, blue: 0.38, alpha: 1.0)
    )
    static let gradeHard = dynamic(
        UIColor(red: 0.17, green: 0.36, blue: 0.53, alpha: 1.0),
        UIColor(red: 0.21, green: 0.34, blue: 0.47, alpha: 1.0)
    )
    static let gradeGood = dynamic(
        UIColor(red: 0.10, green: 0.45, blue: 0.56, alpha: 1.0),
        UIColor(red: 0.17, green: 0.45, blue: 0.55, alpha: 1.0)
    )
    static let gradeEasy = dynamic(
        UIColor(red: 0.07, green: 0.50, blue: 0.58, alpha: 1.0),
        UIColor(red: 0.15, green: 0.58, blue: 0.64, alpha: 1.0)
    )

    static let inputBackground = dynamic(
        UIColor.white.withAlphaComponent(0.94),
        UIColor.white.withAlphaComponent(0.06)
    )
    static let glassBorder = dynamic(
        UIColor(red: 0.12, green: 0.22, blue: 0.34, alpha: 0.12),
        UIColor.white.withAlphaComponent(0.20)
    )
    static let glassFill = dynamic(
        UIColor.white.withAlphaComponent(0.62),
        UIColor.white.withAlphaComponent(0.03)
    )
    static let glassHighlightStart = dynamic(
        UIColor.white.withAlphaComponent(0.64),
        UIColor.white.withAlphaComponent(0.34)
    )
    static let glassHighlightMid = dynamic(
        UIColor.white.withAlphaComponent(0.32),
        UIColor.white.withAlphaComponent(0.10)
    )
    static let badgeBackground = dynamic(
        UIColor.white.withAlphaComponent(0.74),
        UIColor.white.withAlphaComponent(0.14)
    )
    static let badgeBorder = dynamic(
        UIColor(red: 0.12, green: 0.22, blue: 0.34, alpha: 0.12),
        UIColor.white.withAlphaComponent(0.22)
    )
    static let shadowColor = dynamic(
        UIColor(red: 0.07, green: 0.16, blue: 0.30, alpha: 0.24),
        UIColor.black.withAlphaComponent(0.55)
    )
    static let tabBarBackground = dynamic(
        UIColor.white.withAlphaComponent(0.90),
        UIColor(red: 0.05, green: 0.11, blue: 0.21, alpha: 0.96)
    )

    static func resolved(_ color: UIColor, for traitCollection: UITraitCollection) -> UIColor {
        color.resolvedColor(with: traitCollection)
    }

    static func buttonFill(from tint: UIColor, for traitCollection: UITraitCollection) -> UIColor {
        let alpha: CGFloat = traitCollection.userInterfaceStyle == .dark ? 0.40 : 0.62
        return resolved(tint, for: traitCollection).withAlphaComponent(alpha)
    }

    static func applyGradient(to layer: CAGradientLayer, traitCollection: UITraitCollection? = nil) {
        let traits = traitCollection ?? UITraitCollection.current
        layer.colors = [
            resolved(backgroundTop, for: traits).cgColor,
            resolved(backgroundMid, for: traits).cgColor,
            resolved(backgroundBottom, for: traits).cgColor
        ]
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
    private enum UITestLaunchArgument {
        static let skipOnboarding = "UITEST_SKIP_ONBOARDING"
    }

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
        applyChromeAppearance()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.hasDifferentColorAppearance(comparedTo: traitCollection) == true else {
            return
        }
        applyChromeAppearance()
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
            title: FlashForgeStrings.Tab.study,
            image: UIImage(systemName: "bolt.fill"),
            selectedImage: UIImage(systemName: "bolt.fill")
        )
        studyNavigation.tabBarItem.accessibilityIdentifier = "tab.study"

        let decks = DecksViewController(repository: repository)
        let decksNavigation = UINavigationController(rootViewController: decks)
        decksNavigation.navigationBar.prefersLargeTitles = true
        decksNavigation.tabBarItem = UITabBarItem(
            title: FlashForgeStrings.Tab.decks,
            image: UIImage(systemName: "square.stack.3d.up.fill"),
            selectedImage: UIImage(systemName: "square.stack.3d.up.fill")
        )
        decksNavigation.tabBarItem.accessibilityIdentifier = "tab.decks"

        let more = MoreViewController(repository: repository)
        let moreNavigation = UINavigationController(rootViewController: more)
        moreNavigation.navigationBar.prefersLargeTitles = true
        moreNavigation.tabBarItem = UITabBarItem(
            title: FlashForgeStrings.Tab.more,
            image: UIImage(systemName: "ellipsis.circle"),
            selectedImage: UIImage(systemName: "ellipsis.circle.fill")
        )
        moreNavigation.tabBarItem.accessibilityIdentifier = "tab.more"

        viewControllers = [studyNavigation, decksNavigation, moreNavigation]
    }

    private func applyChromeAppearance() {
        let navigationAppearance = AppTheme.makeNavigationAppearance()
        viewControllers?
            .compactMap { $0 as? UINavigationController }
            .forEach { navigationController in
                navigationController.navigationBar.standardAppearance = navigationAppearance
                navigationController.navigationBar.scrollEdgeAppearance = navigationAppearance
                navigationController.navigationBar.compactAppearance = navigationAppearance
                navigationController.navigationBar.tintColor = AppTheme.textPrimary
            }

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithTransparentBackground()
        tabAppearance.backgroundColor = AppTheme.tabBarBackground

        let itemAppearances = [
            tabAppearance.stackedLayoutAppearance,
            tabAppearance.inlineLayoutAppearance,
            tabAppearance.compactInlineLayoutAppearance
        ]
        itemAppearances.forEach { appearance in
            appearance.normal.iconColor = AppTheme.textSecondary
            appearance.normal.titleTextAttributes = [.foregroundColor: AppTheme.textSecondary]
            appearance.selected.iconColor = AppTheme.accent
            appearance.selected.titleTextAttributes = [.foregroundColor: AppTheme.accent]
        }

        tabBar.standardAppearance = tabAppearance
        tabBar.scrollEdgeAppearance = tabAppearance
        tabBar.tintColor = AppTheme.accent
        tabBar.unselectedItemTintColor = AppTheme.textSecondary
    }

    private func presentOnboardingIfNeeded() {
        if ProcessInfo.processInfo.arguments.contains(UITestLaunchArgument.skipOnboarding) {
            return
        }

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
                CrashReporter.record(error: error, context: "RootTabBarController.presentOnboardingIfNeeded")
                self.isPresentingOnboarding = false
            }
        }
    }
}
