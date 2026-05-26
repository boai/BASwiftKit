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
    dependencies: [
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.7.0")
    ],
    targets: [
        .target(
            name: "BASwiftKit",
            dependencies: ["SnapKit"],
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
