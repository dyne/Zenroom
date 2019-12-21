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
 * @file ecp_ZZZ.h
 * @author Mike Scott
 * @brief ECP Header File
 *
 */

#ifndef ECP_ZZZ_H
#define ECP_ZZZ_H

#include "fp_YYY.h"
#include "config_curve_ZZZ.h"

/* Curve Params - see rom_zzz.c */
extern const int CURVE_A_ZZZ;         /**< Elliptic curve A parameter */
extern const int CURVE_Cof_I_ZZZ;     /**< Elliptic curve cofactor */
extern const int CURVE_B_I_ZZZ;       /**< Elliptic curve B_i parameter */
extern const BIG_XXX CURVE_B_ZZZ;     /**< Elliptic curve B parameter */
extern const BIG_XXX CURVE_Order_ZZZ; /**< Elliptic curve group order */
extern const BIG_XXX CURVE_Cof_ZZZ;   /**< Elliptic curve cofactor */

/* Generator point on G1 */
extern const BIG_XXX CURVE_Gx_ZZZ; /**< x-coordinate of generator point in group G1  */
extern const BIG_XXX CURVE_Gy_ZZZ; /**< y-coordinate of generator point in group G1  */


/* For Pairings only */

/* Generator point on G2 */
extern const BIG_XXX CURVE_Pxa_ZZZ; /**< real part of x-coordinate of generator point in group G2 */
extern const BIG_XXX CURVE_Pxb_ZZZ; /**< imaginary part of x-coordinate of generator point in group G2 */
extern const BIG_XXX CURVE_Pya_ZZZ; /**< real part of y-coordinate of generator point in group G2 */
extern const BIG_XXX CURVE_Pyb_ZZZ; /**< imaginary part of y-coordinate of generator point in group G2 */


/*** needed for BLS24 curves ***/

extern const BIG_XXX CURVE_Pxaa_ZZZ; /**< real part of x-coordinate of generator point in group G2 */
extern const BIG_XXX CURVE_Pxab_ZZZ; /**< imaginary part of x-coordinate of generator point in group G2 */
extern const BIG_XXX CURVE_Pxba_ZZZ; /**< real part of x-coordinate of generator point in group G2 */
extern const BIG_XXX CURVE_Pxbb_ZZZ; /**< imaginary part of x-coordinate of generator point in group G2 */
extern const BIG_XXX CURVE_Pyaa_ZZZ; /**< real part of y-coordinate of generator point in group G2 */
extern const BIG_XXX CURVE_Pyab_ZZZ; /**< imaginary part of y-coordinate of generator point in group G2 */
extern const BIG_XXX CURVE_Pyba_ZZZ; /**< real part of y-coordinate of generator point in group G2 */
extern const BIG_XXX CURVE_Pybb_ZZZ; /**< imaginary part of y-coordinate of generator point in group G2 */

/*** needed for BLS48 curves ***/

extern const BIG_XXX CURVE_Pxaaa_ZZZ; /**< real part of x-coordinate of generator point in group G2 */
extern const BIG_XXX CURVE_Pxaab_ZZZ; /**< imaginary part of x-coordinate of generator point in group G2 */
extern const BIG_XXX CURVE_Pxaba_ZZZ; /**< real part of x-coordinate of generator point in group G2 */
extern const BIG_XXX CURVE_Pxabb_ZZZ; /**< imaginary part of x-coordinate of generator point in group G2 */
extern const BIG_XXX CURVE_Pxbaa_ZZZ; /**< real part of x-coordinate of generator point in group G2 */
extern const BIG_XXX CURVE_Pxbab_ZZZ; /**< imaginary part of x-coordinate of generator point in group G2 */
extern const BIG_XXX CURVE_Pxbba_ZZZ; /**< real part of x-coordinate of generator point in group G2 */
extern const BIG_XXX CURVE_Pxbbb_ZZZ; /**< imaginary part of x-coordinate of generator point in group G2 */

extern const BIG_XXX CURVE_Pyaaa_ZZZ; /**< real part of y-coordinate of generator point in group G2 */
extern const BIG_XXX CURVE_Pyaab_ZZZ; /**< imaginary part of y-coordinate of generator point in group G2 */
extern const BIG_XXX CURVE_Pyaba_ZZZ; /**< real part of y-coordinate of generator point in group G2 */
extern const BIG_XXX CURVE_Pyabb_ZZZ; /**< imaginary part of y-coordinate of generator point in group G2 */
extern const BIG_XXX CURVE_Pybaa_ZZZ; /**< real part of y-coordinate of generator point in group G2 */
extern const BIG_XXX CURVE_Pybab_ZZZ; /**< imaginary part of y-coordinate of generator point in group G2 */
extern const BIG_XXX CURVE_Pybba_ZZZ; /**< real part of y-coordinate of generator point in group G2 */
extern const BIG_XXX CURVE_Pybbb_ZZZ; /**< imaginary part of y-coordinate of generator point in group G2 */


