#pragma once

#include "efefte.h"

#ifdef __cplusplus
extern "C" {
#endif

// EFEFTE test signal generation utilities
// These are helper functions for testing and demonstration, not part of FFTW3 API

void efefte_generate_sine(fftw_complex *signal, int n, double frequency, double sample_rate);
void efefte_generate_chirp(fftw_complex *signal, int n, double f0, double f1, double sample_rate);
void efefte_generate_noise(fftw_complex *signal, int n, double amplitude);

// Analysis helpers
void efefte_find_peaks(const fftw_complex *spectrum, int n, double sample_rate);
double efefte_magnitude(const fftw_complex value);
void efefte_print_spectrum(const fftw_complex *spectrum, int n, double sample_rate, int max_bins);

#ifdef __cplusplus
}
#endif