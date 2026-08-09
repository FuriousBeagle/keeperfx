# Platforms.cmake - platform detection + directory-scope compile definitions.

if(WIN32)
    kfx_status("PLATFORM" "Windows / MinGW-w64 (i686)")
elseif(APPLE AND CMAKE_SYSTEM_NAME STREQUAL "iOS")
    kfx_status("PLATFORM" "iOS / ARM64")
    # Keep both CMake-time platform selection and source-level conditionals in
    # sync. add_compile_definitions() alone does not create a CMake variable,
    # so guards such as if(KFX_IOS) would otherwise evaluate false.
    set(KFX_IOS TRUE)
    add_compile_definitions(KFX_IOS=1)
elseif(UNIX AND NOT APPLE)
    kfx_status("PLATFORM" "Linux (x86_64)")
else()
    message(FATAL_ERROR "Unsupported platform (only Windows/MinGW, Linux and iOS are supported)")
endif()

add_compile_definitions("DEBUG=$<IF:$<CONFIG:Debug>,1,0>")

# Static-linkage defines for the prebuilt Windows dependencies.
if(WIN32)
    add_compile_definitions(_CRT_NONSTDC_NO_WARNINGS _CRT_SECURE_NO_WARNINGS)
    add_compile_definitions(SPNG_STATIC=1 AL_LIBTYPE_STATIC)
endif()
