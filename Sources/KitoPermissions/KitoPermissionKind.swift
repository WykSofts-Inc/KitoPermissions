//
//  KitoPermissionKind.swift
//  KitoPermissions
//
//  Created by Wycliff on 8/26/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

public enum KitoPermissionKind: CaseIterable, Sendable {
    case camera, photoLibrary, microphone, locationWhenInUse, notifications, contacts
}

public enum KitoPermissionStatus: Equatable, Sendable {
    case notDetermined, granted, denied, restricted
}
