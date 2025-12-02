// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "passage-mailgun",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        .library(name: "PassageMailgun", targets: ["PassageMailgun"]),
    ],
    dependencies: [
        .package(path: "../vapor-identity"),
        .package(url: "https://github.com/vapor-community/mailgun.git", from: "6.0.1"),
    ],
    targets: [
        .target(
            name: "PassageMailgun",
            dependencies: [
                .product(name: "Passage", package: "vapor-identity"),
                .product(name: "Mailgun", package: "mailgun"),
            ]
        ),
    ]
)
