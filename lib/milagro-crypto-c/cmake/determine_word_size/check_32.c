#include <stdint.h>

int main() {
#if (__WORDSIZE == 32)
    return 0;
#elif (defined(_WIN32) && !defined(_WIN64))
    return 0;
#else
#error "Wordsize is not 32"
#endif
}
