// swift-tools-version:4.0

import PackageDescription

var targets: [PackageDescription.Target] = [
	.target(name: "Bolt", dependencies: ["PackStream", "NIO", "NIOOpenSSL"], path: "Sources"),
	.testTarget(name: "BoltTests", dependencies: ["Bolt"]),
]

let package = Package(
    name: "Bolt",
	products: [
		.library(name: "Bolt", targets: ["Bolt"]),
	],
	dependencies: [
	    .package(url: "https://github.com/Neo4j-Swift/PackStream-swift.git", from: "1.0.2"),
		.package(url: "https://github.com/apple/swift-nio.git", from: "1.8.0"),
		.package(url: "https://github.com/apple/swift-nio-ssl", from: "1.2.0")
	    ],
	targets: targets
)
