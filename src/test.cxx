#include "../include/test.h"
#include <cmath>
#include <numbers>
#include <print>

extern "C" {

// Test signal generation functions
void efefte_generate_sine(fftw_complex *signal, int n, double frequency, double sample_rate) {
    std::print("efefte_generate_sine: n={}, freq={} Hz, sample_rate={} Hz\n", n, frequency, sample_rate);

    for (int i = 0; i < n; ++i) {
        double t = static_cast<double>(i) / sample_rate;
        double phase = 2.0 * std::numbers::pi * frequency * t;
        signal[i][0] = std::cos(phase);  // Real part
        signal[i][1] = std::sin(phase);  // Imaginary part
    }
}

void efefte_generate_chirp(fftw_complex *signal, int n, double f0, double f1, double sample_rate) {
    std::print("efefte_generate_chirp: n={}, f0={} Hz, f1={} Hz, sample_rate={} Hz\n", n, f0, f1, sample_rate);

    double duration = static_cast<double>(n) / sample_rate;
    double k = (f1 - f0) / duration;  // Frequency sweep rate

    for (int i = 0; i < n; ++i) {
        double t = static_cast<double>(i) / sample_rate;
        double freq_t = f0 + k * t;
        double phase = 2.0 * std::numbers::pi * freq_t * t;
        signal[i][0] = std::cos(phase);  // Real part
        signal[i][1] = std::sin(phase);  // Imaginary part
    }
}

void efefte_generate_noise(fftw_complex *signal, int n, double amplitude) {
    std::print("efefte_generate_noise: n={}, amplitude={}\n", n, amplitude);

    // Simple pseudo-random noise (not cryptographically secure)
    static unsigned int seed = 12345;

    for (int i = 0; i < n; ++i) {
        // Linear congruential generator
        seed = seed * 1103515245 + 12345;
        double r1 = static_cast<double>(seed & 0x7fff) / 32768.0 - 1.0;

        seed = seed * 1103515245 + 12345;
        double r2 = static_cast<double>(seed & 0x7fff) / 32768.0 - 1.0;

        signal[i][0] = amplitude * r1;  // Real part
        signal[i][1] = amplitude * r2;  // Imaginary part
    }
}

// Analysis helper functions
double efefte_magnitude(const fftw_complex value) {
    return std::sqrt(value[0] * value[0] + value[1] * value[1]);
}

void efefte_print_spectrum(const fftw_complex *spectrum, int n, double sample_rate, int max_bins) {
    std::print("Spectrum analysis (showing {} bins):\n", max_bins);
    std::print("Bin  Frequency  Magnitude\n");
    std::print("---  ---------  ---------\n");

    int bins_to_show = (max_bins > 0 && max_bins < n/2) ? max_bins : n/2;

    for (int i = 0; i < bins_to_show; ++i) {
        double frequency = static_cast<double>(i) * sample_rate / n;
        double magnitude = efefte_magnitude(spectrum[i]);
        std::print("{:3d}  {:8.2f}   {:8.6f}\n", i, frequency, magnitude);
    }
}

void efefte_find_peaks(const fftw_complex *spectrum, int n, double sample_rate) {
    std::print("Finding spectral peaks...\n");

    double max_magnitude = 0.0;
    int max_bin = 0;

    // Only check positive frequencies (first half of spectrum)
    for (int i = 1; i < n/2; ++i) {
        double magnitude = efefte_magnitude(spectrum[i]);
        if (magnitude > max_magnitude) {
            max_magnitude = magnitude;
            max_bin = i;
        }
    }

    if (max_magnitude > 0.0) {
        double peak_frequency = static_cast<double>(max_bin) * sample_rate / n;
        std::print("Peak found at bin {}: {:.2f} Hz, magnitude {:.6f}\n",
                   max_bin, peak_frequency, max_magnitude);
    } else {
        std::print("No significant peaks found\n");
    }
}

} // extern "C"