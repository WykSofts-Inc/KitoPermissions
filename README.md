# KitoPermissions

One async API over camera, photo library, microphone, location, contacts,
notification and eight more system permissions — plus priming screens that
explain *why* before the one-shot system prompt, a Settings recovery when the
answer was no, and a permissions dashboard.

## Install

```swift
.package(url: "https://github.com/WykSofts-Inc/KitoPermissions.git", from: "1.1.0"),
```

Add the usual `Info.plist` usage-description keys for whichever permissions
you request (`NSCameraUsageDescription`, etc.) — KitoPermissions calls the
system APIs, it doesn't (can't) supply their required plist strings.

## Priming screens

Explain first, then ask. Each primer requests the permission when the person taps
Allow, celebrates a yes, and turns a no into three steps and an **Open Settings**
button (straight to the notification settings page for `.notifications`).

```swift
// A floating card over a dimmed screen
ContentView()
    .kitoPermissionPriming(isPresented: $asksForCamera, kind: .camera, style: .card) { status in
        if status.isGranted { startScanner() }
    }

// A full-screen page with an animated illustration
KitoPermissionPrimer(kind: .locationWhenInUse, style: .illustration, onDismiss: { dismiss() })

// An inline banner inside your content
KitoPermissionPrimer(kind: .notifications, style: .banner, onDismiss: { hideBanner() })
```

Your own copy: `KitoPermissionPrimingContent(title:message:benefits:allowTitle:laterTitle:)`;
every kind also has sensible `.standard(for:)` copy, a `displayName`, `systemImage` and `tint`.

## Permissions dashboard

```swift
ScrollView {
    KitoPermissionsDashboard([.camera, .photoLibrary, .notifications, .locationWhenInUse],
                             reasons: [.camera: "Scan M-Pesa QR codes"])
        .padding()
}
```

A summary ring, then one row per permission with Allow (not asked), a green
Allowed pill, or Settings (off). Statuses refresh when the app becomes active again.

## Previews, demos and tests

Pass `requester: .simulated([.camera: .denied], outcome: .granted)` to any primer or
the dashboard to show every state without touching real permissions.

## App Tracking is a separate product

`KitoPermissions` doesn't link AppTrackingTransparency, so apps that don't track
don't need `NSUserTrackingUsageDescription`. Without the add-on, `.tracking`
reports `.notDetermined`, `request(.tracking)` does nothing, and
`KitoPermissionManager.shared.isSupported(.tracking)` is `false`.

If you do track, add the `KitoPermissionsTracking` product, the
`NSUserTrackingUsageDescription` key, and register once at launch:

```swift
import KitoPermissionsTracking

init() { KitoPermissionsTracking.register() }
```

**Migrating from 1.0:** apps that requested `.tracking` must add the
`KitoPermissionsTracking` product and call `register()`; nothing else changes.

## Samples

**Check then request:**
```swift
let status = await KitoPermissionManager.shared.status(for: .camera)
if status == .notDetermined {
    let result = await KitoPermissionManager.shared.request(.camera)
}
```

**Rationale screen before prompting (better grant rates than a cold prompt):**
```swift
.sheet(isPresented: $showingRationale) {
    KitoPermissionRationaleView(
        icon: "camera.fill",
        title: "Scan receipts instantly",
        message: "We use your camera only to scan receipts — nothing is uploaded without your say-so.",
        onContinue: {
            showingRationale = false
            Task { await requestCamera() }
        },
        onSkip: { showingRationale = false }
    )
}
```

**From a ViewModel:**
```swift
@Observable final class ScannerViewModel {
    var permissionStatus: KitoPermissionStatus = .notDetermined

    func requestCameraAccess() async {
        permissionStatus = await KitoPermissionManager.shared.request(.camera)
    }
}
```

**Notifications opt-in during onboarding:**
```swift
Button("Enable notifications") {
    Task { _ = await KitoPermissionManager.shared.request(.notifications) }
}
```

## License

MIT
