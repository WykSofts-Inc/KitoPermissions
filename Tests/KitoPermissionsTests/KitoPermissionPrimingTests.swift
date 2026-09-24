//
//  KitoPermissionPrimingTests.swift
//  KitoPermissions
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import XCTest
@testable import KitoPermissions
@testable import KitoPermissionsTracking

final class KitoPermissionPrimingTests: XCTestCase {
    func testPhaseFollowsStatus() {
        XCTAssertEqual(KitoPermissionPrimerPhase(status: .notDetermined), .priming)
        XCTAssertEqual(KitoPermissionPrimerPhase(status: .granted), .granted)
        XCTAssertEqual(KitoPermissionPrimerPhase(status: .denied), .denied)
        XCTAssertEqual(KitoPermissionPrimerPhase(status: .restricted), .denied)
    }

    func testEveryKindHasCopyAndArtwork() {
        for kind in KitoPermissionKind.allCases {
            let content = KitoPermissionPrimingContent.standard(for: kind)
            XCTAssertFalse(content.title.isEmpty, "\(kind)")
            XCTAssertFalse(content.message.isEmpty, "\(kind)")
            XCTAssertEqual(content.benefits.count, 3, "\(kind)")
            XCTAssertFalse(kind.displayName.isEmpty, "\(kind)")
            XCTAssertFalse(kind.systemImage.isEmpty, "\(kind)")
            XCTAssertFalse(kind.companionSymbols.isEmpty, "\(kind)")
        }
    }

    func testStatusLabels() {
        XCTAssertEqual(KitoPermissionStatus.granted.label, "Allowed")
        XCTAssertEqual(KitoPermissionStatus.denied.label, "Off")
        XCTAssertTrue(KitoPermissionStatus.notDetermined.canPrompt)
        XCTAssertFalse(KitoPermissionStatus.denied.canPrompt)
        XCTAssertTrue(KitoPermissionStatus.granted.isGranted)
    }

    func testSimulatedRequesterResolvesOnceThenRemembers() async {
        let requester = KitoPermissionRequester.simulated([.camera: .denied], outcome: .granted, delay: .zero)
        let camera = await requester.request(.camera)
        XCTAssertEqual(camera, .denied, "an answered permission keeps its answer")

        let before = await requester.status(.microphone)
        XCTAssertEqual(before, .notDetermined)
        let mic = await requester.request(.microphone)
        XCTAssertEqual(mic, .granted)
        let after = await requester.status(.microphone)
        XCTAssertEqual(after, .granted)
    }

    func testSimulatedDenialOutcome() async {
        let requester = KitoPermissionRequester.simulated(outcome: .denied, delay: .zero)
        let result = await requester.request(.notifications)
        XCTAssertEqual(result, .denied)
    }
}

final class KitoPermissionHandlerTests: XCTestCase {
    override func tearDown() {
        KitoPermissionHandlerRegistry.set(nil, for: .tracking)
    }

    func testTrackingWithoutAddOnIsUnsupportedAndInert() async {
        KitoPermissionHandlerRegistry.set(nil, for: .tracking)
        XCTAssertFalse(KitoPermissionManager.shared.isSupported(.tracking))
        XCTAssertTrue(KitoPermissionManager.shared.isSupported(.camera))
        let status = await KitoPermissionManager.shared.request(.tracking)
        XCTAssertEqual(status, .notDetermined)
    }

    func testRegisteredHandlerIsUsed() async {
        KitoPermissionManager.register(KitoPermissionHandler(status: { .denied }, request: { .granted }), for: .tracking)
        XCTAssertTrue(KitoPermissionManager.shared.isSupported(.tracking))
        let status = await KitoPermissionManager.shared.status(for: .tracking)
        let requested = await KitoPermissionManager.shared.request(.tracking)
        XCTAssertEqual(status, .denied)
        XCTAssertEqual(requested, .granted)
    }

    func testTrackingStatusMapping() {
        XCTAssertEqual(KitoPermissionsTracking.map(.authorized), .granted)
        XCTAssertEqual(KitoPermissionsTracking.map(.denied), .denied)
        XCTAssertEqual(KitoPermissionsTracking.map(.notDetermined), .notDetermined)
    }
}
