// swift-tools-version: 6.0
// The parts of BRIQ that need no Apple-only framework: the theme, part-category and color tables,
// the bundled-data format and the set-number sort key. It builds and tests on Linux too.

import PackageDescription

let package = Package(
    name: "BRIQKit",
    // The deployment targets of the two app targets in BRIQ.xcodeproj.
    platforms: [.macOS("14.6"), .iOS("18.6")],
    products: [
        .library(name: "BRIQKit", targets: ["BRIQKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/weichsel/ZIPFoundation", .upToNextMajor(from: "0.9.19")),
    ],
    targets: [
        .target(
            name: "BRIQKit",
            dependencies: ["ZIPFoundation"]
        ),
        .testTarget(
            name: "BRIQKitTests",
            dependencies: ["BRIQKit", "ZIPFoundation"]
        ),
    ],
    // The app targets build in the Swift 5 language mode (SWIFT_VERSION = 5.0).
    swiftLanguageModes: [.v5]
)
