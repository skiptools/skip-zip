// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "skip-zip",
    defaultLocalization: "en",
    platforms: [.iOS(.v16), .macOS(.v13), .tvOS(.v16), .watchOS(.v9), .macCatalyst(.v16)],
    products: [
        .library(name: "SkipZip", type: .dynamic, targets: ["SkipZip"]),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "0.8.14"),
        .package(url: "https://source.skip.tools/skip-unit.git", from: "0.6.1"),
        .package(url: "https://source.skip.tools/skip-foundation.git", from: "0.5.7"),
        .package(url: "https://source.skip.tools/skip-ffi.git", from: "0.3.1"),
    ],
    targets: [
        .target(name: "SkipZip", dependencies: [
            "MiniZip",
            .product(name: "SkipFoundation", package: "skip-foundation"),
            .product(name: "SkipFFI", package: "skip-ffi")
        ], plugins: [.plugin(name: "skipstone", package: "skip")]),
        .testTarget(name: "SkipZipTests", dependencies: [
            "SkipZip",
            .product(name: "SkipTest", package: "skip")
        ], resources: [.process("Resources")],
            plugins: [.plugin(name: "skipstone", package: "skip")]),
        .target(name: "MiniZip", dependencies: [
            .product(name: "SkipUnit", package: "skip-unit")
        ], sources: ["src"], cSettings: [
            .define("ZLIB_COMPAT"),
            .define("HAVE_ZLIB"),
            .define("MZ_ZIP_NO_CRYPTO"),
        ], plugins: [.plugin(name: "skipstone", package: "skip")]),
    ]
)
