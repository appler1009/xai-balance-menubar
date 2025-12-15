// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "xAI-Balance-Menu",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "xAI-Balance-Menu", targets: ["xAI-Balance-Menu"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "xAI-Balance-Menu",
            dependencies: []
        )
    ]
)