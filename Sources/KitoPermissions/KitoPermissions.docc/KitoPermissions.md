# ``KitoPermissions``

One async API over system permissions, with priming screens, Settings recovery and a permissions dashboard.

## Overview

KitoPermissions wraps camera, photo library, microphone, location, contacts,
notifications and the other system permissions behind a single actor,
``KitoPermissionManager``. Check a status or request one with the same
``KitoPermissionKind`` value, and get back a ``KitoPermissionStatus``.

```swift
let status = await KitoPermissionManager.shared.status(for: .camera)
if status == .notDetermined {
    let result = await KitoPermissionManager.shared.request(.camera)
}
```

Priming screens explain why before the one-shot system prompt. A
``KitoPermissionPrimer`` — or the `kitoPermissionPriming`
view modifier — requests the permission when the person taps Allow, and turns a
no into recovery steps with an Open Settings button.
``KitoPermissionsDashboard`` shows a summary ring and one row per permission, and
refreshes when the app becomes active again.

```swift
ContentView()
    .kitoPermissionPriming(isPresented: $asksForCamera, kind: .camera, style: .card) { status in
        if status.isGranted { startScanner() }
    }
```

Add the matching `Info.plist` usage-description keys for each permission you
request; the package calls the system APIs but cannot supply those strings. Pass
`requester: .simulated([.camera: .denied], outcome: .granted)` to any primer or the dashboard
to show every state in previews and tests. App Tracking Transparency lives in
the separate KitoPermissionsTracking product, so apps that don't track never link
it.

## Topics

### Essentials

- ``KitoPermissionManager``
- ``KitoPermissionKind``
- ``KitoPermissionStatus``

### Priming and Rationale

- ``KitoPermissionPrimer``
- ``KitoPermissionPrimingStyle``
- ``KitoPermissionPrimingContent``
- ``KitoPermissionPrimerPhase``
- ``KitoPermissionRationaleView``
- ``KitoPermissionRecoverySteps``

### Dashboard

- ``KitoPermissionsDashboard``
- ``KitoPermissionStatusBadge``

### Customization and Testing

- ``KitoPermissionRequester``
- ``KitoPermissionHandler``
- ``KitoPermissionSettings``
