#include <stdio.h>
#include <stdlib.h>
#include <zenroom.h>

int main(int argc, char **argv) {
	int res;
	// default iteration is 1
	int iterations = 1;
	if(argc == 8) {
		iterations = atoi(argv[7]);
	}
	for(int i = 0; i < iterations; i++) {
		res = zencode_exec(argv[1], argv[2], argv[3], argv[4], argv[5], argv[6]);
		if(res!=0) {
			fprintf(stderr,"Abort on error code %u\n",res);
			exit(res);
		}
	}
	exit(0);
}
