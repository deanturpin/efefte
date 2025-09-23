.PHONY: all build clean format test benchmark install deploy release plugin run debug help dmg

# Default target
all: build plugin run

# Configuration
BUILD_DIR = build
CMAKE_FLAGS = -DCMAKE_BUILD_TYPE=Release -DCMAKE_EXPORT_COMPILE_COMMANDS=ON

# Build the project
build:
	@echo "Building KEYQ..."
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
	cd $(BUILD_DIR) && ./benchmarks/keyq_benchmark || echo "Benchmarks not built yet"

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
	@open ./$(BUILD_DIR)/KEYQStandalone.app

# Install the library
install: build
	@echo "Installing KEYQ..."
	cd $(BUILD_DIR) && make install

# Development helpers
debug:
	@echo "Building debug version..."
	mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR) && cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ..
	cd $(BUILD_DIR) && make -j$(shell nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)

# Create DMG installer with installer app
dmg: clean build plugin
	@echo "Creating DMG installer..."
	@if [ ! -d $(BUILD_DIR)/KEYQAudioUnit.component ]; then echo "Audio Unit not found"; exit 1; fi
	@if [ ! -d $(BUILD_DIR)/KEYQStandalone.app ]; then echo "Standalone app not found"; exit 1; fi
	@echo "Setting up DMG contents..."
	mkdir -p $(BUILD_DIR)/dmg-contents
	cp -R $(BUILD_DIR)/KEYQAudioUnit.component $(BUILD_DIR)/dmg-contents/
	cp -R $(BUILD_DIR)/KEYQStandalone.app $(BUILD_DIR)/dmg-contents/
	@echo "Creating installer app..."
	osacompile -o $(BUILD_DIR)/dmg-contents/Install\ KEYQ.app installer/Install.applescript
	@echo "Creating DMG..."
	hdiutil create -volname "Turbeaux Sounds KEYQ" \
		-srcfolder $(BUILD_DIR)/dmg-contents \
		-ov -format UDZO \
		$(BUILD_DIR)/TurbeauxSounds-KEYQ-v$$(git describe --tags --abbrev=0 2>/dev/null | sed 's/v//' || echo "1.0.0").dmg
	@echo "DMG created: $(BUILD_DIR)/TurbeauxSounds-KEYQ-*.dmg"

# Deploy target with auto-commit and push
deploy: format build test
	@echo "Deploying changes..."
	git add -A
	git commit -m "Auto-commit from make deploy 🤖" || echo "No changes to commit"
	git push

# Create a new release with downloadable assets
release: clean build plugin
	@echo "Creating release..."
	@if [ ! -d $(BUILD_DIR)/KEYQAudioUnit.component ]; then echo "Audio Unit not found"; exit 1; fi
	@if [ ! -d $(BUILD_DIR)/KEYQStandalone.app ]; then echo "Standalone app not found"; exit 1; fi
	@echo "Packaging Audio Unit..."
	cd $(BUILD_DIR) && zip -r KEYQ-AudioUnit-$$(git describe --tags --abbrev=0 2>/dev/null || echo "v1.0.0").zip KEYQAudioUnit.component
	@echo "Packaging Standalone App..."
	cd $(BUILD_DIR) && zip -r KEYQ-Standalone-$$(git describe --tags --abbrev=0 2>/dev/null || echo "v1.0.0").zip KEYQStandalone.app
	@echo "Creating GitHub release..."
	@echo "Current version: $$(git describe --tags --abbrev=0 2>/dev/null || echo 'v1.0.0')"
	@echo "Please create a new semantic version tag first (e.g., git tag v1.0.2 && git push --tags)"
	@echo "Then GitHub Actions will automatically build and release."

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
	@echo "  release   - Build and package (use git tags for actual releases)"
	@echo "  dmg       - Create DMG installer with drag-and-drop interface"
	@echo "  help      - Show this help message"