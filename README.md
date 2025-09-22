# EFEFTE - FFT Benchmark Project Instructions

## Project Overview

Create EFEFTE - a comprehensive benchmarking suite and high-performance FFT library
to compare against established libraries (FFTW3, Kiss FFT, Intel MKL) with the
goal of creating a drop-in replacement and APT package.

## Dependencies to Install

- **FFTW3**: `apt install libfftw3-dev` or `brew install fftw`
- **Intel MKL**: Intel oneAPI toolkit
- **Kiss FFT**: Download from GitHub (BSD licensed)
- **Google Benchmark**: For performance measurement
- **Google Test**: For accuracy validation

## Benchmark Test Cases

1. **Transform Sizes**: 64, 256, 1024, 4096, 16384, 65536, 262144 samples
2. **Data Types**: float, double, complex float, complex double
3. **Transform Types**: Forward, inverse, real-to-complex, complex-to-real
4. **Threading**: Single-threaded vs multi-threaded performance
5. **Memory Patterns**: In-place vs out-of-place transforms

## Performance Metrics to Measure

- **Execution Time**: microseconds per transform
- **Throughput**: samples processed per second
- **Memory Usage**: peak and average allocation
- **Cache Performance**: L1/L2/L3 cache misses
- **SIMD Utilisation**: vectorisation efficiency
- **Power Consumption**: energy per transform (if measurable)

## Accuracy Validation

- **Reference Data**: Use FFTW3 double precision as ground truth
- **Error Metrics**: RMS error, maximum absolute error
- **Test Signals**:
  - Pure sine waves (various frequencies)
  - Chirp signals
  - White noise
  - Real audio samples

## Modern Latest C++ Standard Features to Leverage

- **Concepts**: Template constraints for numeric types
- **Ranges**: Pipeline-style data processing
- **Modules**: Faster compilation (if compiler supports)
- **constexpr**: Compile-time twiddle factor generation
- **SIMD**: std::simd when available
- **Parallel Algorithms**: std::execution policies

## API Design Goals

### Drop-in FFTW3 Replacement Strategy
- **Battle-tested API** - leverage FFTW3's proven interface design
- **Zero migration effort** - change `#include <fftw3.h>` to `#include <efefte.h>`
- **Instant benchmarking** - easy performance comparison in existing codebases
- **Familiar workflow** - no learning curve for experienced developers

### Modern C++ Wrapper (Optional)

```cpp
namespace efefte {
    using plan = fftw_plan;  // or custom type

    auto plan_dft_1d(int n, std::complex<double>* in, std::complex<double>* out,
                     int sign, unsigned flags) -> plan;
    void execute(plan p);
    void destroy_plan(plan p);

    // Modern convenience functions
    template<std::floating_point T>
    auto transform(std::span<const std::complex<T>> input) -> std::vector<std::complex<T>>;
}
```

### FFTW3-Compatible C Interface (Primary)

```cpp
extern "C" {
    // Direct FFTW3 API compatibility
    fftw_plan fftw_plan_dft_1d(int n, fftw_complex *in, fftw_complex *out,
                               int sign, unsigned flags);
    void fftw_execute(const fftw_plan plan);
    void fftw_destroy_plan(fftw_plan plan);

    // Or prefixed alternative
    efefte_plan efefte_plan_dft_1d(int n, efefte_complex *in, efefte_complex *out,
                                   int sign, unsigned flags);
    void efefte_execute(efefte_plan plan);
    void efefte_destroy_plan(efefte_plan plan);
}
```

## APT Package Configuration

- **Package Name**: `libefefte-dev`
- **Dependencies**: `libc6-dev, cmake`
- **Files**:
  - Headers: `/usr/include/efefte/`
  - Library: `/usr/lib/x86_64-linux-gnu/libefefte.so`
  - CMake config: `/usr/lib/x86_64-linux-gnu/cmake/efefte/`
  - Documentation: `/usr/share/doc/libefefte-dev/`

## Build System Requirements

- **CMake 3.25+**: For latest C++ standard support
- **Latest GCC or Clang**: Latest C++ standard compiler
- **Architecture Support**: x86_64, ARM64, RISC-V
- **Cross-compilation**: Support multiple targets

## CI/CD Pipeline

1. **Build Matrix**: Multiple compilers and architectures
2. **Performance Regression**: Compare against baseline
3. **Accuracy Validation**: Ensure numerical correctness
4. **Package Testing**: Verify APT package installation
5. **Documentation**: Auto-generate API docs
6. **GitHub Pages**: Auto-publish benchmark results and charts

## GitHub Pages Publishing

- **Automated Results**: CI runs benchmarks and updates results page
- **Interactive Charts**: Chart.js or D3.js for performance visualisation
- **Historical Tracking**: Performance trends over time
- **Comparison Tables**: Side-by-side library performance
- **Platform Breakdown**: Results by architecture (x86_64, ARM64)
- **Responsive Design**: Mobile-friendly benchmark viewer

## Optimisation Strategies

- **SIMD Instructions**: AVX-512, ARM NEON
- **Cache Optimisation**: Block-wise processing
- **Memory Alignment**: 64-byte aligned allocations
- **Loop Unrolling**: Template-based unrolling
- **Parallel Processing**: OpenMP or std::execution
- **Hardware-Specific**: CPU feature detection

## Documentation Requirements

- **Performance Results**: Benchmark comparison charts
- **API Reference**: Complete function documentation
- **Usage Examples**: Real-world use cases
- **Migration Guide**: From FFTW3 to modern latest C++
- **Build Instructions**: All supported platforms

