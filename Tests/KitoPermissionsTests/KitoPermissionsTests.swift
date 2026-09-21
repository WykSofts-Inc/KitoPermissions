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
        XCTAssertEqual(KitoPermissionKind.allCases.count, 6)
    }

    func testStatusEquatable() {
        XCTAssertEqual(KitoPermissionStatus.granted, .granted)
        XCTAssertNotEqual(KitoPermissionStatus.granted, .denied)
    }
}
