#ifndef sss_RANDOMBYTES_H
#define sss_RANDOMBYTES_H

#ifdef ARCH_WIN
/* Load size_t on windows */
#include <crtdefs.h>
#else
#ifndef ARCH_CORTEX
#include <sys/syscall.h>
#endif
#include <unistd.h>
#endif /* _WIN32 */

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Write `n` bytes of high quality random bytes to `buf`
 */
int randombytes(void *buf, size_t n);

#ifdef __cplusplus
}
#endif

#endif /* sss_RANDOMBYTES_H */
