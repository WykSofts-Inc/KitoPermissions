// swift-tools-version: 5.9
//
//  Package.swift
//  KitoPermissions
//
//  Created by Wycliff on 8/25/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//


import PackageDescription

let package = Package(
    name: "KitoPermissions",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "KitoPermissions", targets: ["KitoPermissions"]),
        // Separate so apps that don't track never link AppTrackingTransparency.
        .library(name: "KitoPermissionsTracking", targets: ["KitoPermissionsTracking"]),
    ],
    dependencies: [
        .package(url: "https://github.com/WykSofts-Inc/KitoCore.git", from: "1.1.0"),
    ],
    targets: [
        .target(name: "KitoPermissions", dependencies: [.product(name: "KitoCore", package: "KitoCore")]),
        .target(name: "KitoPermissionsTracking", dependencies: ["KitoPermissions"]),
        .testTarget(name: "KitoPermissionsTests", dependencies: ["KitoPermissions", "KitoPermissionsTracking"]),
    ]
)
