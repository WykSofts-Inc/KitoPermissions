//
//  KitoPermissionManager.swift
//  KitoPermissions
//
//  Created by Wycliff on 8/27/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import AVFoundation
import Photos
import CoreLocation
import Contacts
import UserNotifications

/// One async API over six different system permission APIs, each with its
/// own callback/delegate shape. Callers never touch `AVCaptureDevice`,
/// `PHPhotoLibrary`, or `CNContactStore` directly.
public actor KitoPermissionManager {
    public static let shared = KitoPermissionManager()

    public func status(for kind: KitoPermissionKind) async -> KitoPermissionStatus {
        switch kind {
        case .camera:
            return Self.map(AVCaptureDevice.authorizationStatus(for: .video))
        case .microphone:
            return Self.map(AVCaptureDevice.authorizationStatus(for: .audio))
        case .photoLibrary:
            return Self.map(PHPhotoLibrary.authorizationStatus(for: .readWrite))
        case .locationWhenInUse:
            return Self.map(CLLocationManager().authorizationStatus)
        case .contacts:
            return Self.map(CNContactStore.authorizationStatus(for: .contacts))
        case .notifications:
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral: return .granted
            case .denied: return .denied
            case .notDetermined: return .notDetermined
            @unknown default: return .notDetermined
            }
        }
    }

    /// Requests the permission if not yet determined, otherwise returns the
    /// current status without prompting again (the OS ignores a second
    /// prompt anyway, but this keeps call sites simple: always call
    /// `request`, never branch on `status` first).
    public func request(_ kind: KitoPermissionKind) async -> KitoPermissionStatus {
        switch kind {
        case .camera:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            return granted ? .granted : .denied
        case .microphone:
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            return granted ? .granted : .denied
        case .photoLibrary:
            let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            return Self.map(status)
        case .locationWhenInUse:
            // CLLocationManager's delegate-based API doesn't have a native
            // async form; callers needing live updates should use
            // CLLocationManager directly. This reports current status only.
            return await status(for: .locationWhenInUse)
        case .contacts:
            return await withCheckedContinuation { continuation in
                CNContactStore().requestAccess(for: .contacts) { granted, _ in
                    continuation.resume(returning: granted ? .granted : .denied)
                }
            }
        case .notifications:
            let center = UNUserNotificationCenter.current()
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            return granted ? .granted : .denied
        }
    }

    private static func map(_ status: AVAuthorizationStatus) -> KitoPermissionStatus {
        switch status {
        case .authorized: return .granted
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .notDetermined
        }
    }

    private static func map(_ status: PHAuthorizationStatus) -> KitoPermissionStatus {
        switch status {
        case .authorized, .limited: return .granted
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .notDetermined
        }
    }

    private static func map(_ status: CLAuthorizationStatus) -> KitoPermissionStatus {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse: return .granted
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .notDetermined
        }
    }

    private static func map(_ status: CNAuthorizationStatus) -> KitoPermissionStatus {
        switch status {
        case .authorized: return .granted
        case .limited: return .granted
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .notDetermined
        }
    }
}