extern const BIG_XXX CURVE_Bnx_ZZZ; /**< BN curve x parameter */

extern const BIG_XXX CURVE_Cru_ZZZ; /**< BN curve Cube Root of Unity */

extern const BIG_XXX Fra_YYY; /**< real part of BN curve Frobenius Constant */
extern const BIG_XXX Frb_YYY; /**< imaginary part of BN curve Frobenius Constant */


extern const BIG_XXX CURVE_W_ZZZ[2];	 /**< BN curve constant for GLV decomposition */
extern const BIG_XXX CURVE_SB_ZZZ[2][2]; /**< BN curve constant for GLV decomposition */
extern const BIG_XXX CURVE_WB_ZZZ[4];	 /**< BN curve constant for GS decomposition */
extern const BIG_XXX CURVE_BB_ZZZ[4][4]; /**< BN curve constant for GS decomposition */


/**
	@brief ECP structure - Elliptic Curve Point over base field
*/

typedef struct
{
//    int inf; /**< Infinity Flag - not needed for Edwards representation */

    FP_YYY x; /**< x-coordinate of point */
#if CURVETYPE_ZZZ!=MONTGOMERY
    FP_YYY y; /**< y-coordinate of point. Not needed for Montgomery representation */
#endif
    FP_YYY z;/**< z-coordinate of point */
} ECP_ZZZ;


/* ECP E(Fp) prototypes */
/**	@brief Tests for ECP point equal to infinity
 *
	@param P ECP point to be tested
	@return 1 if infinity, else returns 0
 */
extern int ECP_ZZZ_isinf(ECP_ZZZ *P);
/**	@brief Tests for equality of two ECPs
 *
	@param P ECP instance to be compared
	@param Q ECP instance to be compared
	@return 1 if P=Q, else returns 0
 */
extern int ECP_ZZZ_equals(ECP_ZZZ *P,ECP_ZZZ *Q);
/**	@brief Copy ECP point to another ECP point
 *
	@param P ECP instance, on exit = Q
	@param Q ECP instance to be copied
 */
extern void ECP_ZZZ_copy(ECP_ZZZ *P,ECP_ZZZ *Q);
/**	@brief Negation of an ECP point
 *
	@param P ECP instance, on exit = -P
 */
extern void ECP_ZZZ_neg(ECP_ZZZ *P);
/**	@brief Set ECP to point-at-infinity
 *
	@param P ECP instance to be set to infinity
 */
extern void ECP_ZZZ_inf(ECP_ZZZ *P);
/**	@brief Calculate Right Hand Side of curve equation y^2=f(x)
 *
	Function f(x) depends on form of elliptic curve, Weierstrass, Edwards or Montgomery.
	Used internally.
	@param r BIG n-residue value of f(x)
	@param x BIG n-residue x
 */
extern void ECP_ZZZ_rhs(FP_YYY *r,FP_YYY *x);

#if CURVETYPE_ZZZ==MONTGOMERY
/**	@brief Set ECP to point(x,[y]) given x
 *
	Point P set to infinity if no such point on the curve. Note that y coordinate is not needed.
	@param P ECP instance to be set (x,[y])
	@param x BIG x coordinate of point
	@return 1 if point exists, else 0
 */
extern int ECP_ZZZ_set(ECP_ZZZ *P,BIG_XXX x);
/**	@brief Extract x coordinate of an ECP point P
 *
	@param x BIG on exit = x coordinate of point
	@param P ECP instance (x,[y])
	@return -1 if P is point-at-infinity, else 0
 */
extern int ECP_ZZZ_get(BIG_XXX x,ECP_ZZZ *P);
/**	@brief Adds ECP instance Q to ECP instance P, given difference D=P-Q
 *
	Differential addition of points on a Montgomery curve
	@param P ECP instance, on exit =P+Q
	@param Q ECP instance to be added to P
	@param D Difference between P and Q
 */
extern void ECP_ZZZ_add(ECP_ZZZ *P,ECP_ZZZ *Q,ECP_ZZZ *D);
#else
/**	@brief Set ECP to point(x,y) given x and y
 *
	Point P set to infinity if no such point on the curve.
	@param P ECP instance to be set (x,y)
	@param x BIG x coordinate of point
	@param y BIG y coordinate of point
	@return 1 if point exists, else 0
 */
extern int ECP_ZZZ_set(ECP_ZZZ *P,BIG_XXX x,BIG_XXX y);
/**	@brief Extract x and y coordinates of an ECP point P
 *
	If x=y, returns only x
	@param x BIG on exit = x coordinate of point
	@param y BIG on exit = y coordinate of point (unless x=y)
	@param P ECP instance (x,y)
	@return sign of y, or -1 if P is point-at-infinity
 */
