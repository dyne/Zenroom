#include <amcl.h>
#include <rsa_2048.h>
#include <rsa_4096.h>

typedef struct {
	int bits;
	int hash;
	sign32 exponent;
	int max;
	csprng *rng; // random generator defined in amcl.h
	int publen; // precalculated length of public key
	int privlen; // precalculated length of a private key
} rsa;
// this structure is mostly filled on instantiation by calling
// bitchoice (zen_rsa_aux.c) by rsa_new when bits are known. It is set
// as LUA metatable for the object returned by rsa:new()
