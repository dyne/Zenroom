#include <stddef.h>
#include "zenroom.h"

/***

HOW TO RUN THE TEST
===================

1) compile the shared library

make linux-lib

2) move the library to the /usr/lib

sudo mv src/zenroom-shared /usr/lib/libzenroom.so

3) compile the test file

gcc src/test.c -o src/test -lzenroom

4) Execute the test

./src/test

5) Check the results

expect: to have the contract executed
actual: an error about lua state failed is thrown

*/
int main(int argc, char **argv) {

    size_t outputSize = 1024 * 8;
    char *z_output = (char*)malloc(outputSize * sizeof(char));
    size_t  errorSize = 1024 * 8;
    char *z_error = (char*)malloc(errorSize * sizeof(char));

    int ret = zenroom_exec_tobuf("print(\"zen zen zen room\")", "", "{}", "{}", 3, z_output, outputSize, z_error, errorSize);


    printf("OUTPUT\n %s --- ", z_output);
    printf("ERROR\n %s --- ", z_error);

}
