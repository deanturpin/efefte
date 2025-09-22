cmake_minimum_required(VERSION 3.25)
project(EFEFTEStandalone)

# macOS only
if(NOT APPLE)
    message(FATAL_ERROR "Standalone app is currently only supported on macOS")
endif()

# Find required frameworks
find_library(COCOA_FRAMEWORK Cocoa)
find_library(AVFOUNDATION_FRAMEWORK AVFoundation)
find_library(COREAUDIO_FRAMEWORK CoreAudio)

# Include parent EFEFTE library
include_directories(${CMAKE_SOURCE_DIR}/include)

# Standalone application
add_executable(EFEFTEStandalone MACOSX_BUNDLE
    main.mm
)

# Enable ARC for Objective-C++
target_compile_options(EFEFTEStandalone PRIVATE -fobjc-arc)

# Set app properties
set_target_properties(EFEFTEStandalone PROPERTIES
    MACOSX_BUNDLE_INFO_STRING "Turbeaux Sounds EFEFTE - Spectrum Analyser"
    MACOSX_BUNDLE_GUI_IDENTIFIER "com.turbeaux.efefte.standalone"
    MACOSX_BUNDLE_BUNDLE_NAME "Turbeaux Sounds EFEFTE"
    MACOSX_BUNDLE_BUNDLE_VERSION "1.0"
    MACOSX_BUNDLE_SHORT_VERSION_STRING "1.0"
)

# Link frameworks and libraries
target_link_libraries(EFEFTEStandalone
    ${COCOA_FRAMEWORK}
    ${AVFOUNDATION_FRAMEWORK}
    ${COREAUDIO_FRAMEWORK}
    libefefte
)

# Copy to Applications folder for easy access
add_custom_command(TARGET EFEFTEStandalone POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
        $<TARGET_BUNDLE_DIR:EFEFTEStandalone>
        ${CMAKE_BINARY_DIR}/EFEFTEStandalone.app
    COMMENT "Creating standalone app..."
)