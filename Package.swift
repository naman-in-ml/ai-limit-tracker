// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ClaudeUsage",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(name: "ClaudeUsageCore", targets: ["ClaudeUsageCore"]),
        .executable(name: "ClaudeUsage", targets: ["ClaudeUsage"]),
        .executable(name: "ClaudeUsageTests", targets: ["ClaudeUsageTests"])
    ],
    targets: [
        .target(
            name: "ClaudeUsageCore",
            path: "Sources/ClaudeUsageCore"
        ),
        .executableTarget(
            name: "ClaudeUsage",
            dependencies: ["ClaudeUsageCore"],
            path: "Sources/ClaudeUsage"
        ),
        .executableTarget(
            name: "ClaudeUsageTests",
            dependencies: ["ClaudeUsageCore"],
            path: "Tests/ClaudeUsageTests"
        )
    ]
)
