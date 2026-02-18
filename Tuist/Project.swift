import ProjectDescription

let appName = "FlashForge"
let bundleId = "com.bbdyno.app.flashFlow"
let testBundleId = "com.bbdyno.app.flashFlowTests"
let marketingVersion = "1.0.1"
let buildNumber = "2026.02.18.1"

let project = Project(
    name: appName,
    organizationName: "bbdyno",
    packages: [
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.7.1"),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "11.0.0")
    ],
    settings: .settings(
        base: [
            "SWIFT_VERSION": "5.9",
            "SWIFT_STRICT_CONCURRENCY": "complete",
            "MARKETING_VERSION": .string(marketingVersion),
            "CURRENT_PROJECT_VERSION": .string(buildNumber)
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
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleShortVersionString": .string(marketingVersion),
                "CFBundleVersion": .string(buildNumber),
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
                "../App/**",
                "../Models/**",
                "../Services/**",
                "../ViewModels/**",
                "../Views/**",
                "../ViewControllers/**"
            ],
            resources: [
                "../Resources/AppAssets.xcassets",
                "../GoogleService-Info.plist"
            ],
            dependencies: [
                .package(product: "SnapKit"),
                .package(product: "FirebaseCore"),
                .package(product: "FirebaseAnalytics"),
                .package(product: "FirebaseCrashlytics")
            ],
            settings: .settings(
                base: [
                    "SWIFT_STRICT_CONCURRENCY": "complete",
                    "MARKETING_VERSION": .string(marketingVersion),
                    "CURRENT_PROJECT_VERSION": .string(buildNumber)
                ]
            )
        ),
        .target(
            name: "\(appName)Tests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: testBundleId,
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleShortVersionString": .string(marketingVersion),
                "CFBundleVersion": .string(buildNumber)
            ]),
            sources: [
                "../Tests/**"
            ],
            dependencies: [
                .target(name: appName)
            ],
            settings: .settings(
                base: [
                    "SWIFT_STRICT_CONCURRENCY": "complete",
                    "MARKETING_VERSION": .string(marketingVersion),
                    "CURRENT_PROJECT_VERSION": .string(buildNumber)
                ]
            )
        )
    ]
)
