#!/bin/bash

# Turbeaux Sounds EFEFTE Installer Script

echo "Installing Turbeaux Sounds EFEFTE..."

# Create Components directory if it doesn't exist
COMPONENTS_DIR="$HOME/Library/Audio/Plug-Ins/Components"
if [ ! -d "$COMPONENTS_DIR" ]; then
    echo "Creating Components directory..."
    mkdir -p "$COMPONENTS_DIR"
fi

# Get the directory where this script is located (DMG mount point)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Install Audio Unit
if [ -d "$SCRIPT_DIR/EFEFTEAudioUnit.component" ]; then
    echo "Installing Audio Unit plugin to $COMPONENTS_DIR..."
    cp -R "$SCRIPT_DIR/EFEFTEAudioUnit.component" "$COMPONENTS_DIR/"
    echo "✅ Audio Unit installed successfully!"
else
    echo "⚠️  Audio Unit not found in installer package"
fi

# Install Standalone App
if [ -d "$SCRIPT_DIR/EFEFTEStandalone.app" ]; then
    echo "Installing Standalone app to /Applications..."
    cp -R "$SCRIPT_DIR/EFEFTEStandalone.app" /Applications/
    echo "✅ Standalone app installed successfully!"
else
    echo "⚠️  Standalone app not found in installer package"
fi

echo ""
echo "Installation complete!"
echo "Please restart Logic Pro to use the Turbeaux Sounds EFEFTE plugin."
echo ""
read -p "Press any key to close this installer..."