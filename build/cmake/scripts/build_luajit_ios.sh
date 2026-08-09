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
HOST_ARCH="$(uname -m)"
TARGET_FLAGS="-arch ${ARCH} -isysroot ${SDK_PATH} -miphoneos-version-min=${DEPLOYMENT_TARGET}"

# LuaJIT's Darwin/iOS Makefile expects this variable to be present while it
# detects and builds the host tools. Keep it aligned with the iOS deployment
# target used by the generated Xcode project.
export MACOSX_DEPLOYMENT_TARGET="${DEPLOYMENT_TARGET}"

# LuaJIT first builds minilua/buildvm and executes them on the macOS build host.
# Force those helpers to be native Apple Silicon executables. GitHub's arm64
# runner produced an unsigned minilua that macOS terminated with SIGKILL, so
# explicitly request the linker's ad-hoc signature for every LuaJIT host tool.
HOST_CC="${HOST_CLANG} -arch ${HOST_ARCH}"
HOST_LDFLAGS="-Wl,-adhoc_codesign"

# Build minilua on its own first so CI can verify the resulting host executable
# before the full LuaJIT cross-build starts.
make -C "$LUAJIT_SRC/src" clean >/dev/null 2>&1 || true
make -C "$LUAJIT_SRC/src" \
    HOST_CC="$HOST_CC" \
    HOST_LDFLAGS="$HOST_LDFLAGS" \
    host/minilua

MINILUA="$LUAJIT_SRC/src/host/minilua"

# Be defensive in case an older linker ignores -adhoc_codesign. This requires no
# signing identity and is only for the native build-host helper.
if ! codesign -v "$MINILUA" >/dev/null 2>&1; then
    codesign --force --sign - "$MINILUA"
fi

echo "==== LuaJIT host tool diagnostics ===="
echo "host architecture: ${HOST_ARCH}"
echo "host compiler: ${HOST_CLANG}"
echo "deployment target: ${MACOSX_DEPLOYMENT_TARGET}"
file "$MINILUA" || true
lipo -info "$MINILUA" || true
otool -L "$MINILUA" || true
codesign -dvv "$MINILUA" 2>&1 || true
xattr -l "$MINILUA" 2>&1 || true
echo "---- executing minilua ----"
"$MINILUA" -v

echo "==== Building LuaJIT 2.1 for iOS ===="
# TARGET_SYS=iOS disables runtime JIT code generation while retaining the fast
# interpreter and Lua 5.1-compatible API.
make -C "$LUAJIT_SRC" \
    BUILDMODE=static \
    DEFAULT_CC=clang \
    HOST_CC="$HOST_CC" \
    HOST_LDFLAGS="$HOST_LDFLAGS" \
    CROSS="${CLANG_DIR}/" \
    TARGET_FLAGS="${TARGET_FLAGS}" \
    TARGET_SYS=iOS