## Testing Strategy

- **Unit Tests**: Individual function validation
- **Integration Tests**: Full pipeline testing
- **Performance Tests**: Automated benchmarking
- **Compatibility Tests**: FFTW3 wrapper validation
- **Stress Tests**: Large data sets and edge cases

## Future Enhancements

- **GPU Acceleration**: CUDA/OpenCL backends
- **Distributed Computing**: MPI support for large transforms
- **Real-time Processing**: Lock-free ring buffer integration
- **Audio Applications**: Jack/ALSA integration
- **Logic Pro Plugin**: EFEFTE Audio Unit wrapper for real-time spectral processing
- **Web Assembly**: Browser-based FFT processing

## Audio Unit Plugin Architecture

### Platform Strategy
- **Core FFT Engine**: Platform-agnostic C++ library (static linking)
- **macOS Audio Unit**: SwiftUI/AppKit GUI with Metal visualisation
- **Future Expansion**: JUCE wrapper for Windows/Linux VST support
- **Development Focus**: macOS-first, cross-platform ready

### Plugin Distribution
- **Static Linking**: Core FFT library compiled into plugin bundle
- **No External Dependencies**: Self-contained .component bundle
- **Code Signing**: Apple Developer Program for distribution
- **Installer**: Optional PKG installer for professional deployment

## Audio Unit Plugin Features

### Spectral Analysis & Visualisation

- **Real-time spectrum analyser** with logarithmic frequency scaling
- **Spectrogram view** showing frequency content over time
- **Phase correlation meter** for stereo imaging analysis

### Creative Effects

- **Spectral gate** - mute frequencies below threshold (noise reduction)
- **Frequency shifter** - shift all frequencies by fixed amount (metallic effects)
- **Spectral freeze** - capture and hold frequency content indefinitely
- **Harmonic enhancer** - boost or suppress specific harmonic series

### Mixing & Mastering Tools

- **Surgical EQ** - ultra-precise frequency cuts with visual feedback
- **Dynamic EQ** - frequency-dependent compression/expansion
- **Stereo width control** - adjust stereo field per frequency band
- **Crossover designer** - custom speaker crossover networks

### Restoration & Cleanup

- **De-noise** - learn noise profile and subtract intelligently
- **De-hum** - remove 50/60Hz mains hum and harmonics
- **Spectral repair** - paint out clicks, pops, or unwanted sounds
- **Voice isolation** - extract vocals or remove them entirely

### Musical Applications

- **Pitch correction** with formant preservation
- **Auto-tune** effects with customisable response curves
- **Vocoder** - classic robot voice effects
- **Convolution reverb** - realistic acoustic spaces

### Key-Aware Musical EQ

#### Core Concept
- **Real-time peak detection** with musical pitch mapping (Hz to note names)
- **Key signature analysis** from frequency peak patterns
- **Visual overlay** showing note names and detected key on EQ curve
- **Harmonic awareness** distinguishing fundamentals from overtones

#### Bum Note Detection System
- **Out-of-key highlighting** - red peaks for notes not in detected key
- **Microtonal warnings** - yellow for slightly off-pitch (±10 cents)
- **Clash detection** - orange when instruments compete in same note
- **Dissonance meter** - visual tension indicator for harmonic intervals

#### Smart Analysis Features
- **Traffic light system**: Green (in key), Yellow (questionable), Red (clashing)
- **Severity scaling** - brighter colours for louder/more prominent issues
- **Context awareness** - genre-specific tolerance (jazz vs classical)
- **Temporal tracking** - highlight pitch drift over time
- **Mode detection** - distinguish major/minor/modal scales
- **Chord progression awareness** - understand passing tones vs errors

#### Corrective Action Engine
- **Auto-suggest fixes** - "Try cutting 247Hz (B♭) to resolve key clash"
- **Harmonic alternatives** - "Boost 220Hz (A) instead for better fit"
- **Tuning guidance** - "Instrument 2 cents sharp on F#"
- **Musical EQ moves** - frequency adjustments that respect harmonic series
- **Conflict resolution** - suggest which instrument to adjust in frequency battles

## Success Criteria

1. **Performance**: Within 10% of FFTW3 for common sizes
2. **Accuracy**: < 1e-12 RMS error for double precision
3. **Compatibility**: Drop-in replacement for FFTW3 C API
4. **Usability**: Clean latest C++ interface with good documentation
5. **Distribution**: Successfully packaged for major Linux distros

## Design Philosophy

### Clean Architecture Principles
- **Separation of Concerns**: Platform-agnostic FFT core completely isolated from GUI
- **Static Linking Strategy**: Self-contained plugin bundles with zero external dependencies
- **macOS-First Development**: Focus on Apple ecosystem quality and performance
- **Cross-Platform Ready**: Core engine designed for future Windows/Linux expansion
- **No Vendor Lock-in**: Avoid framework dependencies (JUCE) for maximum flexibility

### Quality Standards
- **Apple-Native Experience**: SwiftUI/Metal for native look, feel, and performance
- **Professional Distribution**: Code-signed .component bundles for Logic Pro
- **Developer Experience**: Clean APIs, excellent documentation, maintainable code
- **Performance First**: Real-time constraints drive all architectural decisions

## Implementation Priority

1. Core latest C++ FFT implementation
2. Basic benchmark framework
3. FFTW3 compatibility layer
4. Performance optimisation
5. Packaging and distribution
6. Advanced features (GPU, distributed)
7. Logic Pro EFEFTE Audio Unit plugin development
