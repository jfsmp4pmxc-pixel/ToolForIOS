// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Empty",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .app(name: "Empty", targets: ["Empty"])
    ],
    targets: [
        .executableTarget(
            name: "Empty",
            dependencies: [],
            path: "Empty",
            swiftSettings: [
                .unsafeFlags(["-suppress-warnings"], .when(configuration: .release))
            ]
        )
    ]
)

extension Product {
    static func app(name: String, targets: [String]) -> Product {
        return .executable(name: name, targets: targets)
    }
}
