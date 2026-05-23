// swift-tools-version: 6.3.1

import PackageDescription

let package = Package(
    name: "swift-buffer-ring-primitives",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
    ],
    products: [
        .library(name: "Buffer Ring Primitive", targets: ["Buffer Ring Primitive"]),
        .library(name: "Buffer Ring Primitives", targets: ["Buffer Ring Primitives"]),
        .library(name: "Buffer Ring Inline Primitives", targets: ["Buffer Ring Inline Primitives"]),
        .library(name: "Buffer Ring Primitives Test Support", targets: ["Buffer Ring Primitives Test Support"]),
    ],
    dependencies: [
        .package(path: "../swift-buffer-primitives"),
        .package(path: "../swift-storage-primitives"),
        .package(path: "../swift-cyclic-index-primitives"),
        .package(path: "../swift-index-primitives"),
        .package(path: "../swift-affine-primitives"),
        .package(path: "../swift-ordinal-primitives"),
        .package(path: "../swift-memory-primitives"),
        .package(path: "../swift-sequence-primitives"),
        .package(path: "../swift-cardinal-primitives"),
    ],
    targets: [

        // MARK: - Buffer Ring Primitive — type declarations only (A10 poison isolation).
        .target(
            name: "Buffer Ring Primitive",
            dependencies: [
                .product(name: "Buffer Primitive", package: "swift-buffer-primitives"),
                .product(name: "Buffer Growth Primitives", package: "swift-buffer-primitives"),
                .product(name: "Storage Heap Primitives", package: "swift-storage-primitives"),
                .product(name: "Storage Inline Primitives", package: "swift-storage-primitives"),
                .product(name: "Storage Initialization Primitives", package: "swift-storage-primitives"),
                .product(name: "Cyclic Index Primitives", package: "swift-cyclic-index-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Memory Primitives", package: "swift-memory-primitives"),
                .product(name: "Affine Primitives", package: "swift-affine-primitives"),
                .product(name: "Ordinal Primitives", package: "swift-ordinal-primitives"),
            ]
        ),

        // MARK: - Buffer Ring Primitives — operations + Sequence conformances.
        .target(
            name: "Buffer Ring Primitives",
            dependencies: [
                "Buffer Ring Primitive",
                .product(name: "Storage Heap Primitives", package: "swift-storage-primitives"),
                .product(name: "Cyclic Index Primitives", package: "swift-cyclic-index-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Memory Primitives", package: "swift-memory-primitives"),
                .product(name: "Sequence Primitives", package: "swift-sequence-primitives"),
            ]
        ),
        .target(
            name: "Buffer Ring Inline Primitives",
            dependencies: [
                "Buffer Ring Primitive",
                "Buffer Ring Primitives",
                .product(name: "Storage Heap Primitives", package: "swift-storage-primitives"),
                .product(name: "Storage Inline Primitives", package: "swift-storage-primitives"),
                .product(name: "Cyclic Index Primitives", package: "swift-cyclic-index-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Memory Primitives", package: "swift-memory-primitives"),
                .product(name: "Sequence Primitives", package: "swift-sequence-primitives"),
            ]
        ),

        // MARK: - Test Support
        .target(
            name: "Buffer Ring Primitives Test Support",
            dependencies: [
                "Buffer Ring Primitives",
                "Buffer Ring Inline Primitives",
                .product(name: "Cardinal Primitives", package: "swift-cardinal-primitives"),
                .product(name: "Index Primitives", package: "swift-index-primitives"),
                .product(name: "Memory Primitives Test Support", package: "swift-memory-primitives"),
            ],
            path: "Tests/Support"
        ),

        // MARK: - Tests
        .testTarget(
            name: "Buffer Ring Primitives Tests",
            dependencies: ["Buffer Ring Primitives", "Buffer Ring Primitives Test Support"]
        ),
        .testTarget(
            name: "Buffer Ring Inline Primitives Tests",
            dependencies: ["Buffer Ring Inline Primitives", "Buffer Ring Primitives Test Support"]
        ),
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

    let package: [SwiftSetting] = [
        .enableExperimentalFeature("BuiltinModule"),
        .enableExperimentalFeature("RawLayout"),
    ]

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
