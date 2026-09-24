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
import EventKit
import Speech
import MediaPlayer
import CoreBluetooth

/// One async API over thirteen different system permission APIs, each with
/// its own callback/delegate/completion-handler shape. Callers never touch
/// `AVCaptureDevice`, `PHPhotoLibrary`, `EKEventStore`, `CBCentralManager`,
/// or any of the others directly.
///
/// App Tracking lives in the separate `KitoPermissionsTracking` product so apps
/// that don't track never link AppTrackingTransparency (App Store validation
/// then demands `NSUserTrackingUsageDescription`). Without it, `.tracking`
/// reports `.notDetermined` and requesting it does nothing.
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
        case .locationAlways:
            return Self.mapAlways(CLLocationManager().authorizationStatus)
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
        case .calendar:
            return Self.map(EKEventStore.authorizationStatus(for: .event))
        case .reminders:
            return Self.map(EKEventStore.authorizationStatus(for: .reminder))
        case .speechRecognition:
            return Self.map(SFSpeechRecognizer.authorizationStatus())
        case .mediaLibrary:
            return Self.map(MPMediaLibrary.authorizationStatus())
        case .bluetooth:
            return Self.map(CBManager.authorization)
        case .tracking:
            return await KitoPermissionHandlerRegistry.handler(for: .tracking)?.status() ?? .notDetermined
        }
    }

    /// Requests the permission if not yet determined, otherwise returns the
    /// current status without prompting again (the OS ignores a second
    /// prompt anyway, but this keeps call sites simple: always call
    /// `request`, never branch on `status` first).
    /// Whether this build can ask for `kind`. Only `.tracking` can be missing — it needs the
    /// `KitoPermissionsTracking` add-on and `KitoPermissionsTracking.register()`.
    public nonisolated func isSupported(_ kind: KitoPermissionKind) -> Bool {
        kind != .tracking || KitoPermissionHandlerRegistry.handler(for: .tracking) != nil
    }

    /// Plugs in status/request code for a permission whose framework lives in an add-on
    /// target (today: App Tracking, via `KitoPermissionsTracking.register()`).
    public nonisolated static func register(_ handler: KitoPermissionHandler, for kind: KitoPermissionKind) {
        KitoPermissionHandlerRegistry.set(handler, for: kind)
    }

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
        case .locationAlways:
            return await status(for: .locationAlways)
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
        case .calendar:
            let granted = (try? await EKEventStore().requestFullAccessToEvents()) ?? false
            return granted ? .granted : .denied
        case .reminders:
            let granted = (try? await EKEventStore().requestFullAccessToReminders()) ?? false
            return granted ? .granted : .denied
        case .speechRecognition:
            return await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: Self.map(status))
                }
            }
        case .mediaLibrary:
            return await withCheckedContinuation { continuation in
                MPMediaLibrary.requestAuthorization { status in
                    continuation.resume(returning: Self.map(status))
                }
            }
        case .bluetooth:
            // CoreBluetooth has no explicit "request" call — the system
            // prompt appears the first time a CBCentralManager is actually
            // used. Standing one up and waiting for its first state update
            // is what triggers (and resolves) that prompt.
            await KitoBluetoothAuthorizationWaiter().waitForResolution()
            return Self.map(CBManager.authorization)
        case .tracking:
            return await KitoPermissionHandlerRegistry.handler(for: .tracking)?.request() ?? .notDetermined
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

    /// Unlike the general location mapping, "when in use" alone doesn't
    /// satisfy an Always request — only `.authorizedAlways` counts as
    /// granted here, so a screen asking for background location doesn't
    /// show a misleading "granted" for a scope it doesn't actually have.
    private static func mapAlways(_ status: CLAuthorizationStatus) -> KitoPermissionStatus {
        switch status {
        case .authorizedAlways: return .granted
        case .authorizedWhenInUse, .denied: return .denied
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

    private static func map(_ status: EKAuthorizationStatus) -> KitoPermissionStatus {
        switch status {
        case .fullAccess, .authorized: return .granted
        case .writeOnly: return .granted
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .notDetermined
        }
    }

    private static func map(_ status: SFSpeechRecognizerAuthorizationStatus) -> KitoPermissionStatus {
        switch status {
        case .authorized: return .granted
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .notDetermined
        }
    }

    private static func map(_ status: MPMediaLibraryAuthorizationStatus) -> KitoPermissionStatus {
        switch status {
        case .authorized: return .granted
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .notDetermined
        }
    }

    private static func map(_ status: CBManagerAuthorization) -> KitoPermissionStatus {
        switch status {
        case .allowedAlways: return .granted
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .notDetermined
        @unknown default: return .notDetermined
        }
    }
}

/// Status and request code for one permission, supplied by an add-on target.
public struct KitoPermissionHandler: Sendable {
    public var status: @Sendable () async -> KitoPermissionStatus
    public var request: @Sendable () async -> KitoPermissionStatus

    public init(
        status: @escaping @Sendable () async -> KitoPermissionStatus,
        request: @escaping @Sendable () async -> KitoPermissionStatus
    ) {
        self.status = status
        self.request = request
    }
}

enum KitoPermissionHandlerRegistry {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var handlers: [KitoPermissionKind: KitoPermissionHandler] = [:]

    static func handler(for kind: KitoPermissionKind) -> KitoPermissionHandler? {
        lock.withLock { handlers[kind] }
    }

    static func set(_ handler: KitoPermissionHandler?, for kind: KitoPermissionKind) {
        lock.withLock { handlers[kind] = handler }
    }
}

/// Stands up a `CBCentralManager` just long enough to receive its first
/// state update — the moment CoreBluetooth resolves (or triggers) the
/// authorization prompt — then lets it go.
private final class KitoBluetoothAuthorizationWaiter: NSObject, CBCentralManagerDelegate, @unchecked Sendable {
    private var continuation: CheckedContinuation<Void, Never>?
    private var manager: CBCentralManager?

    func waitForResolution() async {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            self.manager = CBCentralManager(delegate: self, queue: nil)
        }
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        continuation?.resume()
        continuation = nil
    }
}
