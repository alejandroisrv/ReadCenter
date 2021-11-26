// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ReadCenter",
    platforms: [.iOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "ReadCenter",
            targets: ["ReadCenter"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(name: "AEXML", url: "https://github.com/tadija/AEXML.git", from: "4.6.1"),
        .package(name: "SnapKit", url: "https://github.com/SnapKit/SnapKit", from: "5.0.1"),
        .package(name: "Reachability", url: "https://github.com/ashleymills/Reachability.swift", from: "5.0.0"),
        .package(name: "PKHUD", url: "https://github.com/pkluz/PKHUD", from: "5.3.0"),
        .package(name: "ZipArchive", url: "https://github.com/ZipArchive/ZipArchive.git", from: "2.4.2"),
        .package(name: "DTCoreText", url: "https://github.com/Cocoanetics/DTCoreText", from: "1.6.26"),
        .package(name: "FMDB", url: "https://github.com/ccgus/fmdb", from: "2.7.7"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "ReadCenter",
            dependencies: ["SnapKit", "PKHUD", "Reachability", "DTCoreText","ZipArchive", "FMDB", "AEXML"]),
    ]
)
