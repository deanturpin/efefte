# EFEFTE - FFT Benchmark Project - Claude Instructions

## Project Goals

- Create EFEFTE: high-performance latest C++ standard FFT library as drop-in FFTW3 replacement
- Comprehensive benchmarking against FFTW3, Kiss FFT, Intel MKL
- Modern C++ API with FFTW3-compatible C wrapper
- APT package distribution

## Development Guidelines

- Target latest C++ standard with newest GCC/Clang
- Prioritise performance: SIMD, cache optimisation, parallel processing
- Use concepts, ranges, and constexpr extensively
- FFT visualisations should default to logarithmic X-axis scaling for musical analysis
- Maintain numerical accuracy: < 1e-12 RMS error for double precision
- Create both modern latest C++ interface and FFTW3-compatible wrapper

## Build and Test Requirements

- Always run benchmarks after significant changes
- Validate accuracy against FFTW3 reference
- Test multiple input sizes: 64, 256, 1024, 4096, 16384, 65536, 262144
- Profile performance with different compilers and optimisation flags
- Ensure cross-platform builds (x86_64, ARM64)

## Performance Targets

- Within 10% of FFTW3 performance for common transform sizes
- Better than Kiss FFT across all metrics
- Efficient memory usage and cache behaviour
- Good scaling with thread count

## API Design Principles

- Modern latest C++ standard interface using span, ranges, concepts
- Template-based for compile-time optimisation
- Exception-safe RAII design
- Zero-cost abstractions where possible

## Packaging Goals

- Clean APT package installation
- CMake integration support
- Header-only option where feasible
- Clear migration path from FFTW3

## Implementation Priority

1. Core latest C++ FFT implementation
2. Basic benchmark framework
3. FFTW3 compatibility layer
4. Performance optimisation
5. GitHub Pages results publishing
6. Packaging and distribution
7. Advanced features (GPU, distributed)
8. Logic Pro EFEFTE Audio Unit plugin development

## Design Philosophy

### Architecture Principles
- Platform-agnostic C++ FFT core with clean separation from GUI layers
- Static linking for self-contained, dependency-free plugin distribution
- macOS-first development focus with cross-platform expansion capability
- No vendor framework lock-in (avoid JUCE dependency)

### Quality Standards
- Apple-native experience using SwiftUI/Metal for professional look and feel
- Real-time performance constraints drive all architectural decisions
- Clean APIs with excellent documentation for maintainable codebase
- Professional code-signed distribution for Logic Pro integration

## GitHub Pages Requirements

- Auto-publish benchmark results from CI
- Interactive performance charts with logarithmic X-axis scaling
- Historical performance tracking
- Cross-platform comparison tables
- Mobile-responsive design

## Audio Unit Plugin Requirements

- **Platform Strategy**: macOS-first with cross-platform backend
- **Core Engine**: Platform-agnostic C++ FFT library (statically linked)
- **macOS GUI**: SwiftUI/AppKit with Metal visualisation
- **Distribution**: Self-contained .component bundle, no external deps
- Real-time FFT processing with < 10ms latency
- Support sample rates from 44.1kHz to 192kHz
- Lock-free ring buffer for audio thread safety
- Logic Pro integration and validation
- Future JUCE wrapper for Windows/Linux VST expansion

## Audio Plugin Feature Set

### Analysis Tools

- Real-time spectrum analyser with logarithmic scaling
- Spectrogram visualisation
- Phase correlation metering

### Creative Processing

- Spectral gating and frequency shifting
- Spectral freeze and harmonic enhancement
- Surgical EQ with visual feedback
- Dynamic EQ and stereo width control

### Audio Restoration

- Intelligent de-noise and de-hum
- Spectral repair and voice isolation
- Pitch correction with formant preservation
- Vocoder and convolution reverb effects

### Key-Aware Musical EQ (Flagship Feature)

#### Core Functionality
- Real-time musical pitch detection and key analysis
- Visual note name overlay on traditional EQ interface
- Harmonic vs fundamental frequency differentiation
- Genre-aware dissonance tolerance settings

#### Bum Note Detection & Correction
- Traffic light system for harmonic compatibility (green/yellow/red)
- Microtonal pitch accuracy warnings (±10 cents)
- Intelligent auto-suggestions for musical frequency adjustments
- Conflict resolution between competing instruments in same notes
- Temporal tracking of pitch drift and tuning issues
