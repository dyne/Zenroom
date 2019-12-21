/*
	Licensed to the Apache Software Foundation (ASF) under one
	or more contributor license agreements.  See the NOTICE file
	distributed with this work for additional information
	regarding copyright ownership.  The ASF licenses this file
	to you under the Apache License, Version 2.0 (the
	"License"); you may not use this file except in compliance
	with the License.  You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing,
	software distributed under the License is distributed on an
	"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
	KIND, either express or implied.  See the License for the
	specific language governing permissions and limitations
	under the License.
*/

/**
 * @file ecp2_ZZZ.h
 * @author Mike Scott
 * @brief ECP2 Header File
 *
 */

#ifndef ECP2_ZZZ_H
#define ECP2_ZZZ_H

#include "fp2_YYY.h"
#include "config_curve_ZZZ.h"

/**
	@brief ECP2 Structure - Elliptic Curve Point over quadratic extension field
*/

typedef struct
{
//    int inf; /**< Infinity Flag */
    FP2_YYY x;   /**< x-coordinate of point */
    FP2_YYY y;   /**< y-coordinate of point */
    FP2_YYY z;   /**< z-coordinate of point */
} ECP2_ZZZ;


/* Curve Params - see rom_zzz.c */
extern const int CURVE_A_ZZZ;		/**< Elliptic curve A parameter */
extern const int CURVE_B_I_ZZZ;		/**< Elliptic curve B parameter */
extern const BIG_XXX CURVE_B_ZZZ;     /**< Elliptic curve B parameter */
extern const BIG_XXX CURVE_Order_ZZZ; /**< Elliptic curve group order */
extern const BIG_XXX CURVE_Cof_ZZZ;   /**< Elliptic curve cofactor */
extern const BIG_XXX CURVE_Bnx_ZZZ;   /**< Elliptic curve parameter */

extern const BIG_XXX Fra_YYY; /**< real part of BN curve Frobenius Constant */
extern const BIG_XXX Frb_YYY; /**< imaginary part of BN curve Frobenius Constant */


/* Generator point on G1 */
extern const BIG_XXX CURVE_Gx_ZZZ; /**< x-coordinate of generator point in group G1  */
extern const BIG_XXX CURVE_Gy_ZZZ; /**< y-coordinate of generator point in group G1  */

/* For Pairings only */

/* Generator point on G2 */
extern const BIG_XXX CURVE_Pxa_ZZZ; /**< real part of x-coordinate of generator point in group G2 */
extern const BIG_XXX CURVE_Pxb_ZZZ; /**< imaginary part of x-coordinate of generator point in group G2 */
extern const BIG_XXX CURVE_Pya_ZZZ; /**< real part of y-coordinate of generator point in group G2 */
extern const BIG_XXX CURVE_Pyb_ZZZ; /**< imaginary part of y-coordinate of generator point in group G2 */

/* ECP2 E(Fp2) prototypes */
/**	@brief Tests for ECP2 point equal to infinity
 *
	@param P ECP2 point to be tested
	@return 1 if infinity, else returns 0
 */
extern int ECP2_ZZZ_isinf(ECP2_ZZZ *P);
/**	@brief Copy ECP2 point to another ECP2 point
 *
	@param P ECP2 instance, on exit = Q
	@param Q ECP2 instance to be copied
 */
extern void ECP2_ZZZ_copy(ECP2_ZZZ *P,ECP2_ZZZ *Q);
/**	@brief Set ECP2 to point-at-infinity
 *
	@param P ECP2 instance to be set to infinity
 */
extern void ECP2_ZZZ_inf(ECP2_ZZZ *P);
/**	@brief Tests for equality of two ECP2s
 *
	@param P ECP2 instance to be compared
	@param Q ECP2 instance to be compared
	@return 1 if P=Q, else returns 0
 */
extern int ECP2_ZZZ_equals(ECP2_ZZZ *P,ECP2_ZZZ *Q);
/**	@brief Converts an ECP2 point from Projective (x,y,z) coordinates to affine (x,y) coordinates
 *
	@param P ECP2 instance to be converted to affine form
 */
extern void ECP2_ZZZ_affine(ECP2_ZZZ *P);
/**	@brief Extract x and y coordinates of an ECP2 point P
 *
	If x=y, returns only x
	@param x FP2 on exit = x coordinate of point
	@param y FP2 on exit = y coordinate of point (unless x=y)
	@param P ECP2 instance (x,y)
	@return -1 if P is point-at-infinity, else 0
 */
extern int ECP2_ZZZ_get(FP2_YYY *x,FP2_YYY *y,ECP2_ZZZ *P);
/**	@brief Formats and outputs an ECP2 point to the console, converted to affine coordinates
 *
	@param P ECP2 instance to be printed
 */
