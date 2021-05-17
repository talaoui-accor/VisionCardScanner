// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "VisionCardScanner",
  platforms: [
    .macOS(.v10_15), .iOS(.v13)
  ],
  products: [
    .library(
      name: "VisionCardScanner",
      targets: ["VisionCardScanner"]
    )
  ],
  dependencies: [
  ],
  targets: [
    .target(
      name: "VisionCardScanner",
      dependencies: [],
      path: "Sources",
      exclude: ["VisionCardScannerSample"]
      )
  ]
)
