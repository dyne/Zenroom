#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <zenroom.h>

int main(int argc, char **argv) {
  char ctx[2048];
  int res;
  res = zenroom_hash_init("sha512", ctx, 2048);
  if(res!=0){fprintf(stderr,"Abort on error code %u\n",res);exit(res);}
  fprintf(stderr, "hash ctx: %s\n",ctx);

  const char *str448 = "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq";
  res = zenroom_hash_update(ctx, str448, 448/8);
  if(res!=0){fprintf(stderr,"Abort on error code %u\n",res);exit(res);}
  fprintf(stderr, "hash ctx: %s\n",ctx);

  char b64[90]; // base64 is 88 with padding
  res = zenroom_hash_final(ctx, b64, 90);
  if(res!=0){fprintf(stderr,"Abort on error code %u\n",res);exit(res);}
  fprintf(stderr, "hash b64: %s\n",b64);
  assert(strcmp(b64,"IEqPxt2oLwoM7XvrjgikFlfBbvRosiioJ5vjMacDwzWW/RXBOxsH+aodO+pXeJygMa2Fx6cd1wNU7GMSOMo0RQ==")==0);
  exit(0);
}
