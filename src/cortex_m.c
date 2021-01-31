#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "zenroom.h"

#ifdef ARCH_CORTEX

#include <errno.h>
#undef errno
extern int errno;

enum semihost_ops
{
  SEMIHOSTING_SYS_OPEN = 0x01,
  SEMIHOSTING_SYS_CLOSE = 0x02,
  SEMIHOSTING_SYS_WRITEC = 0x03,
  SEMIHOSTING_SYS_WRITE0 = 0x04,
  SEMIHOSTING_SYS_WRITE = 0x05,
  SEMIHOSTING_SYS_READ = 0x06,
  SEMIHOSTING_SYS_READC = 0x07,
  SEMIHOSTING_SYS_ISTTY = 0x09,
  SEMIHOSTING_SYS_SEEK = 0x0A,
  SEMIHOSTING_SYS_EXIT = 0x18,
};

static inline int semihost_call(int R0, int R1)
{
  int rc;
  __asm__ volatile(
      "mov r0, %1\n" /* move int R0 to register r0 */
      "mov r1, %2\n" /* move int R1 to register r1 */
      "bkpt #0xAB\n" /* thumb mode semihosting call */
      "mov %0, r0"   /* move register r0 to int rc */
      : "=r"(rc)
      : "r"(R0), "r"(R1)
      : "r0", "r1", "ip", "lr", "memory", "cc");
  return rc;
}

int _isatty(int fd)
{
  return semihost_call(SEMIHOSTING_SYS_ISTTY, (int)&fd);
}

int _read(int fd, void *buf, size_t len)
{
  unsigned int args[] = {
      (unsigned int)fd,
      (unsigned int)buf,
      (unsigned int)len,
  };
  return semihost_call(SEMIHOSTING_SYS_READ, (int)args);
}

int _write(int fd, const void *buf, size_t len)
{
  unsigned int args[] = {
      (unsigned int)fd,
      (unsigned int)buf,
      (unsigned int)len,
  };
  return semihost_call(SEMIHOSTING_SYS_WRITE0, (int)buf);
}

int _lseek(int fd, int off, int whence)
{
  return -1;
}

int _fstat(int fd, void *st)
{
  return -1;
}

int _close(int fd)
{
  return semihost_call(SEMIHOSTING_SYS_CLOSE, (int)&fd);
}

int _open(const char *name,
          int flags,
          int mode)
{
  unsigned int args[] = {
      (unsigned int)name,
      (unsigned int)flags,
      (unsigned int)mode,
  };
  return semihost_call(SEMIHOSTING_SYS_OPEN, (int)&args);
}

void abort(void)
{
  while (1)
  {
    /* Panic! */
  }
}

void exit(int val)
{
  semihost_call(SEMIHOSTING_SYS_EXIT, val);
  for (;;)
    ;
}

static const char zenroom_test_code[] = "print('Hello, world!')";

int main(void)
{
  zenroom_exec(zenroom_test_code, NULL, NULL, NULL);

  return 0;
}

void _start(void)
{
  main();
  exit(0);
}

#endif
