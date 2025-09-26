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
		echo "Installing Audio Unit plugin..."; \
		cd $(BUILD_DIR) && make install; \
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
	@GIT_HASH=$$(git rev-parse --short HEAD); \
	hdiutil create -volname "KEYQ" \
		-srcfolder $(BUILD_DIR)/dmg-contents \
		-ov -format UDZO \
		$(BUILD_DIR)/KEYQ-v$${GIT_HASH}.dmg
	@echo "DMG created: $(BUILD_DIR)/KEYQ-v$$(git rev-parse --short HEAD).dmg"
	@echo "Packaging individual components..."
	@GIT_HASH=$$(git rev-parse --short HEAD); \
	cd $(BUILD_DIR) && zip -r KEYQ-AudioUnit-$${GIT_HASH}.zip KEYQAudioUnit.component && \
	zip -r KEYQ-Standalone-$${GIT_HASH}.zip KEYQStandalone.app

# Deploy target with auto-commit and push
deploy: format build test
	@echo "Deploying changes..."
	git add -A
	git commit -m "Auto-commit from make deploy 🤖" || echo "No changes to commit"
	git push

# Create and publish a GitHub release with packages
release: dmg
	@echo "🚀 Creating GitHub release..."
	@GIT_HASH=$$(git rev-parse --short HEAD); \
	DMG_FILE="KEYQ-v$${GIT_HASH}.dmg"; \
	if command -v gh >/dev/null 2>&1; then \
		echo "📤 Creating release $${GIT_HASH}..."; \
		gh release create "$${GIT_HASH}" \
			--title "KEYQ Build $${GIT_HASH}" \
			--notes $$'Automated release of KEYQ FFT library and Logic Pro plugin.\n\n**Features:**\n- High-performance C++23 FFT library (FFTW3 compatible)\n- Logic Pro Audio Unit spectrum analyser plugin\n- Standalone spectrum analyser app\n- Real-time audio processing with test tone generation\n\n**Download:** '"$${DMG_FILE}" \
			"$(BUILD_DIR)/$${DMG_FILE}" \
			"$(BUILD_DIR)/KEYQ-AudioUnit-$${GIT_HASH}.zip" \
			"$(BUILD_DIR)/KEYQ-Standalone-$${GIT_HASH}.zip" || echo "Release might already exist"; \
		echo "✅ Release published at: https://github.com/deanturpin/keyq/releases/tag/$${GIT_HASH}"; \
	else \
		echo "⚠️  GitHub CLI not installed. Install with: brew install gh"; \
		echo "📁 Files ready for manual upload:"; \
		echo "   - $(BUILD_DIR)/$${DMG_FILE}"; \
		echo "   - $(BUILD_DIR)/KEYQ-AudioUnit-$${GIT_HASH}.zip"; \
		echo "   - $(BUILD_DIR)/KEYQ-Standalone-$${GIT_HASH}.zip"; \
	fi

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