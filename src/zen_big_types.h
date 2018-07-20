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

#if BIGSIZE == 384
#if CHUNK == 64
// #pragma message "BIGnum CHUNK size: 64bit"
// #include <big_384_58.h>
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
#define BIG_add(d,l,r) BIG_384_58_add(d,l,r)
#define BIG_sub(d,l,r) BIG_384_58_sub(d,l,r)
#define BIG_mul(d,l,r) BIG_384_58_smul(d,l,r)
#define BIG_mod(x,n) BIG_384_58_mod(x,n)
#define BIG_div(x,n) BIG_384_58_sdiv(x,n)
#define BIG_modmul(x,y,z,n) BIG_384_58_modmul(x,y,z,n)
#define BIG_moddiv(x,y,z,n) BIG_384_58_moddiv(x,y,z,n)
#define BIG_modsqr(x,y,n) BIG_384_58_modsqr(x,y,n)
#define BIG_modneg(x,y,n) BIG_384_58_modneg(x,y,n)
#define BIG_jacobi(x,y) BIG_384_58_jacobi(x,y)

#elif CHUNK == 32
// #pragma message "BIGnum CHUNK size: 32bit"
//#include <big_384_29.h>
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
#define BIG_add(d,l,r) BIG_384_29_add(d,l,r)
#define BIG_sub(d,l,r) BIG_384_29_sub(d,l,r)
#define BIG_mul(d,l,r) BIG_384_29_smul(d,l,r)
#define BIG_mod(x,n) BIG_384_29_mod(x,n)
#define BIG_div(x,n) BIG_384_29_sdiv(x,n)
#define BIG_modmul(x,y,z,n) BIG_384_29_modmul(x,y,z,n)
#define BIG_moddiv(x,y,z,n) BIG_384_29_moddiv(x,y,z,n)
#define BIG_modsqr(x,y,n) BIG_384_29_modsqr(x,y,n)
#define BIG_modneg(x,y,n) BIG_384_29_modneg(x,y,n)
#define BIG_jacobi(x,y) BIG_384_29_jacobi(x,y)

#define FP FP_BLS383
#define FP_zero(b) FP_BLS383_zero(b)
#define FP_copy(d,s) FP_BLS383_copy(d,s)
#define FP_eq(l,r) FP_BLS383_equals(l,r)
#define FP_cmove(d,s,c) FP_BLS383_cmove(d,s,c)
#define FP_fromBig(f,b) FP_BLS383_nres(f,b)
#define FP_toBig(b,f) FP_BLS383_redc(b,f)
#define FP_mul(d, l, r) FP_BLS383_mul(d, l, r)
#define FP_imul(d, l, r) FP_BLS383_imul(d, l, r)
#define FP_sqr(d, s) FP_BLS383_sqr(d, s)
#define FP_add(d, l, r) FP_BLS383_add(d, l, r)
#define FP_sub(d, l, r) FP_BLS383_sub(d, l, r)
#define FP_div2(d, s) FP_BLS383_div2(d,s)
#define FP_pow(d, l, r) FP_BLS383_pow(d,l,r)
#define FP_sqrt(d,s) FP_BLS383_sqrt(d,s)
#define FP_neg(d,s) FP_BLS383_neg(d,s)
#define FP_reduce(f) FP_BLS383_reduce(f)
#define FP_norm(f) FP_BLS383_norm(f)
#define FP_qr(f) FP_BLS383_qr(f)
#define FP_inv(d,s) FP_BLS383_inv(d,s)

#elif CHUNK == 16
#error "BIGnum CHUNK size: 16bit PLATFORM NOT SUPPORTED"
#endif // CHUNK
#endif // BIGSIZE

#endif // _H_
