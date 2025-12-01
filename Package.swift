// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "vapor-identity-email-mailgun",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(name: "IdentityMailgun", targets: ["IdentityMailgun"]),
    ],
    dependencies: [
        .package(path: "../vapor-identity"),
        .package(url: "https://github.com/vapor-community/mailgun.git", from: "6.0.1"),
    ],
    targets: [
        .target(
            name: "IdentityMailgun",
            dependencies: [
                .product(name: "Identity", package: "vapor-identity"),
                .product(name: "Mailgun", package: "mailgun"),
            ]
        ),
    ]
)
