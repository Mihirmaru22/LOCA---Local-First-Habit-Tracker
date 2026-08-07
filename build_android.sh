#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANDROID_DIR="$SCRIPT_DIR/android"
APK_OUT="$ANDROID_DIR/androidApp/build/outputs/apk/debug/androidApp-debug.apk"

# ── Colour helpers ────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()    { echo -e "${CYAN}[LOCA]${NC} $*"; }
success() { echo -e "${GREEN}[LOCA]${NC} $*"; }
warn()    { echo -e "${YELLOW}[LOCA]${NC} $*"; }
error()   { echo -e "${RED}[LOCA]${NC} $*" >&2; }

# ── Java check ────────────────────────────────────────────────────────────────
if ! command -v java &>/dev/null; then
    error "Java not found. Install Java 17+ (e.g. via SDKMAN: sdk install java 17-zulu)"
    exit 1
fi

JAVA_VER=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}' | cut -d. -f1)
if [[ "$JAVA_VER" -lt 17 ]]; then
    error "Java 17+ required (found Java $JAVA_VER). Switch with JAVA_HOME or SDKMAN."
    exit 1
fi
info "Java $JAVA_VER ✓"

# ── Android SDK check ─────────────────────────────────────────────────────────
ANDROID_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}"
if [[ -z "$ANDROID_HOME" ]]; then
    # Common install locations
    for candidate in \
        "$HOME/Library/Android/sdk" \
        "$HOME/Android/Sdk" \
        "/opt/android-sdk" \
        "/usr/local/lib/android/sdk"; do
        if [[ -d "$candidate" ]]; then
            ANDROID_HOME="$candidate"
            export ANDROID_HOME
            export ANDROID_SDK_ROOT="$ANDROID_HOME"
            warn "ANDROID_HOME not set — guessed $ANDROID_HOME"
            break
        fi
    done
fi

if [[ -z "$ANDROID_HOME" || ! -d "$ANDROID_HOME" ]]; then
    error "Android SDK not found. Set ANDROID_HOME to your SDK directory."
    error "  e.g.  export ANDROID_HOME=\$HOME/Library/Android/sdk"
    exit 1
fi
info "Android SDK: $ANDROID_HOME ✓"

# ── local.properties ──────────────────────────────────────────────────────────
LOCAL_PROPS="$ANDROID_DIR/local.properties"
if [[ ! -f "$LOCAL_PROPS" ]] || ! grep -q "sdk.dir" "$LOCAL_PROPS" 2>/dev/null; then
    echo "sdk.dir=$ANDROID_HOME" > "$LOCAL_PROPS"
    info "Wrote sdk.dir to local.properties"
fi

# ── Build ─────────────────────────────────────────────────────────────────────
VARIANT="${1:-debug}"   # pass 'release' as first arg for release build

if [[ "$VARIANT" == "release" ]]; then
    TASK="assembleRelease"
    APK_OUT="$ANDROID_DIR/androidApp/build/outputs/apk/release/androidApp-release-unsigned.apk"
else
    TASK="assembleDebug"
fi

info "Building LOCA Android ($VARIANT)…"
cd "$ANDROID_DIR"

if [[ "${CLEAN:-0}" == "1" ]]; then
    info "Clean requested — running ./gradlew clean first"
    ./gradlew clean
fi

./gradlew "$TASK" --stacktrace

# ── Result ────────────────────────────────────────────────────────────────────
if [[ -f "$APK_OUT" ]]; then
    SIZE=$(du -sh "$APK_OUT" | cut -f1)
    success "APK ready ($SIZE)"
    success "  $APK_OUT"
    echo ""
    echo "  Install on a connected device:"
    echo "    adb install -r \"$APK_OUT\""
else
    error "Build finished but APK not found at expected path:"
    error "  $APK_OUT"
    exit 1
fi
