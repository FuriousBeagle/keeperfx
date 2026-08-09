#!/bin/sh
set -eu

if [ "$#" -ne 1 ]; then
    echo "usage: $0 <luajit-source-dir>" >&2
    exit 2
fi

LUAJIT_SRC="$1"
SDK_NAME="${KFX_IOS_SDK:-iphoneos}"
ARCH="${KFX_IOS_ARCH:-arm64}"
SDK_PATH="$(xcrun --sdk "$SDK_NAME" --show-sdk-path)"
CLANG="$(xcrun --sdk "$SDK_NAME" --find clang)"
CLANG_DIR="$(dirname "$CLANG")"
HOST_CLANG="$(xcrun --sdk macosx --find clang)"
HOST_ARCH="$(uname -m)"
TARGET_FLAGS="-arch ${ARCH} -isysroot ${SDK_PATH}"

if [ -n "${KFX_IOS_DEPLOYMENT_TARGET:-}" ]; then
    TARGET_FLAGS="${TARGET_FLAGS} -miphoneos-version-min=${KFX_IOS_DEPLOYMENT_TARGET}"
fi

# LuaJIT's build first creates minilua/buildvm and executes those tools on the
# build host. Xcode propagates the iOS cross-compilation environment into this
# custom command, so force those helpers to be native macOS executables while
# keeping the LuaJIT target objects on the iOS ARM64 toolchain.
HOST_CC="${HOST_CLANG} -arch ${HOST_ARCH}"

# Build minilua on its own first so CI can tell us exactly what macOS is being
# asked to execute. This is deliberately diagnostic: once the host-tool issue is
# understood these probes can be removed.
make -C "$LUAJIT_SRC/src" clean >/dev/null 2>&1 || true
make -C "$LUAJIT_SRC/src" \
    HOST_CC="$HOST_CC" \
    host/minilua

MINILUA="$LUAJIT_SRC/src/host/minilua"
echo "==== LuaJIT host tool diagnostics ===="
echo "host architecture: ${HOST_ARCH}"
echo "host compiler: ${HOST_CLANG}"
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
    CROSS="${CLANG_DIR}/" \
    TARGET_FLAGS="${TARGET_FLAGS}" \
    TARGET_SYS=iOS
