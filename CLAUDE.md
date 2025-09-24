# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

KEYQ (pronounced "key-q") is a high-performance FFT library designed as a drop-in replacement for FFTW3, written in modern C++23. The project includes:

1. **Core FFT Library** (`libkeyq`) - FFTW3-compatible C API with modern C++ implementation
2. **Audio Unit Plugin** - Real-time spectrum analysis plugin for Logic Pro
3. **Standalone App** - Independent spectrum analyser for development and testing
4. **Key-Aware Musical EQ** (flagship feature) - EQ that detects musical keys and highlights frequency conflicts

## Build Commands

```bash
make              # Build everything and launch standalone app
make build        # Build core library and test executable
make plugin       # Build Audio Unit and standalone app (macOS only)
make dmg          # Create DMG installer with "Install KEYQ" app
make test         # Run FFT accuracy tests
make clean        # Remove all build artifacts
make format       # Format C++ source with clang-format
make deploy       # Format, build, test, commit and push
make release      # Build local release packages (use git tags for CI releases)
```

## Release Process

1. Make changes and test locally with `make`
2. Create semantic version tag: `git tag v1.0.X && git push --tags`
3. GitHub Actions automatically builds and creates release with:
   - `KEYQ-AudioUnit-1.0.X.zip` (Logic Pro plugin)
   - `KEYQ-Standalone-1.0.X.zip` (Standalone app)
   - `TurbeauxSounds-KEYQ-v1.0.X.dmg` (Installer with both)

## Architecture

### Core Library Structure
- `include/keyq.h` - FFTW3-compatible C API header with identical function signatures and type definitions
- `src/keyq.cxx` - Main FFT implementation using C++23 features (currently stub implementation)
- `src/main.cxx` - Test executable entry point
- `src/test.cxx` - Validation and accuracy testing functions
- The library maintains ABI compatibility with FFTW3 for seamless replacement

### Build System
- **CMake 3.25+** required for C++23 support
- **Mixed Language Support**: C++ core with Objective-C++ for macOS plugins
- **Static Library**: `libkeyq` shared library target
- **Conditional Building**: Audio Unit and Standalone only build on macOS with Clang

### Platform-Specific Components
- **macOS Audio Unit**: `plugin/AudioUnit/` - Logic Pro plugin (Objective-C++/Swift)
- **Standalone App**: `plugin/Standalone/` - Cross-platform spectrum analyser (Objective-C++)
- **Static Linking Strategy**: All plugins contain the FFT engine statically linked
- **Bundle Structure**: `.component` for Audio Unit, `.app` for Standalone

### Modern C++ Features Used
- C++23 standard with concepts, ranges, and constexpr
- Template-based compile-time optimisation
- SIMD instructions (AVX-512, ARM NEON) for performance
- Exception-safe RAII design patterns
- `std::print` for formatted output (C++23)

## Development Guidelines

### Performance Requirements
- **Target**: Within 10% of FFTW3 performance for common transform sizes
- **Accuracy**: < 1e-12 RMS error for double precision transforms
- **Latency**: < 10ms for real-time audio processing in plugins
- **Sample Rates**: Support 44.1kHz to 192kHz for audio applications

### API Design Principles
- **Drop-in Compatibility**: Change `#include <fftw3.h>` to `#include <keyq.h>`
- **Zero Migration Effort**: Identical function signatures and behaviour
- **Template-based Optimisation**: Compile-time specialisation for performance
- **Lock-free Audio Processing**: Ring buffers for real-time constraints

### Audio Plugin Architecture
- **Static Linking**: Self-contained .component bundles with no external dependencies
- **macOS-first Development**: SwiftUI/AppKit GUI with Metal visualisation
- **Cross-platform Ready**: Core engine designed for future Windows/Linux VST expansion
- **Musical Intelligence**: Key detection and harmonic analysis for frequency-aware EQ

## Key Technical Details

- **C++ Standard**: C++23 (requires Clang 17+ or GCC 14+)
- **File Extensions**: `.cxx` files (not `.cpp`) throughout codebase
- **Audio Format**: 48kHz sample rate, 512 sample buffer
- **Plugin Type**: Audio Unit (aufx/efft/Turb)
- **Bundle IDs**: com.turbeaux.keyq.audiounit, com.turbeaux.keyq.standalone
- **Legacy Names**: Some references to "efefte" remain in build scripts and CI

## Current Implementation Status

### Core Library
- **FFTW3 API**: Complete C header with all major function signatures
- **Implementation**: Currently stub/placeholder implementation in `keyq.cxx`
- **Plan Structure**: `fftw_plan_s` defined with basic fields (n, rank, sign, flags, pointers)
- **Memory Management**: Basic malloc/free for plan allocation
- **Debugging**: Uses C++23 `std::print` for debugging output

### Plugin Development
- **Audio Unit**: Framework in place with CMakeLists.txt and Objective-C++ sources
- **Standalone**: Basic app structure with main.mm entry point
- **Integration**: Both plugins designed to statically link core library

## Testing and Validation

### Test Categories
- **Accuracy Validation**: Compare against FFTW3 double precision as ground truth
- **Performance Benchmarks**: Multi-size transforms (64 to 262144 samples)
- **Audio Integration**: Real-time processing validation in Logic Pro
- **Cross-platform**: Verify behaviour on x86_64 and ARM64 architectures

### Testing Individual Components
```bash
./build/keyq                      # Run FFT test with 440Hz sine wave
open build/KEYQStandalone.app     # Test standalone spectrum analyser
auval -v aufx efft Turb           # Validate Audio Unit plugin
make benchmark                    # Performance comparison with FFTW3/Kiss FFT (if benchmark available)
```

### Musical EQ Features (Flagship)
- **Key Detection**: Real-time musical pitch mapping (Hz to note names)
- **Harmonic Analysis**: Distinguish fundamentals from overtones
- **Conflict Detection**: Traffic light system for frequency clashes (green/yellow/red)
- **Corrective Suggestions**: "Try cutting 247Hz (B♭) to resolve key clash"

## GitHub Actions CI/CD

The `.github/workflows/build-and-release.yml` workflow:

### Build Process
- Triggers on pushes to `main`, PRs, and version tags (`v*`)
- Builds on `macos-latest` runner using `make build plugin`
- Runs test executable: `./build/efefte` (legacy name)
- Creates DMG installer with AppleScript installer app

### Release Artifacts
- **Audio Unit**: `KEYQ-AudioUnit-{version}.zip`
- **Standalone App**: `KEYQ-Standalone-{version}.zip`
- **DMG Installer**: `TurbeauxSounds-KEYQ-{version}.dmg`
- Auto-publishes GitHub releases on version tags
- Deploys documentation to GitHub Pages from `./docs` directory

### Permissions Required
- `contents: write` for creating releases
- `pages: write` and `id-token: write` for GitHub Pages deployment

## User Preferences (from global CLAUDE.md)

- Use British English spellings
- Commit messages use 🤖 emoji (no Claude mentions)
- Auto-push significant changes
- Remove dead code completely (trust version control)
- FFT visualisations default to logarithmic X-axis scaling