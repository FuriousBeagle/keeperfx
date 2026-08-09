#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
    echo "usage: $0 <luajit-source-dir>" >&2
    exit 2
fi

LUAJIT_SRC="$1"
SDK_NAME="${KFX_IOS_SDK:-iphoneos}"
ARCH="${KFX_IOS_ARCH:-arm64}"
DEPLOYMENT_TARGET="${KFX_IOS_DEPLOYMENT_TARGET:-15.0}"
SDK_PATH="$(xcrun --sdk "$SDK_NAME" --show-sdk-path)"
CLANG="$(xcrun --sdk "$SDK_NAME" --find clang)"
CLANG_DIR="$(dirname "$CLANG")"
HOST_CLANG="$(xcrun --sdk macosx --find clang)"
HOST_SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
HOST_ARCH="$(uname -m)"
HOST_DEPLOYMENT_TARGET="$(sw_vers -productVersion | awk -F. '{print $1"."$2}')"
TARGET_FLAGS="-arch ${ARCH} -isysroot ${SDK_PATH} -miphoneos-version-min=${DEPLOYMENT_TARGET}"

# LuaJIT first builds minilua/buildvm and executes them on the macOS build host.
# Xcode's custom-build environment is an iPhoneOS environment, so make the host
# platform explicit: macOS SDK, native architecture and the runner's macOS
# deployment target. Otherwise an ARM64 Mach-O can still be tagged for iOS and
# be killed immediately when macOS attempts to execute it.
HOST_CC="${HOST_CLANG} -arch ${HOST_ARCH} -isysroot ${HOST_SDK_PATH} -mmacosx-version-min=${HOST_DEPLOYMENT_TARGET}"
HOST_LDFLAGS="-Wl,-adhoc_codesign -isysroot ${HOST_SDK_PATH} -mmacosx-version-min=${HOST_DEPLOYMENT_TARGET}"

make -C "$LUAJIT_SRC/src" clean >/dev/null 2>&1 || true
SDKROOT="$HOST_SDK_PATH" \
MACOSX_DEPLOYMENT_TARGET="$HOST_DEPLOYMENT_TARGET" \
make -C "$LUAJIT_SRC/src" \
    HOST_CC="$HOST_CC" \
    HOST_LDFLAGS="$HOST_LDFLAGS" \
    host/minilua

MINILUA="$LUAJIT_SRC/src/host/minilua"

if ! codesign -v "$MINILUA" >/dev/null 2>&1; then
    codesign --force --sign - "$MINILUA"
fi

echo "==== LuaJIT host tool diagnostics ===="
echo "host architecture: ${HOST_ARCH}"
echo "host compiler: ${HOST_CLANG}"
echo "host SDK: ${HOST_SDK_PATH}"
echo "host deployment target: ${HOST_DEPLOYMENT_TARGET}"
echo "iOS deployment target: ${DEPLOYMENT_TARGET}"
file "$MINILUA" || true
lipo -info "$MINILUA" || true
otool -L "$MINILUA" || true
otool -l "$MINILUA" | awk '/LC_BUILD_VERSION/{show=1; n=0} show{print; n++} n==8{show=0}' || true
codesign -dvv "$MINILUA" 2>&1 || true
xattr -l "$MINILUA" 2>&1 || true
echo "---- executing minilua ----"
MINILUA_PROBE="$LUAJIT_SRC/src/host/minilua-probe.lua"
printf '%s\n' 'print("minilua host probe OK")' > "$MINILUA_PROBE"
"$MINILUA" "$MINILUA_PROBE"
rm -f "$MINILUA_PROBE"

echo "==== Building LuaJIT 2.1 for iOS ===="
# LuaJIT's Darwin/iOS Makefile expects MACOSX_DEPLOYMENT_TARGET even for its iOS
# cross-build. Scope the iOS environment to the target build rather than leaking
# it into the native host-tool build above.
SDKROOT="$SDK_PATH" \
MACOSX_DEPLOYMENT_TARGET="$DEPLOYMENT_TARGET" \
make -C "$LUAJIT_SRC" \
    BUILDMODE=static \
    DEFAULT_CC=clang \
    HOST_CC="$HOST_CC" \
    HOST_LDFLAGS="$HOST_LDFLAGS" \
    CROSS="${CLANG_DIR}/" \
    TARGET_FLAGS="${TARGET_FLAGS}" \
    TARGET_SYS=iOS
