.PHONY: all build clean format test benchmark install deploy release plugin run debug help

# Default target
all: build plugin run

# Configuration
BUILD_DIR = build
CMAKE_FLAGS = -DCMAKE_BUILD_TYPE=Release -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

# Build the project
build:
	@echo "Building EFEFTE..."
	mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && cmake $(CMAKE_FLAGS) ..
	cd $(BUILD_DIR) && make -j$(shell nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(BUILD_DIR)

# Format source code
format:
	@echo "Formatting source code..."
	find src include tests benchmarks -name "*.cxx" -o -name "*.h" | xargs clang-format -i

# Run tests
test: build
	@echo "Running tests..."
	cd $(BUILD_DIR) && ctest --output-on-failure

# Run benchmarks
benchmark: build
	@echo "Running benchmarks..."
	cd $(BUILD_DIR) && ./benchmarks/efefte_benchmark || echo "Benchmarks not built yet"

# Build plugins (macOS only)
plugin: build
	@echo "Building plugins..."
	@if [ "$$(uname)" = "Darwin" ]; then \
		echo "Building Audio Unit and Standalone app..."; \
	else \
		echo "Plugins only supported on macOS"; \
	fi

# Run standalone app in background
run: plugin
	@echo "Launching standalone spectrum analyser..."
	@open ./$(BUILD_DIR)/EFEFTEStandalone.app

# Install the library
install: build
	@echo "Installing EFEFTE..."
	cd $(BUILD_DIR) && make install

# Development helpers
debug:
	@echo "Building debug version..."
	mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ..
	cd $(BUILD_DIR) && make -j$(shell nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

# Deploy target with auto-commit and push
deploy: format build test
	@echo "Deploying changes..."
	git add -A
	git commit -m "Auto-commit from make deploy 🤖" || echo "No changes to commit"
	git push

# Create a new release with downloadable assets
release: clean build plugin
	@echo "Creating release..."
	@if [ ! -d $(BUILD_DIR)/EFEFTEAudioUnit.component ]; then echo "Audio Unit not found"; exit 1; fi
	@if [ ! -d $(BUILD_DIR)/EFEFTEStandalone.app ]; then echo "Standalone app not found"; exit 1; fi
	@echo "Packaging Audio Unit..."
	cd $(BUILD_DIR) && zip -r EFEFTE-AudioUnit-v$$(git describe --tags --abbrev=0 2>/dev/null || echo "1.0.0").zip EFEFTEAudioUnit.component
	@echo "Packaging Standalone App..."
	cd $(BUILD_DIR) && zip -r EFEFTE-Standalone-v$$(git describe --tags --abbrev=0 2>/dev/null || echo "1.0.0").zip EFEFTEStandalone.app
	@echo "Creating GitHub release..."
	gh release create v$$(date +%Y.%m.%d) $(BUILD_DIR)/EFEFTE-*.zip \
		--title "EFEFTE v$$(date +%Y.%m.%d)" \
		--notes "**EFEFTE Release v$$(date +%Y.%m.%d)**\n\n🎵 **Audio Unit Plugin for Logic Pro**\n- Real-time FFT spectrum analysis\n- Professional audio processing tools\n- Native macOS integration\n\n💻 **Standalone Spectrum Analyser**\n- Independent microphone analysis\n- Development and testing tool\n- No Logic Pro required\n\n### Installation\n\n**Audio Unit:**\n1. Download \`EFEFTE-AudioUnit-*.zip\`\n2. Unzip and copy \`EFEFTEAudioUnit.component\` to \`~/Library/Audio/Plug-Ins/Components/\`\n3. Restart Logic Pro\n\n**Standalone:**\n1. Download \`EFEFTE-Standalone-*.zip\`\n2. Unzip and run \`EFEFTEStandalone.app\`"

# Help
help:
	@echo "Available targets:"
	@echo "  all       - Build the project and run standalone app (default)"
	@echo "  build     - Build the project in release mode"
	@echo "  plugin    - Build Audio Unit and standalone app (macOS only)"
	@echo "  run       - Launch standalone spectrum analyser"
	@echo "  debug     - Build the project in debug mode"
	@echo "  clean     - Clean build artifacts"
	@echo "  format    - Format source code with clang-format"
	@echo "  test      - Run tests"
	@echo "  benchmark - Run benchmarks"
	@echo "  install   - Install the library"
	@echo "  deploy    - Format, build, test, commit and push"
	@echo "  release   - Create GitHub release with downloadable packages"
	@echo "  help      - Show this help message"