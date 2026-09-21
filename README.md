# KitoPermissions

One async API over camera, photo library, microphone, location, contacts, and
notification permissions — plus a themed rationale screen to show before the
one-shot system prompt.

## Install

```swift
.package(url: "https://github.com/WykSofts-Inc/KitoPermissions.git", from: "1.0.0"),
```

Add the usual `Info.plist` usage-description keys for whichever permissions
you request (`NSCameraUsageDescription`, etc.) — KitoPermissions calls the
system APIs, it doesn't (can't) supply their required plist strings.

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
