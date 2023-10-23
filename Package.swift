// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "skip-zip",
    defaultLocalization: "en",
    platforms: [.iOS(.v16), .macOS(.v13), .tvOS(.v16), .watchOS(.v9), .macCatalyst(.v16)],
    products: [
    .library(name: "SkipZip", targets: ["SkipZip"]),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "0.7.1"),
        .package(url: "https://source.skip.tools/skip-foundation.git", from: "0.3.0"),
        .package(url: "https://source.skip.tools/skip-ffi.git", from: "0.1.0"),
    ],
    targets: [
    .target(name: "SkipZip", dependencies: [.product(name: "SkipFoundation", package: "skip-foundation"), .product(name: "SkipFFI", package: "skip-ffi")], plugins: [.plugin(name: "skipstone", package: "skip")]),
    .testTarget(name: "SkipZipTests", dependencies: [
        "SkipZip",
        .product(name: "SkipTest", package: "skip")
    ], plugins: [.plugin(name: "skipstone", package: "skip")]),
    ]
)
