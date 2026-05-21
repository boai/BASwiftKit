// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "BASwiftKit",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "BASwiftKit",
            targets: ["BASwiftKit"]
        )
    ],
    targets: [
        .target(
            name: "BASwiftKit",
            path: "Sources/BASwiftKit"
        ),
        .testTarget(
            name: "BASwiftKitTests",
            dependencies: ["BASwiftKit"],
            path: "Tests/BASwiftKitTests"
        )
    ],
    swiftLanguageVersions: [.v5]
)
