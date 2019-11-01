// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Navigator",
    platforms: [
        .iOS(.v10),
    ],
    products: [
        .library(
            name: "Navigator",
            targets: ["Navigator"])
    ],
    targets: [
        .target(
            name: "Navigator",
            path: "Navigator")
    ]
)
