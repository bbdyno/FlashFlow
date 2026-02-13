import ProjectDescription

let project = Project(
    name: "SharedResources",
    organizationName: "bbdyno",
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
            name: "SharedResources",
            destinations: .iOS,
            product: .framework,
            bundleId: "com.bbdyno.app.flashFlow.sharedresources",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .default,
            sources: [
                "Sources/**"
            ],
            resources: [
                "Resources/**"
            ],
            settings: .settings(
                base: [
                    "SWIFT_STRICT_CONCURRENCY": .string("complete"),
                    "APPLICATION_EXTENSION_API_ONLY": .string("YES")
                ]
            )
        )
    ]
)
