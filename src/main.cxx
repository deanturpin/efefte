#include <print>
#include <numbers>
#include <cmath>
#include "../include/efefte.h"

int main() {
    std::print("EFEFTE FFT\n");
    std::print("Creating an FFTW3-compatible API from scratch\n\n");

    // Basic test case
    constexpr int N = 64;

    // Allocate aligned memory
    fftw_complex *input = static_cast<fftw_complex*>(fftw_malloc(sizeof(fftw_complex) * N));
    fftw_complex *output = static_cast<fftw_complex*>(fftw_malloc(sizeof(fftw_complex) * N));

    if (!input || !output) {
        std::print("Memory allocation failed\n");
        return 1;
    }

    // Generate test signal: sine wave
    std::print("Generating test signal...\n");
    for (int i = 0; i < N; ++i) {
        input[i][0] = std::sin(2.0 * std::numbers::pi * i / N);  // Real part
        input[i][1] = 0.0;                                       // Imaginary part
    }

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

    // Display first few results
    std::print("First 5 FFT results:\n");
    for (int i = 0; i < 5; ++i) {
        std::print("  {}: {:.6f} + {:.6f}i\n", i, output[i][0], output[i][1]);
    }

    // Test with different arrays
    std::print("\nTesting execute with different arrays...\n");
    fftw_execute_dft(plan, input, output);

    // Clean up
    std::print("Cleaning up...\n");
    fftw_destroy_plan(plan);
    fftw_free(input);
    fftw_free(output);

    std::print("Test completed successfully!\n");
    return 0;
}