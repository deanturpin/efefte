cmake_minimum_required(VERSION 3.25)

project(keyq
    VERSION 0.1.0
    DESCRIPTION "High-performance FFT library as drop-in FFTW3 replacement"
    LANGUAGES CXX)

# Require latest C++ standard (Clang supports C++23)
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Set file extensions
set(CMAKE_CXX_SOURCE_FILE_EXTENSIONS cxx)

# Compiler-specific options
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    add_compile_options(-Wall -Wextra -Wpedantic -O3 -march=native)
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    add_compile_options(-Wall -Wextra -Wpedantic -O3 -march=native)
elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    add_compile_options(/W4 /O2)
endif()

# Find dependencies (optional)
find_package(PkgConfig QUIET)
if(PkgConfig_FOUND)
    pkg_check_modules(FFTW3 IMPORTED_TARGET fftw3)
endif()

# Include directories
include_directories(include)

# Library target (our FFTW3 replacement)
add_library(libkeyq SHARED src/keyq.cxx src/test.cxx)
set_target_properties(libkeyq PROPERTIES
    OUTPUT_NAME keyq
    VERSION ${PROJECT_VERSION}
    SOVERSION ${PROJECT_VERSION_MAJOR})

# Main executable (test application)
add_executable(keyq src/main.cxx)
target_link_libraries(keyq libkeyq)

# Optional: Link with real FFTW3 for comparison benchmarks
if(FFTW3_FOUND)
    add_executable(keyq_benchmark src/main.cxx)
    target_link_libraries(keyq_benchmark PkgConfig::FFTW3)
    target_compile_definitions(keyq_benchmark PRIVATE USE_REAL_FFTW3)
endif()

# Install targets (to user directories to avoid sudo)
install(TARGETS keyq libkeyq
    RUNTIME DESTINATION ~/bin
    LIBRARY DESTINATION ~/lib
    ARCHIVE DESTINATION ~/lib)

install(FILES include/keyq.h DESTINATION ~/include)

# Testing and benchmarking (will be added later)
enable_testing()

# Plugins (macOS only, requires Clang for Objective-C++)
if(APPLE AND (CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang"))
    option(BUILD_AUDIO_UNIT "Build Audio Unit plugin for Logic Pro" ON)
    option(BUILD_STANDALONE "Build standalone spectrum analyser app" ON)

    if(BUILD_AUDIO_UNIT)
        add_subdirectory(plugin/AudioUnit)
    endif()

    if(BUILD_STANDALONE)
        add_subdirectory(plugin/Standalone)
    endif()
elseif(APPLE)
    message(STATUS "Skipping Objective-C++ plugins (requires Clang, currently using ${CMAKE_CXX_COMPILER_ID})")
endif()

# Package configuration
include(CMakePackageConfigHelpers)
write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/keyqConfigVersion.cmake"
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion)

install(FILES
    "${CMAKE_CURRENT_BINARY_DIR}/keyqConfigVersion.cmake"
    DESTINATION ~/lib/cmake/keyq)