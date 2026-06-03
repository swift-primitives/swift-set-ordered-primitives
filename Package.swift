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
        .package(path: "../swift-memory-primitives--w2"),
        .package(path: "../swift-span-primitives"),
        .package(path: "../swift-memory-iterator-primitives--w2"),
        .package(url: "https://github.com/swift-primitives/swift-set-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-bit-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-index-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-hash-table-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-hash-primitives.git", branch: "main"),
        // W2 mesh: buffer packages on their --w2 worktrees so every path to memory
        // unifies on identity swift-memory-primitives--w2 (collision resolved).
        .package(path: "../swift-buffer-primitives--w2"),
        .package(path: "../swift-buffer-linear-primitives--w2"),
        .package(url: "https://github.com/swift-primitives/swift-sequence-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-iterator-primitives.git", branch: "main"),
        // The build capability: growable variants conform builder-primitives'
        // generic `Buildable` (Initiable init() + add) for the free `{ … }` DSL;
        // bounded variants drain its shared @Builder / Buffer<Element>.Linear
        // accumulator. There is no set-specific Set.Buildable.Protocol/Set.Builder.
        .package(url: "https://github.com/swift-primitives/swift-builder-primitives.git", branch: "main"),
        // NOTE: swift-set-algebra-primitives is intentionally NOT a dependency of
        // this package (library OR tests). The ordered-set discipline and the set
        // algebra are orthogonal, mutually-independent concerns (set-builder ⊥
        // set-algebra ⊥ set-ordered); algebra is tested in its own package against
        // a buildable fixture, and composed at the consumer (import both packages).
        .package(url: "https://github.com/swift-primitives/swift-property-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-ordinal-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-cardinal-primitives.git", branch: "main"),
        .package(url: "https://github.com/swift-primitives/swift-finite-primitives.git", branch: "main"),
    ],
    targets: [

        // MARK: - Base type (Set.Ordered dynamic/heap + error enums)
        .target(
            name: "Set Ordered Primitive",
            dependencies: [
                .product(name: "Span Protocol Primitives", package: "swift-span-primitives"),
                .product(name: "Set Primitives", package: "swift-set-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Hash Table Primitives", package: "swift-hash-table-primitives"),
                .product(name: "Buffer Linear Primitive", package: "swift-buffer-linear-primitives--w2"),
                .product(name: "Buffer Linear Primitives", package: "swift-buffer-linear-primitives--w2"),
                .product(name: "Ordinal Primitives", package: "swift-ordinal-primitives"),
                .product(name: "Cardinal Primitives", package: "swift-cardinal-primitives"),
            ]
        ),

        // MARK: - Fixed type
        .target(
            name: "Set Ordered Fixed Primitive",
            dependencies: [
                "Set Ordered Primitive",
                .product(name: "Span Protocol Primitives", package: "swift-span-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Hash Table Primitives", package: "swift-hash-table-primitives"),
                .product(name: "Buffer Linear Bounded Primitive", package: "swift-buffer-linear-primitives--w2"),
                .product(name: "Buffer Linear Bounded Primitives", package: "swift-buffer-linear-primitives--w2"),
                .product(name: "Ordinal Primitives", package: "swift-ordinal-primitives"),
                .product(name: "Cardinal Primitives", package: "swift-cardinal-primitives"),
            ]
        ),

        // MARK: - Static type
        .target(
            name: "Set Ordered Static Primitive",
            dependencies: [
                "Set Ordered Primitive",
                .product(name: "Span Protocol Primitives", package: "swift-span-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Hash Table Static Primitives", package: "swift-hash-table-primitives"),
                .product(name: "Buffer Linear Primitive", package: "swift-buffer-linear-primitives--w2"),
                .product(name: "Buffer Linear Inline Primitives", package: "swift-buffer-linear-primitives--w2"),
                .product(name: "Ordinal Primitives", package: "swift-ordinal-primitives"),
                .product(name: "Finite Primitives", package: "swift-finite-primitives"),
            ]
        ),

        // MARK: - Small type
        .target(
            name: "Set Ordered Small Primitive",
            dependencies: [
                "Set Ordered Primitive",
                .product(name: "Span Protocol Primitives", package: "swift-span-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Hash Table Primitives", package: "swift-hash-table-primitives"),
                .product(name: "Buffer Linear Primitive", package: "swift-buffer-linear-primitives--w2"),
                .product(name: "Buffer Linear Small Primitive", package: "swift-buffer-linear-primitives--w2"),
                .product(name: "Buffer Linear Small Primitives", package: "swift-buffer-linear-primitives--w2"),
                .product(name: "Ordinal Primitives", package: "swift-ordinal-primitives"),
                .product(name: "Cardinal Primitives", package: "swift-cardinal-primitives"),
            ]
        ),

        // MARK: - Fixed ops
        .target(
            name: "Set Ordered Fixed Primitives",
            dependencies: [
                "Set Ordered Fixed Primitive",
                "Set Ordered Primitive",
                .product(name: "Memory Iterator Primitives", package: "swift-memory-iterator-primitives--w2"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Buffer Linear Bounded Primitive", package: "swift-buffer-linear-primitives--w2"),
                .product(name: "Buffer Linear Bounded Primitives", package: "swift-buffer-linear-primitives--w2"),
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
                .product(name: "Memory Iterator Primitives", package: "swift-memory-iterator-primitives--w2"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Buffer Linear Primitive", package: "swift-buffer-linear-primitives--w2"),
                .product(name: "Buffer Linear Inline Primitives", package: "swift-buffer-linear-primitives--w2"),
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
                .product(name: "Memory Iterator Primitives", package: "swift-memory-iterator-primitives--w2"),
                // Builder Primitives: Set.Ordered.Small conforms the generic Buildable.
                .product(name: "Builder Primitives", package: "swift-builder-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Buffer Linear Primitive", package: "swift-buffer-linear-primitives--w2"),
                .product(name: "Buffer Linear Small Primitive", package: "swift-buffer-linear-primitives--w2"),
                .product(name: "Buffer Linear Small Primitives", package: "swift-buffer-linear-primitives--w2"),
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
                .product(name: "Memory Iterator Primitives", package: "swift-memory-iterator-primitives--w2"),
                .product(name: "Builder Primitives", package: "swift-builder-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Buffer Linear Primitive", package: "swift-buffer-linear-primitives--w2"),
                .product(name: "Buffer Linear Primitives", package: "swift-buffer-linear-primitives--w2"),
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
                .product(name: "Buffer Primitives Test Support", package: "swift-buffer-primitives--w2"),
            ],
            path: "Tests/Support"
        ),

        // MARK: - Per-variant type tests ([TEST-033] topology B: one test target per
        // variant TYPE module, exercising its hot-op surface in isolation; cross-variant
        // + conformance tests live in the umbrella test target below)
        .testTarget(
            name: "Set Ordered Primitive Tests",
            dependencies: [
                "Set Ordered Primitive",
                .product(name: "Hash Primitives Standard Library Integration", package: "swift-hash-primitives"),
                .product(name: "Index Primitives Test Support", package: "swift-index-primitives"),
            ]
        ),

        .testTarget(
            name: "Set Ordered Fixed Primitive Tests",
            dependencies: [
                "Set Ordered Fixed Primitive",
                .product(name: "Hash Primitives Standard Library Integration", package: "swift-hash-primitives"),
                .product(name: "Index Primitives Test Support", package: "swift-index-primitives"),
            ]
        ),

        .testTarget(
            name: "Set Ordered Static Primitive Tests",
            dependencies: [
                "Set Ordered Static Primitive",
                .product(name: "Hash Primitives Standard Library Integration", package: "swift-hash-primitives"),
                .product(name: "Index Primitives Test Support", package: "swift-index-primitives"),
            ]
        ),

        .testTarget(
            name: "Set Ordered Small Primitive Tests",
            dependencies: [
                "Set Ordered Small Primitive",
                .product(name: "Hash Primitives Standard Library Integration", package: "swift-hash-primitives"),
                .product(name: "Index Primitives Test Support", package: "swift-index-primitives"),
            ]
        ),

        // MARK: - Umbrella + cross-variant tests
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
