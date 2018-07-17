#ifndef __ZEN_BIG_TYPES_H__
#define __ZEN_BIG_TYPES_H__
#include <arch.h>

#if BIGSIZE == 384
#if CHUNK == 64
#pragma message "BIGnum CHUNK size: 64bit"
#include <big_384_58.h>
#define BIG BIG_384_58
#define modbytes MODBYTES_384_58
#define BIG_zero(b) BIG_384_58_zero(b)
#define BIG_fromBytesLen(b,v,l) BIG_384_58_fromBytesLen(b,v,l)
#define BIG_inc(b,n) BIG_384_58_inc(b,n)
#define BIG_norm(b) BIG_384_58_norm(b)
#define BIG_nbits(b) BIG_384_58_nbits(b)
#define BIG_copy(b,a) BIG_384_58_copy(b,a)
#define BIG_rcopy(b,a) BIG_384_58_rcopy(b,a)
#define BIG_shr(b,a) BIG_384_58_shr(b,a)
#define BIG_toBytes(b,a) BIG_384_58_toBytes(b,a)
#define BIG_comp(l,r) BIG_384_58_comp(l,r)
#elif CHUNK == 32
#pragma message "BIGnum CHUNK size: 32bit"
#include <big_384_29.h>
#define BIG BIG_384_29
#define modbytes MODBYTES_384_29
#define BIG_zero(b) BIG_384_29_zero(b)
#define BIG_fromBytesLen(b,v,l) BIG_384_29_fromBytesLen(b,v,l)
#define BIG_inc(b,n) BIG_384_29_inc(b,n)
#define BIG_norm(b) BIG_384_29_norm(b)
#define BIG_nbits(b) BIG_384_29_nbits(b)
#define BIG_copy(b,a) BIG_384_29_copy(b,a)
#define BIG_rcopy(b,a) BIG_384_29_rcopy(b,a)
#define BIG_shr(b,a) BIG_384_29_shr(b,a)
#define BIG_toBytes(b,a) BIG_384_29_toBytes(b,a)
#define BIG_comp(l,r) BIG_384_29_comp(l,r)
#elif CHUNK == 16
#error "BIGnum CHUNK size: 16bit PLATFORM NOT SUPPORTED"
#endif // CHUNK
#endif // BIGSIZE

#endif // _H_
