// SPDX-License-Identifier: Apache-2.0

#ifndef DEBUG_BENCH_TOOLS_H
#define DEBUG_BENCH_TOOLS_H

#include <stdio.h>
#include <sys/time.h>

static inline int64_t cpucycles(void) {
#if (defined(TARGET_AMD64) || defined(TARGET_X86))
    unsigned int hi, lo;

    asm volatile ("rdtsc" : "=a" (lo), "=d"(hi));
    return ((int64_t) lo) | (((int64_t) hi) << 32);
#elif (defined(TARGET_S390X))
    uint64_t tod;
    asm volatile("stckf %0\n" : "=Q" (tod) : : "cc");
    return (tod * 1000 / 4096);
#else
    struct timespec time;
    clock_gettime(CLOCK_REALTIME, &time);
    return (int64_t)(time.tv_sec * 1e9 + time.tv_nsec);
#endif
}

#ifdef TICTOC
#define TIC printf("\n"); \
        int64_t tic_toc_cycles = cpucycles();

#define TOC(name) printf(" %-30s cycles: %lu \n", name, cpucycles() - tic_toc_cycles); \
        tic_toc_cycles = cpucycles();
#else
#define TIC
#define TOC(name)
#endif

#ifdef MAYO_AVX

#include <immintrin.h>

static inline void print_avx2(__m256i a){
    unsigned char *temp = (unsigned char*) &a;
    for (size_t i = 0; i < 32; i++)
    {
        printf("%X", temp[i] & 0xf);
        printf("%X", temp[i] >> 4);
        if(i%4 == 3){
            printf(" ");
        }
    }
    printf("\n");
}

static inline void print_avx2_(__m256i a){
    unsigned char *temp = (unsigned char*) &a;
    for (size_t i = 0; i < 32; i++)
    {
        printf("%X", temp[i] & 0xf);
        printf("%X", temp[i] >> 4);
        if(i%4 == 3){
            printf(" ");
        }
    }
}

#endif

#endif

