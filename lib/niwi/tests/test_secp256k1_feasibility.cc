/* FFT feasibility guard test. */

#include <cstdio>
#include "secp256k1/feasibility.h"

static int failures = 0;
static void check(bool cond, const char *msg) {
    if (!cond) { fprintf(stderr, "FAIL: %s\n", msg); failures++; }
}

int main() {
    printf("=== secp256k1 FFT feasibility test ===\n");

    size_t kMax = niwi::secp256k1_fft_max_bits();
    printf("Max FFT domain bits: %zu (2^%zu = %zu)\n",
           kMax, kMax, (size_t)1 << kMax);

    check(niwi::secp256k1_fft_feasible(0),  "2^0 feasible");
    check(niwi::secp256k1_fft_feasible(5),  "2^5 feasible");
    check(!niwi::secp256k1_fft_feasible(6), "2^6 NOT feasible");
    check(!niwi::secp256k1_fft_feasible(20),"2^20 NOT feasible");

    printf("Guard message: %s\n", niwi::secp256k1_fft_explain());

    if (failures == 0) {
        printf("All tests passed.\n");
    } else {
        printf("%d tests FAILED.\n", failures);
    }
    return failures > 0 ? 1 : 0;
}
