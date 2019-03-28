// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Navigator",
    products: [
        .library(
            name: "Navigator",
            targets: ["Navigator"])
    ],
    targets: [
        .target(
            name: "Navigator",
            path: "Navigator")
    ],
    swiftLanguageVersions: [.v4, .v5]
)
