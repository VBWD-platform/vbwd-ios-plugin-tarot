// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "VBWDTarotPlugin",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(name: "TarotPlugin", targets: ["TarotPlugin"]),
    ],
    dependencies: [
        .package(path: "../vbwd-ios-core"),
    ],
    targets: [
        .target(
            name: "TarotPlugin",
            dependencies: [
                .product(name: "VBWDCore", package: "vbwd-ios-core"),
            ],
            path: "Sources/TarotPlugin",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
