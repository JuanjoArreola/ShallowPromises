// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ShallowPromises",
    products: [
        .library(
            name: "ShallowPromises",
            targets: ["ShallowPromises"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "ShallowPromises",
            dependencies: []),
        .testTarget(
            name: "ShallowPromisesTests",
            dependencies: ["ShallowPromises"]),
    ]
)
