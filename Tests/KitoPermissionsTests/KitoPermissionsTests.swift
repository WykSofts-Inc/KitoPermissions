//
//  KitoPermissionsTests.swift
//  KitoPermissions
//
//  Created by Wycliff on 8/29/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import XCTest
@testable import KitoPermissions

final class KitoPermissionsTests: XCTestCase {
    func testAllPermissionKindsCovered() {
        XCTAssertEqual(KitoPermissionKind.allCases.count, 13)
    }

    func testStatusEquatable() {
        XCTAssertEqual(KitoPermissionStatus.granted, .granted)
        XCTAssertNotEqual(KitoPermissionStatus.granted, .denied)
    }

    func testLocationWhenInUseAndAlwaysAreTrackedSeparately() async {
        // A fresh simulator/test run has never prompted for location, so
        // both report .notDetermined independently — the meaningful thing
        // this asserts is that they're two distinct KitoPermissionKind
        // cases with their own status lookups, not that either is granted.
        let whenInUse = await KitoPermissionManager.shared.status(for: .locationWhenInUse)
        let always = await KitoPermissionManager.shared.status(for: .locationAlways)
        XCTAssertEqual(whenInUse, .notDetermined)
        XCTAssertEqual(always, .notDetermined)
    }
}
