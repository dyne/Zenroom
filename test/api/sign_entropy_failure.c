#include <stddef.h>
#include <stdio.h>
#include <string.h>

#include <zenroom.h>

/* ELF interposition gives this focused test a deterministic failing entropy
 * backend without adding a production-only injection API. */
int randombytes(void *buffer, size_t length) {
  (void)buffer;
  (void)length;
  return -1;
}

int main(void) {
  char output[256] = "unchanged";
  char error[256] = {0};
  const char seed[] =
      "0000000000000000000000000000000000000000000000000000000000000000"
      "0000000000000000000000000000000000000000000000000000000000000000";

  if (zenroom_sign_keygen_tobuf("eddsa", NULL, output, sizeof(output), error,
                                sizeof(error)) == 0 || output[0] != '\0' ||
      strstr(error, "error initializing the random generator") == NULL) {
    return 1;
  }
  strcpy(output, "unchanged");
  error[0] = '\0';
  if (zenroom_sign_keygen_tobuf("eddsa", "00", output, sizeof(output), error,
                                sizeof(error)) == 0 || output[0] != '\0' ||
      strstr(error, "error initializing the random generator") == NULL) {
    return 2;
  }
  if (zenroom_sign_keygen_tobuf("eddsa", seed, output, sizeof(output), error,
                                sizeof(error)) != 0 ||
      strcmp(output,
             "06b4c6f4caf4234be9dedc6983412aaf50773e788e144e3e2cd09b56f21f744d") !=
          0) {
    return 3;
  }
  return 0;
}
