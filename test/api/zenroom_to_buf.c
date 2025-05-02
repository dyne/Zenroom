#include <stdio.h>
#include <stdlib.h>
#include <zenroom.h>

int main(int argc, char **argv) {
	int res;
	char stdout_buf[4096] = {0};
    char stderr_buf[4096] = {0};
	res = zenroom_exec_tobuf(argv[1], argv[2], argv[3], argv[4], argv[5], argv[6], stdout_buf, sizeof(stdout_buf), stderr_buf, sizeof(stderr_buf));
	if(res!=0){
		fprintf(stderr,"Abort on error code %u\n",res);
		fprintf(stderr, "%s", stderr_buf);
		exit(res);
	}
	fprintf(stdout, "%s", stdout_buf);
	exit(0);
}
