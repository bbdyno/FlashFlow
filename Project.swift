import ProjectDescription

let appName = "FlashFlow"
let bundleId = "com.bbdyno.FlashFlow"
let testBundleId = "com.bbdyno.FlashFlowTests"

let project = Project(
    name: appName,
    organizationName: "bbdyno",
    packages: [
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.7.1")
    ],
    settings: .settings(
        base: [
            "SWIFT_VERSION": "5.9",
            "SWIFT_STRICT_CONCURRENCY": "complete"
        ],
        configurations: [
            .debug(name: "Debug"),
            .release(name: "Release")
        ]
    ),
    targets: [
        .target(
            name: appName,
            destinations: .iOS,
            product: .app,
            bundleId: bundleId,
            deploymentTargets: .iOS("16.0"),
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": .dictionary([:]),
                "UIApplicationSceneManifest": .dictionary([
                    "UIApplicationSupportsMultipleScenes": .boolean(false),
                    "UISceneConfigurations": .dictionary([
                        "UIWindowSceneSessionRoleApplication": .array([
                            .dictionary([
                                "UISceneConfigurationName": .string("Default Configuration"),
                                "UISceneDelegateClassName": .string("$(PRODUCT_MODULE_NAME).SceneDelegate")
                            ])
                        ])
                    ])
                ])
            ]),
            sources: [
                "App/**",
                "Models/**",
                "Services/**",
                "ViewModels/**",
                "Views/**",
                "ViewControllers/**"
            ],
            resources: [
                "Resources/**"
            ],
            scripts: [
                .pre(
                    script: """
                    if test -d "/opt/homebrew/bin"; then
                      export PATH="/opt/homebrew/bin:$PATH"
                    fi

                    if test -d "/usr/local/bin"; then
                      export PATH="/usr/local/bin:$PATH"
                    fi

                    if which swiftlint >/dev/null; then
                      swiftlint lint --config "${SRCROOT}/.swiftlint.yml" --no-cache
                    else
                      echo "warning: SwiftLint not installed. Install with: brew install swiftlint"
                    fi
                    """,
                    name: "SwiftLint"
                )
            ],
            dependencies: [
                .package(product: "SnapKit")
            ],
            settings: .settings(
                base: [
                    "SWIFT_STRICT_CONCURRENCY": "complete"
                ]
            )
        ),
        .target(
            name: "\(appName)Tests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: testBundleId,
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: [
                "Tests/**"
            ],
            dependencies: [
                .target(name: appName)
            ],
            settings: .settings(
                base: [
                    "SWIFT_STRICT_CONCURRENCY": "complete"
                ]
            )
        )
    ]
)
