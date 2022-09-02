#include <stdio.h>
#include <stdlib.h>
#include <zenroom.h>

int main(int argc, char **argv) {
  int res;
  res = zenroom_hash_init(argv[1]);
  if(res!=0){fprintf(stderr,"Abort on error code %u\n",res);exit(res);}
  exit(0);
}
