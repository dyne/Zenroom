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
#define BIGSIZE 384
#include <zen_big_types.h>
#define ECP ECP_BLS383
#define CURVE_A CURVE_A_BLS383
#define CURVE_B Curve_B_BLS383
#define CURVE_B_I CURVE_B_I_BLS383
#define CURVE_Gx CURVE_Gx_BLS383
#define CURVE_Gy CURVE_Gy_BLS383
#define CURVE_Order CURVE_Order_BLS383
#define CURVE_Cofactor CURVE_Cof_BLS383
#define ECP_copy(d,s) ECP_BLS383_copy(d,s)
#define ECP_set(d,x,y) ECP_BLS383_set(d, x, y)
#define ECP_setx(d,x,y) ECP_BLS383_setx(d, x, y)
#define ECP_affine(d) ECP_BLS383_affine(d)
#define ECP_inf(d) ECP_BLS383_inf(d)
#define ECP_isinf(d) ECP_BLS383_isinf(d)
#define ECP_mapit(d, s) ECP_BLS383_mapit(d,s)
#define ECP_add(d,s) ECP_BLS383_add(d,s)
#define ECP_sub(d,s) ECP_BLS383_sub(d,s)
#define ECP_neg(d) ECP_BLS383_neg(d)
#define ECP_dbl(d) ECP_BLS383_dbl(d)
#define ECP_mul(d,b) ECP_BLS383_mul(d,b)
#define ECP_equals(l,r) ECP_BLS383_equals(l,r)
#define ECP_fromOctet(d,o) ECP_BLS383_fromOctet(d, o)
#define ECP_toOctet(o,d) ECP_BLS383_toOctet(o,d)
#define FP_redc(x,s) FP_BLS383_redc(x,s)

#endif
