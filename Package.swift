// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "swift-process",
	platforms: [
		.macOS(.v14)
	],
	products: [
		.library(
			name: "SwiftProcess",
			targets: ["SwiftProcess"]
		)
	],
	targets: [
		.target(
			name: "SwiftProcess"
		),
		.testTarget(
			name: "SwiftProcessTests",
			dependencies: ["SwiftProcess"]
		)
	]
)
