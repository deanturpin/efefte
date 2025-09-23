cmake_minimum_required(VERSION 3.25)
project(KEYQStandalone)

# macOS only
if(NOT APPLE)
    message(FATAL_ERROR "Standalone app is currently only supported on macOS")
endif()

# Find required frameworks
find_library(COCOA_FRAMEWORK Cocoa)
find_library(AVFOUNDATION_FRAMEWORK AVFoundation)
find_library(COREAUDIO_FRAMEWORK CoreAudio)

# Include parent KEYQ library
include_directories(${CMAKE_SOURCE_DIR}/include)

# Standalone application
add_executable(KEYQStandalone MACOSX_BUNDLE
    main.mm
)

# Enable ARC for Objective-C++
target_compile_options(KEYQStandalone PRIVATE -fobjc-arc)

# Set app properties
set_target_properties(KEYQStandalone PROPERTIES
    MACOSX_BUNDLE_INFO_STRING "Turbeaux Sounds KEYQ - Spectrum Analyser"
    MACOSX_BUNDLE_GUI_IDENTIFIER "com.turbeaux.keyq.standalone"
    MACOSX_BUNDLE_BUNDLE_NAME "Turbeaux Sounds KEYQ"
    MACOSX_BUNDLE_BUNDLE_VERSION "1.0"
    MACOSX_BUNDLE_SHORT_VERSION_STRING "1.0"
)

# Link frameworks and libraries
target_link_libraries(KEYQStandalone
    ${COCOA_FRAMEWORK}
    ${AVFOUNDATION_FRAMEWORK}
    ${COREAUDIO_FRAMEWORK}
    libkeyq
)

# Copy to Applications folder for easy access
add_custom_command(TARGET KEYQStandalone POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
        $<TARGET_BUNDLE_DIR:KEYQStandalone>
        ${CMAKE_BINARY_DIR}/KEYQStandalone.app
    COMMENT "Creating standalone app..."
)