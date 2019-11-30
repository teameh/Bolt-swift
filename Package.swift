// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Bolt",
    products: [
        .library(name: "Bolt", targets: ["Bolt"]),
    ],
    dependencies: [
      .package(url: "https://github.com/Neo4j-Swift/PackStream-swift.git", from: "1.0.0"),
      .package(url: "https://github.com/IBM-Swift/BlueSSLService.git", from: "0.0.0"),
    ],
    targets: [
        .target(
            name: "Bolt",
            dependencies: ["PackStream", "SSLService"],
            path: "Sources"
        )
    ]
)
