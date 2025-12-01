// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "vapor-identity-email-mailgun",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "IdentityMailgun", targets: ["IdentityMailgun"]),
    ],
    dependencies: [
        .package(url: "https://github.com/rozd/vapor-identity.git", from: "1.0.0"),
        .package(url: "https://github.com/vapor-community/VaporMailgunService.git", from: "4.0.0"),
    ],
    targets: [
        .target(
            name: "IdentityMailgun",
            dependencies: [
                .product(name: "Identity", package: "vapor-identity"),
                .product(name: "Mailgun", package: "VaporMailgunService"),
            ]
        ),
    ]
)
