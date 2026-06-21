#include <stdio.h>

#include <zenroom.h>

int main(int argc, char **argv) {
  char stdout_buf[8] = {0};
  char stderr_buf[256] = {0};
  int res = zenroom_sign_verify_tobuf(argv[1], argv[2], argv[3], argv[4],
                                      stdout_buf, sizeof(stdout_buf),
                                      stderr_buf, sizeof(stderr_buf));
  if (res) {
    fprintf(stderr, "%s", stderr_buf);
    return res;
  }
  fprintf(stdout, "%s", stdout_buf);
  return 0;
}
