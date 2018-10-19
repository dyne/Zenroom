/*  Zenroom (DECODE project)
 *
 *  (c) Copyright 2017-2018 Dyne.org foundation
 *  designed, written and maintained by Denis Roio <jaromil@dyne.org>
 *
 * This source code is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Public License as published
 * by the Free Software Foundation; either version 3 of the License,
 * or (at your option) any later version.
 *
 * This source code is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * Please refer to the GNU Public License for more details.
 *
 * You should have received a copy of the GNU Public License along with
 * this source code; if not, write to:
 * Free Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#ifndef __ZEN_BIG_TYPES_H__
#define __ZEN_BIG_TYPES_H__
#include <arch.h>

#include <fp12_BLS383.h>
// cascades includes for big_ fp_ fp2_ and fp4_

// instance is in rom_field_XXX.c and included by fp_XXX.h
#define Modulus Modulus_BLS383
#define CURVE_Gx CURVE_Gx_BLS383
#define CURVE_Gy CURVE_Gy_BLS383

#if BIGSIZE == 384
#if CHUNK == 64
// #pragma message "BIGnum CHUNK size: 64bit"
// #include <big_384_58.h>
#define  BIG  BIG_384_58
// #define DBIG DBIG_384_58
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
#define BIG_add(d,l,r) BIG_384_58_add(d,l,r)
#define BIG_sub(d,l,r) BIG_384_58_sub(d,l,r)
#define BIG_mul(d,l,r) BIG_384_58_smul(d,l,r)
#define BIG_mod(x,n) BIG_384_58_mod(x,n)
// #define BIG_dmod(a,b,c) BIG_384_58_dmod(a,b,c)
#define BIG_div(x,n) BIG_384_58_sdiv(x,n)
#define BIG_modmul(x,y,z,n) BIG_384_58_modmul(x,y,z,n)
#define BIG_moddiv(x,y,z,n) BIG_384_58_moddiv(x,y,z,n)
#define BIG_modsqr(x,y,n) BIG_384_58_modsqr(x,y,n)
#define BIG_modneg(x,y,n) BIG_384_58_modneg(x,y,n)
#define BIG_jacobi(x,y) BIG_384_58_jacobi(x,y)
#define BIG_random(m,r) BIG_384_58_random(m,r)
#define BIG_randomnum(m,q,r) BIG_384_58_randomnum(m,q,r)

#elif CHUNK == 32
// #pragma message "BIGnum CHUNK size: 32bit"
//#include <big_384_29.h>
#define  BIG  BIG_384_29
#define  DBIG  DBIG_384_29

// #define DBIG DBIG_384_29
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
#define BIG_add(d,l,r) BIG_384_29_add(d,l,r)
#define BIG_sub(d,l,r) BIG_384_29_sub(d,l,r)
#define BIG_mul(d,l,r) BIG_384_29_mul(d,l,r)
#define BIG_mod(x,n) BIG_384_29_mod(x,n)
// #define BIG_dmod(a,b,c) BIG_384_29_dmod(a,b,c)
#define BIG_div(x,n) BIG_384_29_sdiv(x,n)
#define BIG_modmul(x,y,z,n) BIG_384_29_modmul(x,y,z,n)
#define BIG_moddiv(x,y,z,n) BIG_384_29_moddiv(x,y,z,n)
#define BIG_modsqr(x,y,n) BIG_384_29_modsqr(x,y,n)
#define BIG_modneg(x,y,n) BIG_384_29_modneg(x,y,n)
#define BIG_jacobi(x,y) BIG_384_29_jacobi(x,y)
#define BIG_random(m,r) BIG_384_29_random(m,r)
#define BIG_randomnum(m,q,r) BIG_384_29_randomnum(m,q,r)

#define BIG_sqr(x,y) BIG_384_29_sqr(x,y);
#define BIG_dcopy(d,s) BIG_384_29_dcopy(d,s)
#define BIG_sducopy(d,s) BIG_384_29_sducopy(d,s)
#define BIG_sdcopy(d,s) BIG_384_29_sdcopy(d,s)
#define BIG_dnorm(x) BIG_384_29_dnorm(x)
#define BIG_dcomp(l,r) BIG_384_29_dcomp(l,r)
#define BIG_dscopy(d,s) BIG_384_29_dscopy(d,s)
#define BIG_dsub(d,l,r) BIG_384_29_dsub(d,l,r)
#define BIG_dadd(d,l,r) BIG_384_29_dadd(d,l,r)
#define BIG_dmod(d,l,r) BIG_384_29_dmod(d,l,r)
#define BIG_dfromBytesLen(d,o,l) BIG_384_29_dfromBytesLen(d,o,l)
#define BIG_dshr(b,n) BIG_384_29_dshr(b,n)
#define BIG_dzero(d) BIG_384_29_dzero(d)
#define BIG_dnbits(d) BIG_384_29_dnbits(d)

#define FP FP_BLS383
#define FP_copy(d,s) FP_BLS383_copy(d,s)
#define FP_redc(x,y) FP_BLS383_redc(x,y)
#define FP_reduce(x) FP_BLS383_reduce(x)

#define FP12 FP12_BLS383
/* #define FP12_zero(b) FP12_BLS383_zero(b) */
#define FP12_copy(d,s) FP12_BLS383_copy(d,s)
#define FP12_eq(l,r) FP12_BLS383_equals(l,r)
/* #define FP12_cmove(d,s,c) FP12_BLS383_cmove(d,s,c) */
#define FP12_fromOctet(f,o) FP12_BLS383_fromOctet(f,o)
#define FP12_toOctet(o,f) FP12_BLS383_toOctet(o,f)
#define FP12_mul(l, r) FP12_BLS383_mul(l, r)
/* #define FP12_imul(d, l, r) FP12_BLS383_imul(d, l, r) */
#define FP12_sqr(d, s) FP12_BLS383_sqr(d, s)
/* #define FP12_add(d, l, r) FP12_BLS383_add(d, l, r)
#define FP12_sub(d, l, r) FP12_BLS383_sub(d, l, r) */
#define FP12_div2(d, s) FP12_BLS383_div2(d,s)
#define FP12_pow(r, x, b) FP12_BLS383_pow(r,x,b)
// #define FP12_pinpow(r, x, b) FP12_BLS383_pinpow(r,x,b)

// #define FP12_sqrt(d,s) FP12_BLS383_sqrt(d,s)
// #define FP12_neg(d,s) FP12_BLS383_neg(d,s)
// #define FP12_reduce(f) FP12_BLS383_reduce(f)
// #define FP12_norm(f) FP12_BLS383_norm(f)
// #define FP12_qr(f) FP12_BLS383_qr(f)
#define FP12_inv(d,s) FP12_BLS383_inv(d,s)

#elif CHUNK == 16
#error "BIGnum CHUNK size: 16bit PLATFORM NOT SUPPORTED"
#endif // CHUNK
#endif // BIGSIZE

#endif // _H_
