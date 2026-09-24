# ``KitoPermissionsTracking``

App Tracking Transparency support for KitoPermissions, shipped as an opt-in product.

## Overview

The core KitoPermissions product does not link AppTrackingTransparency, so apps
that don't track never need `NSUserTrackingUsageDescription`. Without this
add-on, the `.tracking` permission reports `.notDetermined`, requesting it does
nothing, and `KitoPermissionManager.shared.isSupported(.tracking)` returns
`false`.

If your app tracks, add the KitoPermissionsTracking product, add the
`NSUserTrackingUsageDescription` key to your `Info.plist` — requesting without it
crashes — and register the handler once at launch:

```swift
import SwiftUI
import KitoPermissionsTracking

@main
struct MyApp: App {
    init() { KitoPermissionsTracking.register() }

    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
```

After registration, `.tracking` works like every other permission through
`KitoPermissionManager`, the priming screens and the dashboard.

## Topics

### Essentials

- ``KitoPermissionsTracking/KitoPermissionsTracking``
