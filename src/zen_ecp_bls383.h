// Zenroom ECP module
//
// (c) Copyright 2017-2018 Dyne.org foundation
// designed, written and maintained by Denis Roio <jaromil@dyne.org>
//
// This program is free software: you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public License
// version 3 as published by the Free Software Foundation.
//
// This program is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with this program.  If not, see
// <http://www.gnu.org/licenses/>.

// All static and generated code because runtime pointers won't work
// in ECP where we also need to change BIG types according to
// curve. So we are not using a factory like in ECDH here.

#ifndef __ZEN_ECP_BLS383_H__

#include <ecp_BLS383.h>
#include <ecp2_BLS383.h>
#include <pair_BLS383.h>

#define BIGSIZE 384
#include <zen_big_types.h>


#define ECP ECP_BLS383
#define ECP2 ECP2_BLS383


typedef struct {
	char curve[16];
	char type[16];
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

#define CURVE_A CURVE_A_BLS383
#define CURVE_B Curve_B_BLS383
#define CURVE_B_I CURVE_B_I_BLS383
#define CURVE_Gx CURVE_Gx_BLS383
#define CURVE_Gy CURVE_Gy_BLS383
#define CURVE_Order CURVE_Order_BLS383
#define CURVE_Cofactor CURVE_Cof_BLS383
#define CURVE_G2xa CURVE_Pxa_BLS383
#define CURVE_G2xb CURVE_Pxb_BLS383
#define CURVE_G2ya CURVE_Pya_BLS383
#define CURVE_G2yb CURVE_Pyb_BLS383

#define ECP_copy(d,s) ECP_BLS383_copy(d,s)
#define ECP_set(d,x,y) ECP_BLS383_set(d, x, y)
#define ECP_setx(d,x,n) ECP_BLS383_setx(d, x, n)
#define ECP_affine(d) ECP_BLS383_affine(d)
#define ECP_inf(d) ECP_BLS383_inf(d)
#define ECP_isinf(d) ECP_BLS383_isinf(d)
#define ECP_add(d,s) ECP_BLS383_add(d,s)
#define ECP_sub(d,s) ECP_BLS383_sub(d,s)
#define ECP_neg(d) ECP_BLS383_neg(d)
#define ECP_dbl(d) ECP_BLS383_dbl(d)
#define ECP_mul(d,b) ECP_BLS383_mul(d,b)
#define ECP_equals(l,r) ECP_BLS383_equals(l,r)
#define ECP_fromOctet(d,o) ECP_BLS383_fromOctet(d, o)
#define ECP_toOctet(o,d) ECP_BLS383_toOctet(o,d)
#define ECP_generator(e) ECP_BLS383_generator(e)
#define ECP_mapit(q,w) ECP_BLS383_mapit(q,w)

#define FP2 FP2_BLS383
#define FP2_from_BIGs(x,a,b) FP2_BLS383_from_BIGs(x,a,b)

#define ECP2_copy(d,s) ECP2_BLS383_copy(d,s)
#define ECP2_set(d,x,y) ECP2_BLS383_set(d, x, y)
#define ECP2_setx(d,x) ECP2_BLS383_setx(d, x)
#define ECP2_affine(d) ECP2_BLS383_affine(d)
#define ECP2_inf(d) ECP2_BLS383_inf(d)
#define ECP2_isinf(d) ECP2_BLS383_isinf(d)
#define ECP2_add(d,s) ECP2_BLS383_add(d,s)
#define ECP2_sub(d,s) ECP2_BLS383_sub(d,s)
#define ECP2_neg(d) ECP2_BLS383_neg(d)
#define ECP2_dbl(d) ECP2_BLS383_dbl(d)
#define ECP2_mul(d,b) ECP2_BLS383_mul(d,b)
#define ECP2_equals(l,r) ECP2_BLS383_equals(l,r)
#define ECP2_fromOctet(d,o) ECP2_BLS383_fromOctet(d, o)
#define ECP2_toOctet(o,d) ECP2_BLS383_toOctet(o,d)
#define ECP2_generator(e) ECP2_BLS383_generator(e)
#define ECP2_mapit(q,w) ECP2_BLS383_mapit(q,w)

#define PAIR_ate(r,p,q) PAIR_BLS383_ate(r,p,q)
#define PAIR_fexp(x) PAIR_BLS383_fexp(x)
#define PAIR_G2mul(p,b)	PAIR_BLS383_G2mul(p,b)
#define PAIR_G1mul(p,b) PAIR_BLS383_G1mul(p,b)

#endif
