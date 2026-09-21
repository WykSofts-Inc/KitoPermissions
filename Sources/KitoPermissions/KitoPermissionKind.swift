//
//  KitoPermissionKind.swift
//  KitoPermissions
//
//  Created by Wycliff on 8/26/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

public enum KitoPermissionKind: CaseIterable, Sendable {
    case camera, photoLibrary, microphone
    case locationWhenInUse, locationAlways
    case notifications, contacts
    case calendar, reminders
    case speechRecognition, mediaLibrary
    case bluetooth, tracking
}

public enum KitoPermissionStatus: Equatable, Sendable {
    case notDetermined, granted, denied, restricted
}
