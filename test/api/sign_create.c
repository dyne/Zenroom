#include <stdio.h>
#include <stdlib.h>
#include <zenroom.h>

int main(int argc, char **argv) {
  int res;
  res = zenroom_sign_create(argv[1], argv[2], argv[3]);
  if(res!=0){fprintf(stderr,"Abort on error code %u\n",res);exit(res);}
  exit(0);
}
