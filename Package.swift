// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "TaskBubble",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .executable(name: "TaskBubble", targets: ["TaskBubble"])
  ],
  targets: [
    .executableTarget(
      name: "TaskBubble",
      path: "Sources/TaskBubble"
    ),
    .testTarget(
      name: "TaskBubbleTests",
      dependencies: ["TaskBubble"],
      path: "Tests/TaskBubbleTests"
    ),
  ]
)
