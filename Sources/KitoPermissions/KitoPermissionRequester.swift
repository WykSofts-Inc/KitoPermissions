//
//  KitoPermissionRequester.swift
//  KitoPermissions
//
//  Created by Wycliff on 9/24/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import Foundation

/// Where the priming views get statuses from and send requests to. `.live` talks to the system
/// through `KitoPermissionManager`; `.simulated(…)` answers from memory, so previews, demos and
/// tests can show every state (including "denied") without touching real permissions.
public struct KitoPermissionRequester: Sendable {
    public var status: @Sendable (KitoPermissionKind) async -> KitoPermissionStatus
    public var request: @Sendable (KitoPermissionKind) async -> KitoPermissionStatus

    public init(
        status: @escaping @Sendable (KitoPermissionKind) async -> KitoPermissionStatus,
        request: @escaping @Sendable (KitoPermissionKind) async -> KitoPermissionStatus
    ) {
        self.status = status
        self.request = request
    }

    /// The real system permissions.
    public static let live = KitoPermissionRequester(
        status: { await KitoPermissionManager.shared.status(for: $0) },
        request: { await KitoPermissionManager.shared.request($0) }
    )

    /// Starts from `statuses` (anything missing is `.notDetermined`). A request for a permission
    /// that hasn't been asked resolves to `outcome` after `delay`; asking again returns the stored
    /// answer, just as the system does.
    public static func simulated(
        _ statuses: [KitoPermissionKind: KitoPermissionStatus] = [:],
        outcome: KitoPermissionStatus = .granted,
        delay: Duration = .milliseconds(600)
    ) -> KitoPermissionRequester {
        let store = KitoSimulatedPermissionStore(statuses: statuses)
        return KitoPermissionRequester(
            status: { await store.status(for: $0) },
            request: { kind in
                try? await Task.sleep(for: delay)
                return await store.request(kind, outcome: outcome)
            }
        )
    }
}

private actor KitoSimulatedPermissionStore {
    private var statuses: [KitoPermissionKind: KitoPermissionStatus]

    init(statuses: [KitoPermissionKind: KitoPermissionStatus]) {
        self.statuses = statuses
    }

    func status(for kind: KitoPermissionKind) -> KitoPermissionStatus {
        statuses[kind] ?? .notDetermined
    }

    func request(_ kind: KitoPermissionKind, outcome: KitoPermissionStatus) -> KitoPermissionStatus {
        let current = status(for: kind)
        guard current == .notDetermined else { return current }
        statuses[kind] = outcome
        return outcome
    }
}

/// The stage a priming view is in.
public enum KitoPermissionPrimerPhase: Equatable, Sendable {
    /// Explaining why, before the system prompt.
    case priming
    /// The system prompt is up.
    case requesting
    /// Allowed.
    case granted
    /// Turned off (or restricted) — only Settings can change it now.
    case denied

    /// The phase that follows a known status.
    public init(status: KitoPermissionStatus) {
        switch status {
        case .notDetermined: self = .priming
        case .granted: self = .granted
        case .denied, .restricted: self = .denied
        }
    }
}
