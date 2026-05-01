// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "SharedKit",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "SharedKit", targets: ["SharedKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.1.0"),
        // ONNX Runtime — uncomment once VAD is wired:
        // .package(url: "https://github.com/microsoft/onnxruntime-swift-package-manager.git", from: "1.17.0"),
    ],
    targets: [
        .target(
            name: "SharedKit",
            dependencies: [
                .product(name: "Yams", package: "Yams"),
                // .product(name: "onnxruntime", package: "onnxruntime-swift-package-manager"),
            ],
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "SharedKitTests",
            dependencies: ["SharedKit"]
        ),
    ]
)
