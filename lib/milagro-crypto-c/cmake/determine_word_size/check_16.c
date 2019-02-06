#include <stdint.h>

int main() {
#if (__WORDSIZE == 16)
    return 0;
#else
#error "Wordsize is not 16"
#endif
}
