// swift-tools-version:6.2
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
        .package(url: "https://github.com/vapor-community/passage.git", from: "0.0.3"),
        .package(url: "https://github.com/vapor-community/mailgun.git", from: "6.0.1"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.119.0"),
    ],
    targets: [
        .target(
            name: "PassageMailgun",
            dependencies: [
                .product(name: "Passage", package: "passage"),
                .product(name: "Mailgun", package: "mailgun"),
            ]
        ),
        .testTarget(
            name: "PassageMailgunTests",
            dependencies: [
                "PassageMailgun",
                .product(name: "VaporTesting", package: "vapor"),
            ]
        ),
    ]
)
