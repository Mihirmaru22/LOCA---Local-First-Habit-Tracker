# Xcode Project Verification Checklist

**Mandatory before every push that touches `LOCA.xcodeproj/project.pbxproj`.**
Adopted after a real defect: `LOCA.entitlements` sat at repository root from
Phase 0 onward while `CODE_SIGN_ENTITLEMENTS` expected `LOCA/LOCA.entitlements`.
Every prior structural check passed because it checksummed file *content* in
a scratch directory, never confirming the *tracked path* in the actual repo
resolved against what the build setting expects. This checklist closes that
specific blind spot.

## The Check

For every `PBXFileReference` and every `CODE_SIGN_ENTITLEMENTS` /
`INFOPLIST_FILE` / similar path-valued build setting in `project.pbxproj`:

1. Extract the exact path string as stored (case-sensitive, no normalization).
2. Resolve it as relative to the repository root (`SRCROOT`).
3. Confirm a file exists at that **exact** path in the **currently tracked
   working tree** — `git status` clean, not a scratch/output directory.
4. Fail immediately if any path doesn't resolve. Do not push until fixed.

## Why "tracked working tree," specifically

Checking a scratch directory (e.g. a generator's own output folder) proves
the generator produced correct output — it does not prove that output ever
actually reached the repository in the same shape. The defect this checklist
exists to prevent happened exactly there: correct in the generator's own
directory, silently wrong after being copied into the repo.

## Minimum Command

```bash
python3 -c "
import re, os
with open('LOCA.xcodeproj/project.pbxproj') as f:
    pbx = f.read()
paths = re.findall(r'path = \"?([^\";]+)\"?;', pbx)
real = [p for p in paths if any(p.endswith(e) for e in
        ['.swift', '.entitlements', '.plist', '.xcassets'])]
ents = re.findall(r'CODE_SIGN_ENTITLEMENTS = \"?([^\";]+)\"?;', pbx)
for p in ents:
    assert os.path.isfile(p), f'MISSING (entitlements): {p}'
print('All CODE_SIGN_ENTITLEMENTS paths resolve:', len(ents), 'checked')
"
```

Run this — or the fuller sweep across all `real` paths, not just
entitlements — against the actual `git`-tracked directory immediately before
every push that touches the project file. No exceptions.
