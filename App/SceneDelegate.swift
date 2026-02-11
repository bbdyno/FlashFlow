//
//  SceneDelegate.swift
//  FlashFlow
//
//  Created by bbdyno on 2/11/26.
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private let repository = CardRepository()

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = RootTabBarController(repository: repository)
        window.makeKeyAndVisible()
        self.window = window
    }
}
