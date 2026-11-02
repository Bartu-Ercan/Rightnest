// swift-tools-version: 6.0
import PackageDescription
let package = Package(
    name: "Rightnest",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "Rightnest", targets: ["Rightnest"]),
        .executable(name: "RightSideProbe", targets: ["RightSideProbe"])
    ],
    targets: [
        .target(name: "RightnestCore"),
        .executableTarget(name: "PlacementChecks", dependencies: ["RightnestCore"], path: "Checks/PlacementChecks"),
        .executableTarget(name: "Rightnest", dependencies: ["RightnestCore"]),
        .executableTarget(name: "RightSideProbe"),
        .testTarget(name: "RightnestCoreTests", dependencies: ["RightnestCore"])
    ],
    swiftLanguageModes: [.v6]
)