extern int ECP_ZZZ_get(BIG_XXX x,BIG_XXX y,ECP_ZZZ *P);
/**	@brief Adds ECP instance Q to ECP instance P
 *
	@param P ECP instance, on exit =P+Q
	@param Q ECP instance to be added to P
 */
extern void ECP_ZZZ_add(ECP_ZZZ *P,ECP_ZZZ *Q);
/**	@brief Subtracts ECP instance Q from ECP instance P
 *
	@param P ECP instance, on exit =P-Q
	@param Q ECP instance to be subtracted from P
 */
extern void ECP_ZZZ_sub(ECP_ZZZ *P,ECP_ZZZ *Q);
/**	@brief Set ECP to point(x,y) given just x and sign of y
 *
	Point P set to infinity if no such point on the curve. If x is on the curve then y is calculated from the curve equation.
	The correct y value (plus or minus) is selected given its sign s.
	@param P ECP instance to be set (x,[y])
	@param x BIG x coordinate of point
	@param s an integer representing the "sign" of y, in fact its least significant bit.
 */
extern int ECP_ZZZ_setx(ECP_ZZZ *P,BIG_XXX x,int s);

#endif

/**	@brief Multiplies Point by curve co-factor
 *
	@param Q ECP instance
 */
extern void ECP_ZZZ_cfp(ECP_ZZZ *Q);

/**	@brief Maps random BIG to curve point of correct order
 *
	@param Q ECP instance of correct order
	@param w OCTET byte array to be mapped
 */
extern void ECP_ZZZ_mapit(ECP_ZZZ *Q,octet *w);

/**	@brief Converts an ECP point from Projective (x,y,z) coordinates to affine (x,y) coordinates
 *
	@param P ECP instance to be converted to affine form
 */
extern void ECP_ZZZ_affine(ECP_ZZZ *P);
/**	@brief Formats and outputs an ECP point to the console, in projective coordinates
 *
	@param P ECP instance to be printed
 */
extern void ECP_ZZZ_outputxyz(ECP_ZZZ *P);
/**	@brief Formats and outputs an ECP point to the console, converted to affine coordinates
 *
	@param P ECP instance to be printed
 */
extern void ECP_ZZZ_output(ECP_ZZZ * P);

/**	@brief Formats and outputs an ECP point to the console
 *
	@param P ECP instance to be printed
 */
extern void ECP_ZZZ_rawoutput(ECP_ZZZ * P);

/**	@brief Formats and outputs an ECP point to an octet string
	The octet string is normally in the standard form 0x04|x|y
	Here x (and y) are the x and y coordinates in left justified big-endian base 256 form.
	For Montgomery curve it is 0x06|x
	If c is true, only the x coordinate is provided as in 0x2|x if y is even, or 0x3|x if y is odd
	@param c compression required, true or false
	@param S output octet string
	@param P ECP instance to be converted to an octet string
 */
extern void ECP_ZZZ_toOctet(octet *S,ECP_ZZZ *P,bool c);
/**	@brief Creates an ECP point from an octet string
 *
	The octet string is normally in the standard form 0x04|x|y
	Here x (and y) are the x and y coordinates in left justified big-endian base 256 form.
	For Montgomery curve it is 0x06|x
	If in compressed form only the x coordinate is provided as in 0x2|x if y is even, or 0x3|x if y is odd
	@param P ECP instance to be created from the octet string
	@param S input octet string
	return 1 if octet string corresponds to a point on the curve, else 0
 */
extern int ECP_ZZZ_fromOctet(ECP_ZZZ *P,octet *S);
/**	@brief Doubles an ECP instance P
 *
	@param P ECP instance, on exit =2*P
 */
extern void ECP_ZZZ_dbl(ECP_ZZZ *P);
/**	@brief Multiplies an ECP instance P by a small integer, side-channel resistant
 *
	@param P ECP instance, on exit =i*P
	@param i small integer multiplier
	@param b maximum number of bits in multiplier
 */
extern void ECP_ZZZ_pinmul(ECP_ZZZ *P,int i,int b);
/**	@brief Multiplies an ECP instance P by a BIG, side-channel resistant
 *
	Uses Montgomery ladder for Montgomery curves, otherwise fixed sized windows.
	@param P ECP instance, on exit =b*P
	@param b BIG number multiplier

 */
extern void ECP_ZZZ_mul(ECP_ZZZ *P,BIG_XXX b);
/**	@brief Calculates double multiplication P=e*P+f*Q, side-channel resistant
 *
	@param P ECP instance, on exit =e*P+f*Q
	@param Q ECP instance
	@param e BIG number multiplier
	@param f BIG number multiplier
 */
extern void ECP_ZZZ_mul2(ECP_ZZZ *P,ECP_ZZZ *Q,BIG_XXX e,BIG_XXX f);
/**	@brief Get Group Generator from ROM
 *
	@param G ECP instance
 */
extern void ECP_ZZZ_generator(ECP_ZZZ *G);


#endif