extern void ECP2_ZZZ_output(ECP2_ZZZ *P);
/**	@brief Formats and outputs an ECP2 point to the console, in projective coordinates
 *
	@param P ECP2 instance to be printed
 */
extern void ECP2_ZZZ_outputxyz(ECP2_ZZZ *P);
/**	@brief Formats and outputs an ECP2 point to an octet string
 *
	The octet string is created in the form x|y.
	Convert the real and imaginary parts of the x and y coordinates to big-endian base 256 form.
	@param S output octet string
	@param P ECP2 instance to be converted to an octet string
 */
extern void ECP2_ZZZ_toOctet(octet *S,ECP2_ZZZ *P);
/**	@brief Creates an ECP2 point from an octet string
 *
	The octet string is in the form x|y
	The real and imaginary parts of the x and y coordinates are in big-endian base 256 form.
	@param P ECP2 instance to be created from the octet string
	@param S input octet string
	return 1 if octet string corresponds to a point on the curve, else 0
 */
extern int ECP2_ZZZ_fromOctet(ECP2_ZZZ *P,octet *S);
/**	@brief Calculate Right Hand Side of curve equation y^2=f(x)
 *
	Function f(x)=x^3+Ax+B
	Used internally.
	@param r FP2 value of f(x)
	@param x FP2 instance
 */
extern void ECP2_ZZZ_rhs(FP2_YYY *r,FP2_YYY *x);
/**	@brief Set ECP2 to point(x,y) given x and y
 *
	Point P set to infinity if no such point on the curve.
	@param P ECP2 instance to be set (x,y)
	@param x FP2 x coordinate of point
	@param y FP2 y coordinate of point
	@return 1 if point exists, else 0
 */
extern int ECP2_ZZZ_set(ECP2_ZZZ *P,FP2_YYY *x,FP2_YYY *y);
/**	@brief Set ECP to point(x,[y]) given x
 *
	Point P set to infinity if no such point on the curve. Otherwise y coordinate is calculated from x.
	@param P ECP instance to be set (x,[y])
	@param x BIG x coordinate of point
	@return 1 if point exists, else 0
 */
extern int ECP2_ZZZ_setx(ECP2_ZZZ *P,FP2_YYY *x);
/**	@brief Negation of an ECP2 point
 *
	@param P ECP2 instance, on exit = -P
 */
extern void ECP2_ZZZ_neg(ECP2_ZZZ *P);
/**	@brief Doubles an ECP2 instance P
 *
	@param P ECP2 instance, on exit =2*P
 */
extern int ECP2_ZZZ_dbl(ECP2_ZZZ *P);
/**	@brief Adds ECP2 instance Q to ECP2 instance P
 *
	@param P ECP2 instance, on exit =P+Q
	@param Q ECP2 instance to be added to P
 */
extern int ECP2_ZZZ_add(ECP2_ZZZ *P,ECP2_ZZZ *Q);
/**	@brief Subtracts ECP instance Q from ECP2 instance P
 *
	@param P ECP2 instance, on exit =P-Q
	@param Q ECP2 instance to be subtracted from P
 */
extern void ECP2_ZZZ_sub(ECP2_ZZZ *P,ECP2_ZZZ *Q);
/**	@brief Multiplies an ECP2 instance P by a BIG, side-channel resistant
 *
	Uses fixed sized windows.
	@param P ECP2 instance, on exit =b*P
	@param b BIG number multiplier

 */
extern void ECP2_ZZZ_mul(ECP2_ZZZ *P,BIG_XXX b);
/**	@brief Multiplies an ECP2 instance P by the internal modulus p, using precalculated Frobenius constant f
 *
	Fast point multiplication using Frobenius
	@param P ECP2 instance, on exit = p*P
	@param f FP2 precalculated Frobenius constant

 */
extern void ECP2_ZZZ_frob(ECP2_ZZZ *P,FP2_YYY *f);
/**	@brief Calculates P=b[0]*Q[0]+b[1]*Q[1]+b[2]*Q[2]+b[3]*Q[3]
 *
	@param P ECP2 instance, on exit = b[0]*Q[0]+b[1]*Q[1]+b[2]*Q[2]+b[3]*Q[3]
	@param Q ECP2 array of 4 points
	@param b BIG array of 4 multipliers
 */
extern void ECP2_ZZZ_mul4(ECP2_ZZZ *P,ECP2_ZZZ *Q,BIG_XXX *b);

/**	@brief Maps random BIG to curve point of correct order
 *
	@param P ECP2 instance of correct order
	@param w OCTET byte array to be mapped
 */
extern void ECP2_ZZZ_mapit(ECP2_ZZZ *P,octet *w);

/**	@brief Get Group Generator from ROM
 *
	@param G ECP2 instance
 */
extern void ECP2_ZZZ_generator(ECP2_ZZZ *G);

#endif
