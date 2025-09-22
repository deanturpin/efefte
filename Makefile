.PHONY: all build clean format test benchmark install deploy

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
	@echo "  help      - Show this help message"