#include "../include/efefte.h"
#include <cstdlib>
#include <cstring>
#include <cmath>
#include <numbers>
#include <print>

// Internal plan structure
struct fftw_plan_s {
    int n;
    int rank;
    int sign;
    unsigned flags;
    fftw_complex *in;
    fftw_complex *out;
    bool is_r2c;
    bool is_c2r;
};

// Global state
static int threads_initialized = 0;
static int nthreads = 1;
static double time_limit = -1.0;

extern "C" {

// Core planning functions
fftw_plan fftw_plan_dft_1d(int n, fftw_complex *in, fftw_complex *out,
                           int sign, unsigned flags) {
    std::print("fftw_plan_dft_1d: n={}, sign={}, flags={}\n", n, sign, flags);

    fftw_plan plan = static_cast<fftw_plan>(malloc(sizeof(fftw_plan_s)));
    if (!plan) return nullptr;

    plan->n = n;
    plan->rank = 1;
    plan->sign = sign;
    plan->flags = flags;
    plan->in = in;
    plan->out = out;
    plan->is_r2c = false;
    plan->is_c2r = false;

    return plan;
}

fftw_plan fftw_plan_dft_2d(int n0, int n1,
                           fftw_complex *in, fftw_complex *out,
                           int sign, unsigned flags) {
    std::print("fftw_plan_dft_2d: n0={}, n1={}, sign={}, flags={}\n", n0, n1, sign, flags);

    fftw_plan plan = static_cast<fftw_plan>(malloc(sizeof(fftw_plan_s)));
    if (!plan) return nullptr;

    plan->n = n0 * n1;
    plan->rank = 2;
    plan->sign = sign;
    plan->flags = flags;
    plan->in = in;
    plan->out = out;
    plan->is_r2c = false;
    plan->is_c2r = false;

    return plan;
}

fftw_plan fftw_plan_dft_3d(int n0, int n1, int n2,
                           fftw_complex *in, fftw_complex *out,
                           int sign, unsigned flags) {
    std::print("fftw_plan_dft_3d: n0={}, n1={}, n2={}, sign={}, flags={}\n", n0, n1, n2, sign, flags);

    fftw_plan plan = static_cast<fftw_plan>(malloc(sizeof(fftw_plan_s)));
    if (!plan) return nullptr;

    plan->n = n0 * n1 * n2;
    plan->rank = 3;
    plan->sign = sign;
    plan->flags = flags;
    plan->in = in;
    plan->out = out;
    plan->is_r2c = false;
    plan->is_c2r = false;

    return plan;
}

fftw_plan fftw_plan_dft(int rank, const int *n,
                        fftw_complex *in, fftw_complex *out,
                        int sign, unsigned flags) {
    std::print("fftw_plan_dft: rank={}, sign={}, flags={}\n", rank, sign, flags);

    fftw_plan plan = static_cast<fftw_plan>(malloc(sizeof(fftw_plan_s)));
    if (!plan) return nullptr;

    int total_n = 1;
    for (int i = 0; i < rank; ++i) {
        total_n *= n[i];
    }

    plan->n = total_n;
    plan->rank = rank;
    plan->sign = sign;
    plan->flags = flags;
    plan->in = in;
    plan->out = out;
    plan->is_r2c = false;
    plan->is_c2r = false;

    return plan;
}

// Real-to-complex transforms
fftw_plan fftw_plan_dft_r2c_1d(int n, double *in, fftw_complex *out,
                               unsigned flags) {
    std::print("fftw_plan_dft_r2c_1d: n={}, flags={}\n", n, flags);

    fftw_plan plan = static_cast<fftw_plan>(malloc(sizeof(fftw_plan_s)));
    if (!plan) return nullptr;

    plan->n = n;
    plan->rank = 1;
    plan->sign = FFTW_FORWARD;
    plan->flags = flags;
    plan->in = reinterpret_cast<fftw_complex*>(in);
    plan->out = out;
    plan->is_r2c = true;
    plan->is_c2r = false;

    return plan;
}

fftw_plan fftw_plan_dft_c2r_1d(int n, fftw_complex *in, double *out,
                               unsigned flags) {
    std::print("fftw_plan_dft_c2r_1d: n={}, flags={}\n", n, flags);

    fftw_plan plan = static_cast<fftw_plan>(malloc(sizeof(fftw_plan_s)));
    if (!plan) return nullptr;

    plan->n = n;
    plan->rank = 1;
    plan->sign = FFTW_BACKWARD;
    plan->flags = flags;
    plan->in = in;
    plan->out = reinterpret_cast<fftw_complex*>(out);
    plan->is_r2c = false;
    plan->is_c2r = true;

    return plan;
}

// Basic DFT implementation (O(N²) - slow but correct)
static void basic_dft(const fftw_complex *input, fftw_complex *output, int n, int sign) {
    const double direction = (sign == FFTW_FORWARD) ? -1.0 : 1.0;

    for (int k = 0; k < n; ++k) {
        output[k][0] = 0.0;  // Real part
        output[k][1] = 0.0;  // Imaginary part

        for (int j = 0; j < n; ++j) {
            const double angle = direction * 2.0 * std::numbers::pi * k * j / n;
            const double cos_val = std::cos(angle);
            const double sin_val = std::sin(angle);

            // Complex multiplication: (a + bi) * (c + di) = (ac - bd) + (ad + bc)i
            const double real_part = input[j][0] * cos_val - input[j][1] * sin_val;
            const double imag_part = input[j][0] * sin_val + input[j][1] * cos_val;

            output[k][0] += real_part;
            output[k][1] += imag_part;
        }

        // For inverse transform, divide by N
        if (sign == FFTW_BACKWARD) {
            output[k][0] /= n;
            output[k][1] /= n;
        }
    }
}

// Execution functions
void fftw_execute(const fftw_plan p) {
    if (!p) return;
    std::print("fftw_execute: executing plan with n={}, sign={}\n", p->n, p->sign);

    if (p->is_r2c || p->is_c2r) {
        std::print("Real-to-complex transforms not yet implemented in basic DFT\n");
        return;
    }

    basic_dft(p->in, p->out, p->n, p->sign);
}

void fftw_execute_dft(const fftw_plan p, fftw_complex *in, fftw_complex *out) {
    if (!p) return;
    std::print("fftw_execute_dft: executing with new arrays\n");

    // TODO: Implement actual FFT computation with new arrays
    if (in != out) {
        memcpy(out, in, p->n * sizeof(fftw_complex));
    }
}

void fftw_execute_dft_r2c(const fftw_plan p, double *in, fftw_complex *out) {
    if (!p) return;
    std::print("fftw_execute_dft_r2c: executing real-to-complex\n");

    // TODO: Implement real-to-complex FFT
    for (int i = 0; i < p->n / 2 + 1; ++i) {
        if (i < p->n) {
            out[i][0] = in[i];
            out[i][1] = 0.0;
        }
    }
}

void fftw_execute_dft_c2r(const fftw_plan p, fftw_complex *in, double *out) {
    if (!p) return;
    std::print("fftw_execute_dft_c2r: executing complex-to-real\n");

    // TODO: Implement complex-to-real FFT
    for (int i = 0; i < p->n; ++i) {
        out[i] = in[i][0];
    }
}

// Memory management
void *fftw_malloc(size_t n) {
    std::print("fftw_malloc: allocating {} bytes\n", n);
    return aligned_alloc(32, n); // 32-byte alignment for SIMD
}

void fftw_free(void *p) {
    if (p) {
        std::print("fftw_free: freeing memory\n");
        free(p);
    }
}

void fftw_destroy_plan(fftw_plan p) {
    if (p) {
        std::print("fftw_destroy_plan: destroying plan\n");
        free(p);
    }
}

// Wisdom functions (stubs)
void fftw_forget_wisdom(void) {
    std::print("fftw_forget_wisdom: clearing wisdom\n");
}

int fftw_import_wisdom_from_filename(const char *filename) {
    std::print("fftw_import_wisdom_from_filename: {}\n", filename ? filename : "null");
    return 0; // Failed to import
}

int fftw_export_wisdom_to_filename(const char *filename) {
    std::print("fftw_export_wisdom_to_filename: {}\n", filename ? filename : "null");
    return 0; // Failed to export
}

char *fftw_export_wisdom_to_string(void) {
    std::print("fftw_export_wisdom_to_string: returning empty wisdom\n");
    return nullptr;
}

int fftw_import_wisdom_from_string(const char *input_string) {
    std::print("fftw_import_wisdom_from_string: {}\n", input_string ? "provided" : "null");
    return 0; // Failed to import
}

// Planning time limit
void fftw_set_timelimit(double t) {
    std::print("fftw_set_timelimit: setting limit to {} seconds\n", t);
    time_limit = t;
}

// Thread support
int fftw_init_threads(void) {
    std::print("fftw_init_threads: initializing thread support\n");
    threads_initialized = 1;
    return 1; // Success
}

void fftw_plan_with_nthreads(int n) {
    std::print("fftw_plan_with_nthreads: setting {} threads\n", n);
    nthreads = n;
}

void fftw_cleanup_threads(void) {
    std::print("fftw_cleanup_threads: cleaning up thread support\n");
    threads_initialized = 0;
    nthreads = 1;
}


} // extern "C"