#ifndef __ZEN_ECP_H__
#define __ZEN_ECP_H__

// should abstract this away
// #include <fp12_BLS383.h>
// #include <ecp2_BLS383.h>
#include <ecp_BLS383.h>
#define ECP ECP_BLS383
#define ECP2 ECP2_BLS383
// #pragma message "BIGnum CHUNK size: 32bit"
#include <big_384_29.h>
#define  BIG  BIG_384_29

typedef struct {
	char curve[16];
	char type[16];
	int  biglen; // length in bytes of a reduced coordinate
	int  totlen; // length of a serialized octet

	BIG  order;
	ECP  val;
	// TODO: the values above make it necessary to propagate the
	// visibility on the specific curve point types to the rest of the
	// code. To abstract these and have get/set functions may save a
	// lot of boilerplate when implementing support for multiple
	// curves ECP.
} ecp;

ecp* ecp_new(lua_State *L);
ecp* ecp_arg(lua_State *L,int n);

#endif
