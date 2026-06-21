#include <stdio.h>

#include <zenroom.h>

int main(int argc, char **argv) {
  char stdout_buf[256] = {0};
  char stderr_buf[256] = {0};
  int res = zenroom_sign_keygen_tobuf(argv[1], argc > 2 ? argv[2] : NULL,
                                      stdout_buf, sizeof(stdout_buf),
                                      stderr_buf, sizeof(stderr_buf));
  if (res) {
    fprintf(stderr, "%s", stderr_buf);
    return res;
  }
  fprintf(stdout, "%s", stdout_buf);
  return 0;
}
