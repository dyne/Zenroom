#ifndef __ZEN_ECDH_H__
#define __ZEN_ECDH_H__

#include <zen_octet.h>
#include <pbc_support.h>

typedef struct {
	// function pointers
	int (*ECP__KEY_PAIR_GENERATE)(csprng *R,octet *s,octet *W);
	int (*ECP__PUBLIC_KEY_VALIDATE)(octet *W);
	int (*ECP__SVDP_DH)(octet *s,octet *W,octet *K);
	void (*ECP__ECIES_ENCRYPT)(int h,octet *P1,octet *P2,
	                           csprng *R,octet *W,octet *M,int len,
	                           octet *V,octet *C,octet *T);
	int (*ECP__ECIES_DECRYPT)(int h,octet *P1,octet *P2,
	                          octet *V,octet *C,octet *T,
	                          octet *U,octet *M);
	int (*ECP__SP_DSA)(int h,csprng *R,octet *k,octet *s,
	                   octet *M,octet *c,octet *d);
	int (*ECP__VP_DSA)(int h,octet *W,octet *M,octet *c,octet *d);
	csprng *rng;
	int keysize;
	int fieldsize;
	int hash; // hash type is also bytes length of hash
	char curve[16]; // just short names
	octet *pubkey;
	int publen;
	octet *seckey;
	int seclen;
} ecdh;

#endif
