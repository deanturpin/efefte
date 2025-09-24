cmake_minimum_required(VERSION 3.25)
project(KEYQAudioUnit)

# macOS only
if(NOT APPLE)
    message(FATAL_ERROR "Audio Units are only supported on macOS")
endif()

# Find required frameworks
find_library(AUDIOUNIT_FRAMEWORK AudioUnit)
find_library(AUDIOTOOLBOX_FRAMEWORK AudioToolbox)
find_library(COREAUDIO_FRAMEWORK CoreAudio)
find_library(COREFOUNDATION_FRAMEWORK CoreFoundation)
find_library(FOUNDATION_FRAMEWORK Foundation)
find_library(AVFOUNDATION_FRAMEWORK AVFoundation)

if(NOT AUDIOUNIT_FRAMEWORK)
    message(FATAL_ERROR "AudioUnit framework not found")
endif()

# Include parent KEYQ library
include_directories(${CMAKE_SOURCE_DIR}/include)

# Audio Unit bundle
add_library(KEYQAudioUnit MODULE
    ${CMAKE_CURRENT_SOURCE_DIR}/KEYQAudioUnit.mm
    ${CMAKE_CURRENT_SOURCE_DIR}/KEYQFactory.mm
)

# Use Clang for Objective-C++ with ARC support
set_target_properties(KEYQAudioUnit PROPERTIES
    CXX_COMPILER_LAUNCHER ""
)
target_compile_options(KEYQAudioUnit PRIVATE -fobjc-arc)

# Override compiler for this target (Objective-C++ needs Clang)
set_property(TARGET KEYQAudioUnit PROPERTY CXX_COMPILER /usr/bin/clang++)

# Set properties for Audio Unit bundle
set_target_properties(KEYQAudioUnit PROPERTIES
    BUNDLE TRUE
    BUNDLE_EXTENSION "component"
    MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_SOURCE_DIR}/Info.plist
    LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}
)

# Link frameworks and libraries
target_link_libraries(KEYQAudioUnit
    ${AUDIOUNIT_FRAMEWORK}
    ${AUDIOTOOLBOX_FRAMEWORK}
    ${COREAUDIO_FRAMEWORK}
    ${COREFOUNDATION_FRAMEWORK}
    ${FOUNDATION_FRAMEWORK}
    ${AVFOUNDATION_FRAMEWORK}
    libkeyq
)

# Installation
install(TARGETS KEYQAudioUnit
    COMPONENT "AudioUnit"
    LIBRARY DESTINATION "~/Library/Audio/Plug-Ins/Components"
)

# Post-build: Copy to Audio Units folder
add_custom_command(TARGET KEYQAudioUnit POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
        $<TARGET_BUNDLE_DIR:KEYQAudioUnit>
        "$ENV{HOME}/Library/Audio/Plug-Ins/Components/KEYQAudioUnit.component"
    COMMENT "Installing Audio Unit to ~/Library/Audio/Plug-Ins/Components/"
)

# Optional: Validate Audio Unit
add_custom_target(validate_au
    COMMAND auval -v aufx keyq Turb
    DEPENDS KEYQAudioUnit
    COMMENT "Validating Audio Unit with auval..."
)