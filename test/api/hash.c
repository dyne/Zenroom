#include <stdio.h>
#include <stdlib.h>
#include <zenroom.h>

int main(int argc, char **argv) {
  char ctx[2048];
  int res;
  res = zenroom_hash_init("sha512", ctx, 2048);
  if(res != 0) {
    fprintf(stderr,"Abort on error code %u\n",res);
    exit(res);
  }
  fprintf(stderr, "hash ctx: %s\n",ctx);

  // const char *str448 = "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq";

  // res = zenroom_hash_update(ctx, str448, 448/8);
  exit(0);
}
