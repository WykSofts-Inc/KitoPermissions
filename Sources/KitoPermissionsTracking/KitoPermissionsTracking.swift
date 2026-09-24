//
//  KitoPermissionsTracking.swift
//  KitoPermissions
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import AppTrackingTransparency
import KitoPermissions

/// App Tracking Transparency for `KitoPermissionManager`, kept out of the core product so apps
/// that don't track never link AppTrackingTransparency. Add `NSUserTrackingUsageDescription`
/// to your Info.plist — requesting without it crashes — then register once at launch:
///
/// ```swift
/// init() { KitoPermissionsTracking.register() }
/// ```
public enum KitoPermissionsTracking {
    public static func register() {
        KitoPermissionManager.register(
            KitoPermissionHandler(
                status: { map(ATTrackingManager.trackingAuthorizationStatus) },
                request: {
                    await withCheckedContinuation { continuation in
                        ATTrackingManager.requestTrackingAuthorization { status in
                            continuation.resume(returning: map(status))
                        }
                    }
                }
            ),
            for: .tracking
        )
    }

    static func map(_ status: ATTrackingManager.AuthorizationStatus) -> KitoPermissionStatus {
        switch status {
        case .authorized: return .granted
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .notDetermined
        }
    }
}
