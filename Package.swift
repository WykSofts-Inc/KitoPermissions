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
    products: [.library(name: "KitoPermissions", targets: ["KitoPermissions"])],
    dependencies: [
        .package(url: "https://github.com/WykSofts-Inc/KitoCore.git", from: "1.0.0"),
    ],
    targets: [
        .target(name: "KitoPermissions", dependencies: [.product(name: "KitoCore", package: "KitoCore")]),
        .testTarget(name: "KitoPermissionsTests", dependencies: ["KitoPermissions"]),
    ]
)
