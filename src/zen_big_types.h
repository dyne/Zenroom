#ifndef __ZEN_BIG_TYPES_H__
#define __ZEN_BIG_TYPES_H__
#include <arch.h>

#if CHUNK == 64
#pragma message "BIGnum CHUNK size: 64bit"
#include <big_384_58.h>
#define big BIG_384_58
#define modbytes MODBYTES_384_58
#define big_zero(b) BIG_384_58_zero(b) 
#define big_fromBytesLen(b,v,l) BIG_384_58_fromBytesLen(b,v,l)
#define big_inc(b,n) BIG_384_58_inc(b,n)
#define big_norm(b) BIG_384_58_norm(b)
#define big_nbits(b) BIG_384_58_nbits(b)
#define big_copy(b,a) BIG_384_58_copy(b,a)
#define big_shr(b,a) BIG_384_58_shr(b,a)
#define big_toBytes(b,a) BIG_384_58_toBytes(b,a)
#elif CHUNK == 32
#pragma message "BIGnum CHUNK size: 32bit"
#include <big_384_29.h>
#define big BIG_384_29
#define modbytes MODBYTES_384_29
#define big_zero(b) BIG_384_29_zero(b) 
#define big_fromBytesLen(b,v,l) BIG_384_29_fromBytesLen(b,v,l)
#define big_inc(b,n) BIG_384_29_inc(b,n)
#define big_norm(b) BIG_384_29_norm(b)
#define big_nbits(b) BIG_384_29_nbits(b)
#define big_copy(b,a) BIG_384_29_copy(b,a)
#define big_shr(b,a) BIG_384_29_shr(b,a)
#define big_toBytes(b,a) BIG_384_29_toBytes(b,a)
#elif CHUNK == 16
#error "BIGnum CHUNK size: 16bit PLATFORM NOT SUPPORTED"
#endif

#endif
