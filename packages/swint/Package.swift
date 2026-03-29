// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "Swint",
  platforms: [
    .macOS(.v13),
  ],
  products: [
    .library(
      name: "SwintCore",
      targets: ["SwintCore"]
    ),
    .executable(
      name: "swint",
      targets: ["swint"]
    ),
  ],
  targets: [
    .target(
      name: "SwintCore"
    ),
    .executableTarget(
      name: "swint",
      dependencies: ["SwintCore"]
    ),
    .testTarget(
      name: "SwintCoreTests",
      dependencies: ["SwintCore"]
    ),
  ]
)
