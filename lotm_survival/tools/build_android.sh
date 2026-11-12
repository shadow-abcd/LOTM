#!/bin/sh
# Builds a signed debug APK with the "Android" export preset.
#
#   tools/build_android.sh [godot-binary] [output.apk]
#
# Requirements, one time:
#   * Godot 4.3 export templates installed (Editor > Manage Export Templates)
#   * JDK 17+ and an Android SDK with platform-tools + build-tools
#   * Editor Settings: export/android/java_sdk_path, export/android/android_sdk_path,
#     export/android/debug_keystore (+ debug_keystore_user / _pass)
#   If no keystore is configured, one can be made with:
#     keytool -keyalg RSA -genkeypair -alias androiddebugkey -keypass android \
#       -keystore ~/.local/share/godot/keystores/debug.keystore -storepass android \
#       -dname "CN=Android Debug,O=Android,C=US" -validity 9999 -deststoretype pkcs12
#
# The project must also have rendering/textures/vram_compression/import_etc2_astc
# enabled, or Godot refuses the export with an empty configuration error.
cd "$(dirname "$0")/.." || exit 1

GODOT="${1:-${GODOT_BIN:-godot}}"
OUT="${2:-build/lotm-survival.apk}"
mkdir -p "$(dirname "$OUT")"

if ! command -v "$GODOT" >/dev/null 2>&1 && [ ! -x "$GODOT" ]; then
	echo "build_android: godot binary not found ($GODOT)" >&2
	exit 2
fi

"$GODOT" --headless --path . --export-debug "Android" "$OUT" || exit 1

if [ -f "${ANDROID_SDK_ROOT:-$HOME/android-sdk}/build-tools"/*/apksigner ]; then
	APKSIGNER="$(ls "${ANDROID_SDK_ROOT:-$HOME/android-sdk}"/build-tools/*/apksigner | tail -1)"
	"$APKSIGNER" verify --verbose "$OUT" | head -3
fi
echo "build_android: $OUT ($(du -h "$OUT" | cut -f1))"
