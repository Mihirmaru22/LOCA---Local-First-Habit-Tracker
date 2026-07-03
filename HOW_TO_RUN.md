# Running LOCA in Xcode

## Prerequisites
- Xcode 16+
- An Apple Developer account (free or paid — paid required for CloudKit/App Groups on a real device)

## First Open
1. Double-click `LOCA.xcodeproj` (or `File → Open` in Xcode).
2. Select the **LOCA** project in the navigator → **Signing & Capabilities** tab, for **both** the `LOCA` and `LOCAWidgetExtension` targets:
   - Set your **Team**.
   - Xcode will auto-generate real bundle identifiers if `com.mihirmaru.loca` / `com.mihirmaru.loca.widget` aren't available to you — that's fine, let it.
3. Still in **Signing & Capabilities**, confirm both targets show:
   - **App Groups** → `group.com.mihirmaru.loca` (Xcode will offer to create this under your Team if it doesn't exist — accept)
   - **iCloud → CloudKit** → `iCloud.com.mihirmaru.loca` (same — let Xcode create it)
   - If Xcode renames either identifier during auto-fix, update the matching string in `ModelContainerFactory.swift` (`appGroupIdentifier`) to match exactly. A mismatch here fails silently — no crash, just an empty database.

## Build & Run
1. Pick the **LOCA** scheme (already selected by default) and an iPhone or Mac destination.
2. **⌘B** to build first — this is the actual first compile of this project; treat any errors here as real findings, not something already checked. Report them back rather than guessing at fixes.
3. **⌘R** to run.

## Known Non-Issues (Expected, Not Bugs)
- **Missing app icon warning** — `AppIcon.appiconset` slots exist but are empty. Builds and runs fine without one.
- **No CloudKit sync activity in Simulator** without a signed-in iCloud account — expected, not broken.
- **Empty widget** if you add it to a Home Screen / Notification Center — `LOCAWidgetBundle.swift` intentionally registers zero widgets (Phase 9 scope).

## If the Build Fails
Send me the exact error text from the Xcode issue navigator — that's the first real compiler feedback this project has had, and it's genuinely useful signal for me to act on, not something to route around.
