// swift-tools-version: 6.0
import PackageDescription

#if TUIST
import struct ProjectDescription.PackageSettings

let packageSettings = PackageSettings(productTypes: [:])
#endif

let package = Package(
    name: "UMCDesk",
    dependencies: [
        .package(
            url: "https://github.com/JEONG-J/Aquila.git",
            revision: "c167df60acf91bd5827c67e4ec083ec902b0f65b"
        ),
    ]
)
