#include <stdint.h>

int main() {
#if (__WORDSIZE == 64)
    return 0;
#elif defined(_WIN64)
    return 0;
#else
#error "Wordsize is not 64"
#endif
}
