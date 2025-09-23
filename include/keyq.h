#pragma once

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// FFTW3-compatible type definitions
typedef double fftw_complex[2];
typedef struct fftw_plan_s *fftw_plan;

// Direction flags
#define FFTW_FORWARD (-1)
#define FFTW_BACKWARD (+1)

// Planning flags
#define FFTW_MEASURE (0U)
#define FFTW_DESTROY_INPUT (1U << 0)
#define FFTW_UNALIGNED (1U << 1)
#define FFTW_CONSERVE_MEMORY (1U << 2)
#define FFTW_EXHAUSTIVE (1U << 3)
#define FFTW_PRESERVE_INPUT (1U << 4)
#define FFTW_PATIENT (1U << 5)
#define FFTW_ESTIMATE (1U << 6)

// Core planning functions
fftw_plan fftw_plan_dft_1d(int n, fftw_complex *in, fftw_complex *out, int sign, unsigned flags);

fftw_plan fftw_plan_dft_2d(int n0, int n1, fftw_complex *in, fftw_complex *out, int sign,
                           unsigned flags);

fftw_plan fftw_plan_dft_3d(int n0, int n1, int n2, fftw_complex *in, fftw_complex *out, int sign,
                           unsigned flags);

fftw_plan fftw_plan_dft(int rank, const int *n, fftw_complex *in, fftw_complex *out, int sign,
                        unsigned flags);

// Real-to-complex transforms
fftw_plan fftw_plan_dft_r2c_1d(int n, double *in, fftw_complex *out, unsigned flags);

fftw_plan fftw_plan_dft_c2r_1d(int n, fftw_complex *in, double *out, unsigned flags);

// Execution functions
void fftw_execute(const fftw_plan p);
void fftw_execute_dft(const fftw_plan p, fftw_complex *in, fftw_complex *out);
void fftw_execute_dft_r2c(const fftw_plan p, double *in, fftw_complex *out);
void fftw_execute_dft_c2r(const fftw_plan p, fftw_complex *in, double *out);

// Memory management
void *fftw_malloc(size_t n);
void fftw_free(void *p);
void fftw_destroy_plan(fftw_plan p);

// Wisdom functions
void fftw_forget_wisdom(void);
int fftw_import_wisdom_from_filename(const char *filename);
int fftw_export_wisdom_to_filename(const char *filename);
char *fftw_export_wisdom_to_string(void);
int fftw_import_wisdom_from_string(const char *input_string);

// Planning time limit
void fftw_set_timelimit(double t);

// Thread support
int fftw_init_threads(void);
void fftw_plan_with_nthreads(int nthreads);
void fftw_cleanup_threads(void);

#ifdef __cplusplus
}
#endif