// swift-tools-version: 6.0

import PackageDescription
import Foundation

#if arch(x86_64)
// Docker and Ubuntu release system uses `march=skylake`
let mArch = ProcessInfo.processInfo.environment["MARCH_SKYLAKE"] == "TRUE" ? ["-march=skylake"] : ["-march=native"]
#else
let mArch: [String] = []
#endif

let swiftFlags: [PackageDescription.SwiftSetting] = [
    .unsafeFlags(["-cross-module-optimization", "-Ounchecked"],
    .when(configuration: .release))
]

// Note: Fast math flags reduce performance for compression
let cFlagsPFor2D = [PackageDescription.CSetting.unsafeFlags(["-O3"] + mArch)]
let cFlagsPFor = [PackageDescription.CSetting.unsafeFlags(["-O3", "-Wall", "-Werror", "-Wimplicit-fallthrough", "-Wextra"] + mArch)]


let package = Package(
    name: "om-file-format",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "OmFileFormat",
            targets: ["OmFileFormat"]),
    ],
    targets: [
        .target(
            name: "OmFileFormat",
            dependencies: ["OmFileFormatC"],
            path: "Swift/OmFileFormat",
            cSettings: cFlagsPFor2D,
            swiftSettings: swiftFlags
        ),
        .target(
            name: "OmFileFormatC",
            path: "c",
            cSettings: cFlagsPFor,
            swiftSettings: swiftFlags
        ),
        .testTarget(
            name: "OmFileFormatTests",
            dependencies: ["OmFileFormat"]
        ),
    ]
)
