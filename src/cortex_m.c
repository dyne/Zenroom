#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include "zenroom.h"

#ifdef ARCH_CORTEX

#include <errno.h>
#include <stdbool.h>

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
  SEMIHOSTING_SYS_GET_CMDLINE = 0x15,
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
  return semihost_call(SEMIHOSTING_SYS_WRITE, (int)args);
}

int write_to_console(const char* str){
  return semihost_call(SEMIHOSTING_SYS_WRITE0, (int)str);
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
  if (val == 0)
  {
    // ADP_Stopped_ApplicationExit
    semihost_call(SEMIHOSTING_SYS_EXIT, 0x20026);
  }
  else
  {
    // other reason
    semihost_call(SEMIHOSTING_SYS_EXIT, val);
  }
  for (;;)
    ;
}

int sys_getcmdline(void *buf, size_t size)
{
  uint32_t args[] = {
      (uint32_t)buf,
      (uint32_t)size,
  };
  return semihost_call(SEMIHOSTING_SYS_GET_CMDLINE, (int)args);
}

void load_file(char *dst, char *file)
{
  // open as read binary mode
  int fd = _open(file, 1, strlen(file));
  size_t fsize = MAX_STRING;

  char *string = malloc(fsize + 1);
  memset(string, 0, fsize);

  size_t read_byte = _read(fd, string, fsize);
  string[read_byte] = "\0";
  snprintf(dst, MAX_STRING, "%s", string);
  close(fd);
}

#define MAX_FILE_NAME 256

// TODO: to be verified how to store context, was once extern
zenroom_t *Z;

int SEMIHOSTING_STDOUT_FILENO;

// implement the fault handler
void HardFault_Handler(void)
{
  exit(EXIT_FAILURE);
}

void MemManage_Handler(void){
  exit(EXIT_FAILURE);
}

void BusFault_Handler(void){
  exit(0x20023);
}

void UsageFault_Handler(void){
  exit(EXIT_FAILURE);
}

int main(void)
{
  static char scriptfile[MAX_FILE_NAME] = {0};
  static char keysfile[MAX_FILE_NAME] = {0};
  static char datafile[MAX_FILE_NAME] = {0};
  static char script[MAX_STRING] = {0};
  static char keys[MAX_STRING] = {0};
  static char data[MAX_STRING] = {0};
  static char conffile[MAX_STRING] = {0};
  SEMIHOSTING_STDOUT_FILENO = _open("outlog", 4, 6);

  static char cmd_line[256] = {0};
  sys_getcmdline(cmd_line, 256);
  // parse the argc argv
  char *delim = " ";
  size_t cmd_len = strlen(cmd_line);
  char *ptr = strtok(cmd_line, delim);
  // ignore src/zenroom.bin
  if (strstr(ptr, "bin") != NULL)
  {
    ptr = strtok(NULL, delim);
  }

  bool zencode = false;
  int verbosity = 1;
  int retcode = EXIT_SUCCESS;

  while (ptr != NULL)
  {
    if (strncmp(ptr, "-k", 2) == 0)
    {
      ptr = strtok(NULL, delim);
      snprintf(keysfile, MAX_FILE_NAME - 1, "%s", ptr);
    }
    else if (strncmp(ptr, "-a", 2) == 0)
    {
      ptr = strtok(NULL, delim);
      snprintf(datafile, MAX_FILE_NAME - 1, "%s", ptr);
    }
    else if (strncmp(ptr, "-z", 2) == 0)
    {
      zencode = 1;
    }
    else if (strncmp(ptr, "-c", 2) == 0)
    {
      ptr = strtok(NULL, delim);
      snprintf(conffile, MAX_STRING - 1, "%s", ptr);
    }
    else
    {
      snprintf(scriptfile, MAX_FILE_NAME - 1, "%s", ptr);
    }
    ptr = strtok(NULL, delim);
  }

  if (keysfile[0] != '\0')
  {
    printf("reading KEYS from file: %s", keysfile);
    load_file(keys, keysfile);
  }

  if (datafile[0] != '\0' && verbosity)
  {
    printf("reading DATA from file: %s", datafile);
    load_file(data, datafile);
  }

  // set_debug(verbosity);
  Z = zen_init(
      (conffile[0]) ? conffile : NULL,
      (keys[0]) ? keys : NULL,
      (data[0]) ? data : NULL);

  if (!Z)
  {
    zerror(NULL, "Initialisation failed.");
    retcode = EXIT_FAILURE;
    goto failed;
  }

  if (scriptfile[0] != '\0')
  {
    ////////////////////////////////////
    // load a file as script and execute
    printf("reading Zencode from file: %s", scriptfile);
    load_file(script, scriptfile);
  }

  // configure to parse Lua or Zencode
  if (zencode)
  {
    if (verbosity)
      notice(NULL, "Direct Zencode execution");
    func(NULL, script);
  }

  if (zencode)
  {
    if (zen_exec_zencode(Z, script))
    {
      retcode = EXIT_FAILURE;
      goto failed;
    }
  }
  else if (zen_exec_script(Z, script))
  {
    retcode = EXIT_FAILURE;
    goto failed;
  }

failed:
  zen_teardown(Z);
  return retcode;
}

void _start(void)
{
  int ret = main();
  exit(ret);
}

#endif
