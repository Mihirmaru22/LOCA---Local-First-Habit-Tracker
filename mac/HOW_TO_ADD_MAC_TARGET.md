# Adding the macOS Target in Xcode

## One-time Xcode Setup

The `mac/` folder contains all macOS-specific source files. To wire them
into the Xcode project follow these steps (takes about 10 minutes):

### 1. Add a macOS app target

1. Open `ios/LOCA.xcodeproj` in Xcode.
2. File → New → Target → **macOS → App**.
3. Product name: **LOCAMac**
4. Bundle identifier: `com.mihirmaru.loca.mac`
5. **Uncheck** "Include Tests".
6. Deployment target: **macOS 14.0**
7. Click Finish.

### 2. Add the mac/ source files to the new target

1. In the Project Navigator, drag the entire `mac/` folder into the
   Xcode project group (under the `ios/LOCA.xcodeproj` root).
2. In the "Choose options" sheet:
   - Target membership: **LOCAMac only** (not the iOS target).
   - "Copy items if needed": **unchecked** (files are already in the repo).
3. Do the same for `ios/LOCA/Core/`, `ios/LOCA/Analytics/`, and
   `ios/LOCA/Features/` — these shared directories should be members
   of **both** the iOS `LOCA` target and the macOS `LOCAMac` target.

### 3. Shared files — target membership

These folders contain code shared between iOS and macOS. Add each to the
`LOCAMac` target in File Inspector (⌥⌘1):

| Folder | Shared? |
|--------|---------|
| `ios/LOCA/Core/` | ✅ both targets |
| `ios/LOCA/Analytics/` | ✅ both targets |
| `ios/LOCA/Features/Dashboard/` | ✅ both targets |
| `ios/LOCA/Features/HabitDetail/` | ✅ both targets |
| `ios/LOCA/Features/HabitManagement/` | ✅ both targets |
| `ios/LOCA/Features/Life/` | ✅ both targets |
| `ios/LOCA/App/LOCAApp.swift` | iOS only |
| `ios/LOCA/App/AppRootView.swift` | iOS only |
| `ios/LOCA/Intents/` | iOS only |
| `ios/LOCA/LOCAWidget/` | iOS only |
| `mac/` | macOS only |

### 4. Build settings for LOCAMac target

| Setting | Value |
|---------|-------|
| `MACOSX_DEPLOYMENT_TARGET` | `14.0` |
| `SWIFT_ACTIVE_COMPILATION_CONDITIONS` | `LOCAL_DEVELOPMENT` (Debug) |
| `PRODUCT_BUNDLE_IDENTIFIER` | `com.mihirmaru.loca.mac` |
| `INFOPLIST_FILE` | `mac/Info.plist` |

### 5. Entitlements (optional for local development)

Create `mac/LOCAMac-Debug.entitlements` with:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
</dict>
</plist>
```

This disables sandboxing for local development so SwiftData can write
to the app-sandbox directory without an App Group entitlement.

### 6. Build and run

Select the **LOCAMac** scheme, choose "My Mac" as the run destination,
and press ⌘R. The app launches with a three-pane `NavigationSplitView`
showing the Habits sidebar section.
