#include <cmath>
#include <numbers>
#include <print>

#include "../include/efefte.h"
#include "../include/test.h"

int main() {
    std::print("EFEFTE FFT\n");
    std::print("Creating an FFTW3-compatible API from scratch\n\n");

    // Basic test case
    constexpr int N = 64;

    // Allocate aligned memory
    fftw_complex *input = static_cast<fftw_complex *>(fftw_malloc(sizeof(fftw_complex) * N));
    fftw_complex *output = static_cast<fftw_complex *>(fftw_malloc(sizeof(fftw_complex) * N));

    if (!input || !output) {
        std::print("Memory allocation failed\n");
        return 1;
    }

    // Generate test signal: 440 Hz sine wave (A4 note)
    std::print("Generating 440 Hz sine wave test signal...\n");
    const double sample_rate = 1024.0; // Hz
    const double frequency = 440.0;    // Hz (A4 note)
    efefte_generate_sine(input, N, frequency, sample_rate);

    // Create plan
    std::print("Creating FFT plan...\n");
    fftw_plan plan = fftw_plan_dft_1d(N, input, output, FFTW_FORWARD, FFTW_ESTIMATE);

    if (!plan) {
        std::print("Plan creation failed\n");
        fftw_free(input);
        fftw_free(output);
        return 1;
    }

    // Execute FFT
    std::print("Executing FFT...\n");
    fftw_execute(plan);

    // Analyse spectrum
    std::print("Spectrum Analysis:\n");
    efefte_find_peaks(output, N, sample_rate);
    std::print("\n");
    efefte_print_spectrum(output, N, sample_rate, 10);

    // Clean up
    std::print("Cleaning up...\n");
    fftw_destroy_plan(plan);
    fftw_free(input);
    fftw_free(output);

    std::print("Test completed successfully!\n");
    return 0;
}