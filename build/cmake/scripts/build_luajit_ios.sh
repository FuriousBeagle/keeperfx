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
TARGET_FLAGS="-arch ${ARCH} -isysroot ${SDK_PATH}"

if [ -n "${KFX_IOS_DEPLOYMENT_TARGET:-}" ]; then
    TARGET_FLAGS="${TARGET_FLAGS} -miphoneos-version-min=${KFX_IOS_DEPLOYMENT_TARGET}"
fi

# LuaJIT has first-class iOS support. TARGET_SYS=iOS disables the JIT compiler
# automatically while retaining the fast interpreter and Lua 5.1-compatible API.
make -C "$LUAJIT_SRC" \
    BUILDMODE=static \
    DEFAULT_CC=clang \
    CROSS="${CLANG_DIR}/" \
    TARGET_FLAGS="${TARGET_FLAGS}" \
    TARGET_SYS=iOS
