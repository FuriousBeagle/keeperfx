# BuildTargets.cmake - source collection, executables, per-target flags + linking.

file(GLOB_RECURSE KEEPERFX_SOURCES_C   CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/*.c")
file(GLOB_RECURSE KEEPERFX_SOURCES_CXX CONFIGURE_DEPENDS "${CMAKE_SOURCE_DIR}/src/*.cpp")

# Functional-test harness is off by default (FTEST_DEBUG defaults to 0).
list(FILTER KEEPERFX_SOURCES_C   EXCLUDE REGEX "/src/ftests/")
list(FILTER KEEPERFX_SOURCES_CXX EXCLUDE REGEX "/src/ftests/")

# Platform filtering (matches the hand Makefiles for desktop targets).
if(WIN32)
    list(FILTER KEEPERFX_SOURCES_C   EXCLUDE REGEX "/src/kfx/platform/ios/")
    list(FILTER KEEPERFX_SOURCES_CXX EXCLUDE REGEX "/src/kfx/platform/ios/|/src/linux\\.cpp$|/PlatformLinux\\.cpp$|/PlatformIOS\\.cpp$")
elseif(APPLE AND CMAKE_SYSTEM_NAME STREQUAL "iOS")
    # Initial iOS milestone: keep ENet multiplayer transport, but defer FFmpeg
    # movies, web matchmaking, and automatic NAT-PMP/UPnP port forwarding.
    # Small iOS replacements under src/kfx/platform/ios provide those APIs.
    list(FILTER KEEPERFX_SOURCES_C EXCLUDE REGEX "/src/net_matchmaking\\.c$")
    list(FILTER KEEPERFX_SOURCES_CXX EXCLUDE REGEX "/src/(bflib_fmvids|net_portforward|cdrom|steam_api|windows|linux)\\.cpp$|/Platform(Windows|Linux)\\.cpp$")
elseif(UNIX AND NOT APPLE)
    list(FILTER KEEPERFX_SOURCES_C   EXCLUDE REGEX "/src/kfx/platform/ios/")
    list(FILTER KEEPERFX_SOURCES_CXX EXCLUDE REGEX "/src/kfx/platform/ios/|/src/(cdrom|steam_api|windows)\\.cpp$|/PlatformWindows\\.cpp$|/PlatformIOS\\.cpp$")
endif()

add_executable(keeperfx       ${KEEPERFX_SOURCES_C} ${KEEPERFX_SOURCES_CXX})
add_executable(keeperfx_hvlog ${KEEPERFX_SOURCES_C} ${KEEPERFX_SOURCES_CXX})
target_compile_definitions(keeperfx       PUBLIC BFDEBUG_LEVEL=0)
target_compile_definitions(keeperfx_hvlog PUBLIC BFDEBUG_LEVEL=10)

set(KFX_TARGETS keeperfx keeperfx_hvlog)

if(WIN32)
    foreach(_t IN LISTS KFX_TARGETS)
        target_sources(${_t} PRIVATE "${CMAKE_SOURCE_DIR}/res/keeperfx_stdres.rc")
        # bfd is slow; prefer LLD when available (LINKER_TYPE needs CMake >= 3.29,
        # harmlessly ignored on older CMake, which uses the default linker).
        set_property(TARGET ${_t} PROPERTY LINKER_TYPE LLD)
    endforeach()
endif()

foreach(_t IN LISTS KFX_TARGETS)
    # Put src/ on the include path so sources in subdirectories (src/kfx/platform/, ...)
    # can use "pre_inc.h" and "kfx/platform/Foo.h" style includes.
    target_include_directories(${_t} PRIVATE "${CMAKE_SOURCE_DIR}/src")
    apply_keeperfx_warnings(${_t})
    apply_keeperfx_link_flags(${_t})
    kfx_link_dependencies(${_t})
    apply_windows_system_libs(${_t})
endforeach()

kfx_status("BUILD" "${CMAKE_CXX_COMPILER_ID} -> keeperfx, keeperfx_hvlog")
