#include <stdlib.h>

#include <zenroom.h>

int main(int argc, char **argv) {
  return zenroom_pbkdf2_hex(argv[1], argv[2], argv[3], atoi(argv[4]), atoi(argv[5]));
}
