# DependenciesIOS.cmake - source-built dependencies for iOS/ARM64.
#
# Keep this isolated from the established Windows and Linux dependency paths.
# The first iOS milestone intentionally omits FFmpeg movie playback, automatic
# port forwarding, and web matchmaking; those source modules are replaced with
# small iOS stubs in BuildTargets.cmake.

include(FetchContent)

set(BUILD_SHARED_LIBS OFF CACHE BOOL "" FORCE)
set(BUILD_TESTING OFF CACHE BOOL "" FORCE)

# -----------------------------------------------------------------------------
# SDL3 + image + mixer
# Use git checkouts so SDL_image/SDL_mixer can obtain their vendored decoder
# submodules when building for an Apple target without a system package manager.
set(SDL_TEST_LIBRARY OFF CACHE BOOL "" FORCE)
set(SDL_TESTS OFF CACHE BOOL "" FORCE)
set(SDL_EXAMPLES OFF CACHE BOOL "" FORCE)
set(SDLIMAGE_SAMPLES OFF CACHE BOOL "" FORCE)
set(SDLIMAGE_TESTS OFF CACHE BOOL "" FORCE)
set(SDLIMAGE_VENDORED ON CACHE BOOL "" FORCE)
set(SDLMIXER_SAMPLES OFF CACHE BOOL "" FORCE)
set(SDLMIXER_TESTS OFF CACHE BOOL "" FORCE)
set(SDLMIXER_VENDORED ON CACHE BOOL "" FORCE)

FetchContent_Declare(SDL3
    GIT_REPOSITORY https://github.com/libsdl-org/SDL.git
    GIT_TAG release-3.4.12
    GIT_SHALLOW TRUE)
FetchContent_Declare(SDL3_image
    GIT_REPOSITORY https://github.com/libsdl-org/SDL_image.git
    GIT_TAG release-3.4.4
    GIT_SHALLOW TRUE
    GIT_SUBMODULES_RECURSE TRUE)
FetchContent_Declare(SDL3_mixer
    GIT_REPOSITORY https://github.com/libsdl-org/SDL_mixer.git
    GIT_TAG release-3.2.4
    GIT_SHALLOW TRUE
    GIT_SUBMODULES_RECURSE TRUE)
FetchContent_MakeAvailable(SDL3 SDL3_image SDL3_mixer)

add_library(kfx_sdl3 INTERFACE)
target_link_libraries(kfx_sdl3 INTERFACE
    SDL3::SDL3
    SDL3_image::SDL3_image
    SDL3_mixer::SDL3_mixer)

# -----------------------------------------------------------------------------
# zlib + classic minizip
FetchContent_Declare(kfx_zlib
    GIT_REPOSITORY https://github.com/madler/zlib.git
    GIT_TAG v1.3.1
    GIT_SHALLOW TRUE)
FetchContent_MakeAvailable(kfx_zlib)

# zlib's CMake project exposes zlibstatic when BUILD_SHARED_LIBS is disabled.
add_library(zlib_static ALIAS zlibstatic)

add_library(minizip_static STATIC
    "${kfx_zlib_SOURCE_DIR}/contrib/minizip/ioapi.c"
    "${kfx_zlib_SOURCE_DIR}/contrib/minizip/mztools.c"
    "${kfx_zlib_SOURCE_DIR}/contrib/minizip/unzip.c"
    "${kfx_zlib_SOURCE_DIR}/contrib/minizip/zip.c")
target_include_directories(minizip_static PUBLIC
    "${kfx_zlib_SOURCE_DIR}"
    "${kfx_zlib_BINARY_DIR}"
    "${kfx_zlib_SOURCE_DIR}/contrib/minizip")
target_link_libraries(minizip_static PUBLIC zlibstatic)

# -----------------------------------------------------------------------------
# libspng
# Build the single library source directly so it reuses the zlib target above
# instead of trying to discover a host/system zlib during cross compilation.
FetchContent_Declare(kfx_spng
    GIT_REPOSITORY https://github.com/randy408/libspng.git
    GIT_TAG v0.7.4
    GIT_SHALLOW TRUE)
FetchContent_GetProperties(kfx_spng)
if(NOT kfx_spng_POPULATED)
    FetchContent_Populate(kfx_spng)
endif()
add_library(spng_static STATIC "${kfx_spng_SOURCE_DIR}/spng/spng.c")
target_include_directories(spng_static PUBLIC "${kfx_spng_SOURCE_DIR}/spng")
target_link_libraries(spng_static PUBLIC zlibstatic)
target_compile_definitions(spng_static PUBLIC SPNG_STATIC=1)

# -----------------------------------------------------------------------------
# centijson + KeeperFX's centitoml adapter
FetchContent_Declare(kfx_centijson
    GIT_REPOSITORY https://github.com/mity/centijson.git
    GIT_TAG master
    GIT_SHALLOW TRUE)
FetchContent_GetProperties(kfx_centijson)
if(NOT kfx_centijson_POPULATED)
    FetchContent_Populate(kfx_centijson)
endif()
add_library(centijson_static STATIC
    "${kfx_centijson_SOURCE_DIR}/src/json.c"
    "${kfx_centijson_SOURCE_DIR}/src/json-dom.c"
    "${kfx_centijson_SOURCE_DIR}/src/json-ptr.c"
    "${kfx_centijson_SOURCE_DIR}/src/value.c")
target_include_directories(centijson_static PUBLIC "${kfx_centijson_SOURCE_DIR}/src")

