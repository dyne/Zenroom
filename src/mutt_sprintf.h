/*
 * snprintf.h -- interface for our fixup vsnprintf() etc. functions
 */

#ifndef MUTT_SPRINTF_H
#define MUTT_SPRINTF_H 1

#include <stddef.h>
#include <stdarg.h>
#include <hedley.h>

HEDLEY_INLINE
int mutt_vsnprintf(char *str, size_t count, const char *fmt, va_list args);

HEDLEY_PRINTF_FORMAT(3,4)
HEDLEY_INLINE
int mutt_snprintf(char *str, size_t count, const char *fmt, ...);

#endif /* snprintf.h */
