// swift-tools-version: 6.3.1

import PackageDescription

let package = Package(
    name: "swift-set-ordered-primitives",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        .library(
            name: "Set Ordered Primitives",
            targets: ["Set Ordered Primitives"]
        ),
        .library(
            name: "Set Ordered Primitive",
            targets: ["Set Ordered Primitive"]
        ),
        .library(
            name: "Set Ordered Primitives Test Support",
            targets: ["Set Ordered Primitives Test Support"]
        ),
    ],
    dependencies: [
        .package(path: "../swift-set-primitives"),
        .package(path: "../swift-bit-primitives"),
        .package(path: "../swift-index-primitives"),
        .package(path: "../swift-hash-table-primitives"),
        .package(path: "../swift-buffer-primitives"),
        .package(path: "../swift-buffer-linear-primitives"),
        .package(path: "../swift-sequence-primitives"),
        .package(path: "../swift-iterator-primitives"),
        .package(path: "../swift-property-primitives"),
        .package(path: "../swift-ordinal-primitives"),
        .package(path: "../swift-cardinal-primitives"),
        .package(path: "../swift-finite-primitives"),
    ],
    targets: [

        // MARK: - Type (ordered-set type surface: Ordered + Fixed/Static/Small)
        .target(
            name: "Set Ordered Primitive",
            dependencies: [
                .product(name: "Set Primitives Core", package: "swift-set-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Hash Table Primitives", package: "swift-hash-table-primitives"),
                .product(name: "Buffer Linear Primitive", package: "swift-buffer-linear-primitives"),
                .product(name: "Buffer Linear Primitives", package: "swift-buffer-linear-primitives"),
                .product(name: "Buffer Linear Bounded Primitive", package: "swift-buffer-linear-primitives"),
                .product(name: "Buffer Linear Bounded Primitives", package: "swift-buffer-linear-primitives"),
                .product(name: "Buffer Linear Inline Primitives", package: "swift-buffer-linear-primitives"),
                .product(name: "Buffer Linear Small Primitive", package: "swift-buffer-linear-primitives"),
                .product(name: "Buffer Linear Small Primitives", package: "swift-buffer-linear-primitives"),
            ]
        ),

        // MARK: - Ordered (operations / conformances over the ordered-set types)
        .target(
            name: "Set Ordered Primitives",
            dependencies: [
                "Set Ordered Primitive",
                .product(name: "Set Primitives Core", package: "swift-set-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Hash Table Primitives", package: "swift-hash-table-primitives"),
                .product(name: "Buffer Linear Primitive", package: "swift-buffer-linear-primitives"),
                .product(name: "Buffer Linear Primitives", package: "swift-buffer-linear-primitives"),
                .product(name: "Buffer Linear Bounded Primitive", package: "swift-buffer-linear-primitives"),
                .product(name: "Buffer Linear Bounded Primitives", package: "swift-buffer-linear-primitives"),
                .product(name: "Buffer Linear Inline Primitives", package: "swift-buffer-linear-primitives"),
                .product(name: "Buffer Linear Small Primitive", package: "swift-buffer-linear-primitives"),
                .product(name: "Buffer Linear Small Primitives", package: "swift-buffer-linear-primitives"),
                .product(name: "Ordinal Primitives", package: "swift-ordinal-primitives"),
                .product(name: "Cardinal Primitives", package: "swift-cardinal-primitives"),
                .product(name: "Sequence Primitives", package: "swift-sequence-primitives"),
                .product(name: "Iterator Primitives", package: "swift-iterator-primitives"),
                .product(name: "Property Primitives", package: "swift-property-primitives"),
                .product(name: "Finite Primitives", package: "swift-finite-primitives"),
            ]
        ),

        // MARK: - Test Support
        .target(
            name: "Set Ordered Primitives Test Support",
            dependencies: [
                "Set Ordered Primitives",
                .product(name: "Bit Primitives Test Support", package: "swift-bit-primitives"),
                .product(name: "Index Primitives Test Support", package: "swift-index-primitives"),
                .product(name: "Buffer Primitives Test Support", package: "swift-buffer-primitives"),
            ],
            path: "Tests/Support"
        ),

        // MARK: - Tests
        .testTarget(
            name: "Set Ordered Primitives Tests",
            dependencies: [
                "Set Ordered Primitives",
                "Set Ordered Primitives Test Support",
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
