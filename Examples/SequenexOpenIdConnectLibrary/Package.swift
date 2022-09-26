// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SequenexOpenIdConnectLibrary",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SequenexOpenIdConnectLibrary",
            targets: ["SequenexOpenIdConnectLibrary"])
    ],
    dependencies: [
        .package(url: "https://github.com/openid/AppAuth-iOS", from: "1.6.0")
    ],
    targets: [
        .target(
            name: "SequenexOpenIdConnectLibrary",
            dependencies: [.product(name: "AppAuth", package: "AppAuth-iOS")]
        ),
        .testTarget(
            name: "SequenexOpenIdConnectLibraryTests",
            dependencies: ["SequenexOpenIdConnectLibrary"])
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
