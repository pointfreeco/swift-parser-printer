// swift-tools-version:4.2

import PackageDescription

let package = Package(
  name: "PrinterParser",
  products: [
    .library(name: "Syntax", targets: ["Syntax"]),
    .library(name: "URLRequestRouter", targets: ["URLRequestRouter"]),
    .library(name: "PartialIso", targets: ["PartialIso"]),
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-algebras", .branch("monoid"))
  ],
  targets: [
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
    .target(
      name: "PartialIso",
      dependencies: []),
    .testTarget(
      name: "PartialIsoTests",
      dependencies: ["PartialIso"]),
    ]
)
