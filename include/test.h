#pragma once

#include "keyq.h"

#ifdef __cplusplus
extern "C" {
#endif

// KEYQ test signal generation utilities
// These are helper functions for testing and demonstration, not part of FFTW3 API

void keyq_generate_sine(fftw_complex *signal, int n, double frequency, double sample_rate);
void keyq_generate_chirp(fftw_complex *signal, int n, double f0, double f1, double sample_rate);
void keyq_generate_noise(fftw_complex *signal, int n, double amplitude);

// Analysis helpers
void keyq_find_peaks(const fftw_complex *spectrum, int n, double sample_rate);
double keyq_magnitude(const fftw_complex value);
void keyq_print_spectrum(const fftw_complex *spectrum, int n, double sample_rate, int max_bins);

#ifdef __cplusplus
}
#endif