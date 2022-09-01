#include <stdio.h>
#include <stdlib.h>
#include <zenroom.h>

int main(int argc, char **argv) {
  int res = zenroom_hash_update(argv[1], argv[2], strlen(argv[2]));
  if(res!=0){fprintf(stderr,"Abort on error code %u\n",res);exit(res);}
  exit(0);
}
