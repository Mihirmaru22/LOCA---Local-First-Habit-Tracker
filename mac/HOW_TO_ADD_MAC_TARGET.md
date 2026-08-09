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
7. Click Finish. Xcode may offer to activate the new scheme — click **Activate**.

### 2. Add the mac/ source files (macOS target only)

1. In the Project Navigator, drag the entire `mac/` folder into the
   Xcode project group (under the `ios/LOCA.xcodeproj` root).
2. In the "Choose options" sheet:
   - Target membership: **LOCAMac only** (do NOT tick the iOS LOCA target).
   - "Copy items if needed": **unchecked** (files live in the repo already).

### 3. Add shared iOS source to the macOS target

The folders below are already in the iOS `LOCA` target. You need to **also**
add them to `LOCAMac` so the Mac build can access the shared models, analytics,
design system, and feature views it uses.

For each folder: select all `.swift` files inside it in the Project Navigator,
open File Inspector (⌥⌘1), and tick **LOCAMac** under Target Membership.

| Folder | Add to LOCAMac? | Notes |
|--------|-----------------|-------|
| `ios/LOCA/Core/` | ✅ yes — all files | Models, persistence, DS tokens, extensions |
| `ios/LOCA/Analytics/` | ✅ yes — all files | HeatmapDataProvider, StreakCalculator |
| `ios/LOCA/Features/HabitDetail/` | ✅ yes — all files | RefHeatCell, WeekdaysChartView |
| `ios/LOCA/Features/HabitManagement/` | ✅ yes — all files | SimpleHabitCreationView, ReflectionGenerator |
| `ios/LOCA/Features/Life/` | ⏳ skip for now | Contains iOS-only view modifiers; add in S-chapter when Mac Life section is built |
| `ios/LOCA/Features/Dashboard/` | ❌ iOS only | Mac has its own habit/today columns |
| `ios/LOCA/Features/PersonalLifeView/` | ❌ iOS only | Not referenced by any Mac view |
| `ios/LOCA/Features/Present/` | ❌ iOS only | Not referenced by any Mac view |
| `ios/LOCA/Features/Settings/` | ❌ iOS only | Not referenced by any Mac view |
| `ios/LOCA/App/LOCAApp.swift` | ❌ iOS only | Mac entry point is `mac/App/LOCAMacApp.swift` |
| `ios/LOCA/App/AppRootView.swift` | ❌ iOS only | |
| `ios/LOCA/App/` (other files) | ❌ iOS only | Coordinators, WidgetRefresh, etc. |
| `ios/LOCA/Intents/` | ❌ iOS only | |
| `ios/LOCAWidget/` | ❌ iOS only | |

> **Why not Dashboard or Life?**  
> Several files in those folders call `.navigationBarTitleDisplayMode(.inline)`
> which is iOS-only and causes a build error on macOS. The Mac app has its own
> column-based navigation and doesn't need those views. Add `Features/Life/`
> when the S-chapter Mac Life surface is implemented.

### 4. Build settings for LOCAMac target

Open the project settings, select the **LOCAMac** target, then the
**Build Settings** tab:

| Setting | Value |
|---------|-------|
| `MACOSX_DEPLOYMENT_TARGET` | `14.0` |
| `SWIFT_ACTIVE_COMPILATION_CONDITIONS` (Debug) | add `LOCAL_DEVELOPMENT` |
| `PRODUCT_BUNDLE_IDENTIFIER` | `com.mihirmaru.loca.mac` |
| `INFOPLIST_FILE` | `mac/Info.plist` |

`LOCAL_DEVELOPMENT` tells `ModelContainerFactory` to use a local SQLite file
(no App Group, no CloudKit). Without it the build tries to use the shared App
Group which requires paid-account provisioning.

### 5. Entitlements — disable sandbox for local dev

Create the file `mac/LOCAMac-Debug.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
</dict>
</plist>
```

Then in LOCAMac Build Settings set:
- `CODE_SIGN_ENTITLEMENTS` (Debug) → `mac/LOCAMac-Debug.entitlements`

This lets SwiftData write to the default Application Support directory without
needing an App Group entitlement (which requires a paid Apple Developer account).

### 6. Build and run

1. Select the **LOCAMac** scheme in Xcode's scheme picker.
2. Set the run destination to **My Mac**.
3. Press **⌘R**.

The app launches as a three-pane `NavigationSplitView`. The Habits section
opens by default. Use the sidebar to switch to Today (tasks), Journal, or
Life (stub until S-chapters land).

---

## Troubleshooting

### "Value of type '…' has no member 'navigationBarTitleDisplayMode'"
You accidentally added a Dashboard, Life, or PersonalLifeView file to the
LOCAMac target. Open those files in File Inspector (⌥⌘1) and untick
LOCAMac under Target Membership.

### "Multiple commands produce '…LOCAMacApp'"
Two `@main` entry points are both in the LOCAMac target. Make sure
`ios/LOCA/App/LOCAApp.swift` is **NOT** in LOCAMac's target membership.

### "No such module 'SwiftData'" / "No such module 'SwiftUI'"
Check that Deployment Target for LOCAMac is set to **macOS 14.0** (not lower).

### SwiftData store is empty on first launch
Normal — the `LOCAL_DEVELOPMENT` container starts fresh on each new install.
`DebugSeeder` seeds a handful of sample habits automatically in `#if DEBUG`
builds so you have data to look at immediately.

### App crashes on launch with "Failed to create ModelContainer"
Usually a schema mismatch after pulling new commits. Delete the app and
re-run (`⌘R`) to start with a fresh store.
