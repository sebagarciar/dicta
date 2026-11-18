// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Habla",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/FluidInference/FluidAudio.git", exact: "0.18.3"),
    ],
    targets: [
        .executableTarget(
            name: "HablaCLI",
            dependencies: [.product(name: "FluidAudio", package: "FluidAudio")]
        ),
        .executableTarget(
            name: "Habla",
            dependencies: [.product(name: "FluidAudio", package: "FluidAudio")]
        ),
    ]
)