add_library(centitoml OBJECT "${KFX_CENTITOML_SRC}/toml_api.c")
target_link_libraries(centitoml PUBLIC centijson_static)
target_include_directories(centitoml INTERFACE "${KFX_CENTITOML_SRC}")

# -----------------------------------------------------------------------------
# Astronomy Engine - KeeperFX only needs the portable C implementation.
FetchContent_Declare(kfx_astronomy
    GIT_REPOSITORY https://github.com/cosinekitty/astronomy.git
    GIT_TAG v2.1.19
    GIT_SHALLOW TRUE)
FetchContent_GetProperties(kfx_astronomy)
if(NOT kfx_astronomy_POPULATED)
    FetchContent_Populate(kfx_astronomy)
endif()
add_library(astronomy_static STATIC "${kfx_astronomy_SOURCE_DIR}/source/c/astronomy.c")
target_include_directories(astronomy_static PUBLIC "${kfx_astronomy_SOURCE_DIR}/source/c")
target_link_libraries(astronomy_static PUBLIC m)

# -----------------------------------------------------------------------------
# ENet6 - keep the underlying multiplayer transport available. Web matchmaking
# and router port-forward helpers are deferred separately for the first iOS MVP.
FetchContent_Declare(kfx_enet6
    GIT_REPOSITORY https://github.com/SirLynix/enet6.git
    GIT_TAG v6.1.3
    GIT_SHALLOW TRUE)
FetchContent_MakeAvailable(kfx_enet6)
add_library(enet6_static ALIAS enet6)

# -----------------------------------------------------------------------------
# OpenAL Soft, using Apple's CoreAudio backend.
set(LIBTYPE STATIC CACHE STRING "" FORCE)
set(ALSOFT_EXAMPLES OFF CACHE BOOL "" FORCE)
set(ALSOFT_UTILS OFF CACHE BOOL "" FORCE)
set(ALSOFT_NO_CONFIG_UTIL ON CACHE BOOL "" FORCE)
set(ALSOFT_INSTALL OFF CACHE BOOL "" FORCE)
set(ALSOFT_INSTALL_CONFIG OFF CACHE BOOL "" FORCE)
set(ALSOFT_INSTALL_HRTF_DATA OFF CACHE BOOL "" FORCE)
set(ALSOFT_INSTALL_AMBDEC_PRESETS OFF CACHE BOOL "" FORCE)
set(ALSOFT_INSTALL_EXAMPLES OFF CACHE BOOL "" FORCE)
set(ALSOFT_INSTALL_UTILS OFF CACHE BOOL "" FORCE)
set(ALSOFT_EAX OFF CACHE BOOL "" FORCE)
set(ALSOFT_BACKEND_COREAUDIO ON CACHE BOOL "" FORCE)
FetchContent_Declare(kfx_openal
    GIT_REPOSITORY https://github.com/kcat/openal-soft.git
    GIT_TAG 1.25.1
    GIT_SHALLOW TRUE)
FetchContent_MakeAvailable(kfx_openal)
add_library(openal_static ALIAS OpenAL)

# -----------------------------------------------------------------------------
# LuaJIT. Its upstream build system explicitly supports iOS; TARGET_SYS=iOS
# disables runtime JIT code generation and builds the interpreter for ARM64.
FetchContent_Declare(kfx_luajit
    GIT_REPOSITORY https://github.com/LuaJIT/LuaJIT.git
    GIT_TAG v2.1
    GIT_SHALLOW TRUE)
FetchContent_GetProperties(kfx_luajit)
if(NOT kfx_luajit_POPULATED)
    FetchContent_Populate(kfx_luajit)
endif()

set(KFX_LUAJIT_LIB "${kfx_luajit_SOURCE_DIR}/src/libluajit.a")
add_custom_command(
    OUTPUT "${KFX_LUAJIT_LIB}"
    COMMAND ${CMAKE_COMMAND} -E env
        "KFX_IOS_ARCH=${CMAKE_OSX_ARCHITECTURES}"
        "KFX_IOS_DEPLOYMENT_TARGET=${CMAKE_OSX_DEPLOYMENT_TARGET}"
        /bin/sh "${CMAKE_SOURCE_DIR}/build/cmake/scripts/build_luajit_ios.sh" "${kfx_luajit_SOURCE_DIR}"
    WORKING_DIRECTORY "${kfx_luajit_SOURCE_DIR}"
    COMMENT "Building LuaJIT interpreter for iOS"
    VERBATIM)
add_custom_target(kfx_luajit_build DEPENDS "${KFX_LUAJIT_LIB}")
add_library(luajit_static STATIC IMPORTED GLOBAL)
set_target_properties(luajit_static PROPERTIES
    IMPORTED_LOCATION "${KFX_LUAJIT_LIB}"
    INTERFACE_INCLUDE_DIRECTORIES "${kfx_luajit_SOURCE_DIR}/src")
add_dependencies(luajit_static kfx_luajit_build)

function(kfx_link_ios_dependencies TARGET)
    target_link_libraries(${TARGET} PRIVATE
        kfx_sdl3
        openal_static astronomy_static enet6_static
        spng_static centijson_static minizip_static zlibstatic
        luajit_static centitoml
        "-framework AudioToolbox"
        "-framework AVFoundation"
        "-framework CoreAudio"
        "-framework CoreFoundation"
        "-framework CoreGraphics"
        "-framework CoreHaptics"
        "-framework CoreMotion"
        "-framework Foundation"
        "-framework GameController"
        "-framework Metal"
        "-framework QuartzCore"
        "-framework UIKit")
endfunction()
