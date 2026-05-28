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
        // MARK: - Base
        .library(name: "Set Ordered Primitive", targets: ["Set Ordered Primitive"]),
        .library(name: "Set Ordered Primitives", targets: ["Set Ordered Primitives"]),

        // MARK: - Fixed variant
        .library(name: "Set Ordered Fixed Primitive", targets: ["Set Ordered Fixed Primitive"]),
        .library(name: "Set Ordered Fixed Primitives", targets: ["Set Ordered Fixed Primitives"]),

        // MARK: - Static variant
        .library(name: "Set Ordered Static Primitive", targets: ["Set Ordered Static Primitive"]),
        .library(name: "Set Ordered Static Primitives", targets: ["Set Ordered Static Primitives"]),

        // MARK: - Small variant
        .library(name: "Set Ordered Small Primitive", targets: ["Set Ordered Small Primitive"]),
        .library(name: "Set Ordered Small Primitives", targets: ["Set Ordered Small Primitives"]),

        // MARK: - Test Support
        .library(name: "Set Ordered Primitives Test Support", targets: ["Set Ordered Primitives Test Support"]),
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

        // MARK: - Base type (Set.Ordered dynamic/heap + error enums)
        .target(
            name: "Set Ordered Primitive",
            dependencies: [
                .product(name: "Set Primitives", package: "swift-set-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Hash Table Primitives", package: "swift-hash-table-primitives"),
                .product(name: "Buffer Linear Primitive", package: "swift-buffer-linear-primitives"),
                .product(name: "Buffer Linear Primitives", package: "swift-buffer-linear-primitives"),
                // [MOD-036] refined-C: the hot operation surface (insert/remove/
                // algebra/indexed/builder) co-located here imports these.
                .product(name: "Ordinal Primitives", package: "swift-ordinal-primitives"),
                .product(name: "Cardinal Primitives", package: "swift-cardinal-primitives"),
            ]
        ),

        // MARK: - Fixed type
        .target(
            name: "Set Ordered Fixed Primitive",
            dependencies: [
                "Set Ordered Primitive",
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Hash Table Primitives", package: "swift-hash-table-primitives"),
                .product(name: "Buffer Linear Bounded Primitive", package: "swift-buffer-linear-primitives"),
                .product(name: "Buffer Linear Bounded Primitives", package: "swift-buffer-linear-primitives"),
                // [MOD-036] refined-C: the hot operation surface (insert/remove/
                // indexed/iteration witnesses) co-located here imports these.
                .product(name: "Ordinal Primitives", package: "swift-ordinal-primitives"),
                .product(name: "Cardinal Primitives", package: "swift-cardinal-primitives"),
            ]
        ),

        // MARK: - Static type
        .target(
            name: "Set Ordered Static Primitive",
            dependencies: [
                "Set Ordered Primitive",
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Hash Table Primitives", package: "swift-hash-table-primitives"),
                .product(name: "Buffer Linear Primitive", package: "swift-buffer-linear-primitives"),
                .product(name: "Buffer Linear Inline Primitives", package: "swift-buffer-linear-primitives"),
                // [MOD-036] refined-C: the hot operation surface (insert/remove/
                // bounded-index access/iteration witnesses) co-located here imports these.
                .product(name: "Ordinal Primitives", package: "swift-ordinal-primitives"),
                .product(name: "Finite Primitives", package: "swift-finite-primitives"),
            ]
        ),

        // MARK: - Small type
        .target(
            name: "Set Ordered Small Primitive",
            dependencies: [
                "Set Ordered Primitive",
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Hash Table Primitives", package: "swift-hash-table-primitives"),
                .product(name: "Buffer Linear Primitive", package: "swift-buffer-linear-primitives"),
                .product(name: "Buffer Linear Small Primitive", package: "swift-buffer-linear-primitives"),
                .product(name: "Buffer Linear Small Primitives", package: "swift-buffer-linear-primitives"),
            ]
        ),

        // MARK: - Fixed ops
        .target(
            name: "Set Ordered Fixed Primitives",
            dependencies: [
                "Set Ordered Fixed Primitive",
                "Set Ordered Primitive",
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Buffer Linear Bounded Primitive", package: "swift-buffer-linear-primitives"),
                .product(name: "Buffer Linear Bounded Primitives", package: "swift-buffer-linear-primitives"),
                .product(name: "Sequence Primitives", package: "swift-sequence-primitives"),
                .product(name: "Iterable", package: "swift-iterator-primitives"),
                .product(name: "Iterator Chunk Primitives", package: "swift-iterator-primitives"),
                .product(name: "Property Primitives", package: "swift-property-primitives"),
                .product(name: "Ordinal Primitives", package: "swift-ordinal-primitives"),
                .product(name: "Cardinal Primitives", package: "swift-cardinal-primitives"),
            ]
        ),

        // MARK: - Static ops
        .target(
            name: "Set Ordered Static Primitives",
            dependencies: [
                "Set Ordered Static Primitive",
                "Set Ordered Primitive",
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Buffer Linear Primitive", package: "swift-buffer-linear-primitives"),
                .product(name: "Buffer Linear Inline Primitives", package: "swift-buffer-linear-primitives"),
                .product(name: "Sequence Primitives", package: "swift-sequence-primitives"),
                .product(name: "Iterable", package: "swift-iterator-primitives"),
                .product(name: "Iterator Chunk Primitives", package: "swift-iterator-primitives"),
                .product(name: "Property Primitives", package: "swift-property-primitives"),
                .product(name: "Cardinal Primitives", package: "swift-cardinal-primitives"),
            ]
        ),

        // MARK: - Small ops
        .target(
            name: "Set Ordered Small Primitives",
            dependencies: [
                "Set Ordered Small Primitive",
                "Set Ordered Primitive",
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Buffer Linear Primitive", package: "swift-buffer-linear-primitives"),
                .product(name: "Buffer Linear Small Primitive", package: "swift-buffer-linear-primitives"),
                .product(name: "Buffer Linear Small Primitives", package: "swift-buffer-linear-primitives"),
                .product(name: "Sequence Primitives", package: "swift-sequence-primitives"),
                .product(name: "Iterable", package: "swift-iterator-primitives"),
                .product(name: "Iterator Chunk Primitives", package: "swift-iterator-primitives"),
                .product(name: "Property Primitives", package: "swift-property-primitives"),
                .product(name: "Ordinal Primitives", package: "swift-ordinal-primitives"),
                .product(name: "Cardinal Primitives", package: "swift-cardinal-primitives"),
            ]
        ),

        // MARK: - Base ops + Umbrella ([MOD-005] dual-role: base conformances + re-export of all variants)
        .target(
            name: "Set Ordered Primitives",
            dependencies: [
                "Set Ordered Primitive",
                "Set Ordered Fixed Primitives",
                "Set Ordered Static Primitives",
                "Set Ordered Small Primitives",
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Buffer Linear Primitive", package: "swift-buffer-linear-primitives"),
                .product(name: "Buffer Linear Primitives", package: "swift-buffer-linear-primitives"),
                .product(name: "Sequence Primitives", package: "swift-sequence-primitives"),
                .product(name: "Iterable", package: "swift-iterator-primitives"),
                .product(name: "Iterator Chunk Primitives", package: "swift-iterator-primitives"),
                .product(name: "Property Primitives", package: "swift-property-primitives"),
                .product(name: "Ordinal Primitives", package: "swift-ordinal-primitives"),
                .product(name: "Cardinal Primitives", package: "swift-cardinal-primitives"),
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
