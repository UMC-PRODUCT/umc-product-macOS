// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "UMCNetworkKit",
    platforms: [.macOS("26.0"), .iOS("26.0")],
    products: [.library(name: "UMCNetworkKit", targets: ["UMCNetworkKit"])],
    dependencies: [
        .package(url: "https://github.com/Moya/Moya.git", from: "15.0.3"),
    ],
    targets: [
        .target(
            name: "UMCNetworkKit",
            dependencies: [.product(name: "Moya", package: "Moya")]
        ),
        .testTarget(name: "UMCNetworkKitTests", dependencies: ["UMCNetworkKit"]),
    ]
)
