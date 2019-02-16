// swift-tools-version:4.2

import PackageDescription

let package = Package(
  name: "ParserPrinter",
  products: [
    .executable(name: "generate-partial-isos", targets: ["generate-partial-isos"]),
    .library(name: "GeneratePartialIsos", targets: ["GeneratePartialIsos"]),
    .library(name: "PartialIso", targets: ["PartialIso"]),
    .library(name: "Syntax", targets: ["Syntax"]),
    .library(name: "URLRequestRouter", targets: ["URLRequestRouter"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-syntax.git", .exact("0.40200.0")),
    .package(url: "https://github.com/pointfreeco/swift-algebras", .branch("monoid")),
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", .revision("0ea1b40")),
  ],
  targets: [
    .target(
      name: "generate-partial-isos",
      dependencies: ["GeneratePartialIsos"]),
    .target(
      name: "GeneratePartialIsos",
      dependencies: ["SwiftSyntax"]),
    .testTarget(
      name: "GeneratePartialIsosTests",
      dependencies: ["GeneratePartialIsos", "PartialIso", "SnapshotTesting"]),
    .target(
      name: "PartialIso",
      dependencies: []),
    .testTarget(
      name: "PartialIsoTests",
      dependencies: ["PartialIso"]),
    .target(
      name: "Syntax",
      dependencies: ["Monoid", "PartialIso"]),
    .testTarget(
      name: "SyntaxTests",
      dependencies: ["Syntax"]),
    .target(
      name: "URLRequestRouter",
      dependencies: ["Monoid", "PartialIso", "Syntax"]),
    .testTarget(
      name: "URLRequestRouterTests",
      dependencies: ["URLRequestRouter"]),
    ]
)
