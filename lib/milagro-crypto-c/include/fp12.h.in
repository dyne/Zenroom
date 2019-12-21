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
 * @file fp12_YYY.h
 * @author Mike Scott
 * @brief FP12 Header File
 *
 */

#ifndef FP12_YYY_H
#define FP12_YYY_H

#include "fp4_YYY.h"

/**
	@brief FP12 Structure - towered over three FP4
*/

typedef struct
{
    FP4_YYY a; /**< first part of FP12 */
    FP4_YYY b; /**< second part of FP12 */
    FP4_YYY c; /**< third part of FP12 */
    int type;  /**< Type */
} FP12_YYY;

extern const BIG_XXX Fra_YYY; /**< real part of BN curve Frobenius Constant */
extern const BIG_XXX Frb_YYY; /**< imaginary part of BN curve Frobenius Constant */

/* FP12 prototypes */
/**	@brief Tests for FP12 equal to zero
 *
	@param x FP12 number to be tested
	@return 1 if zero, else returns 0
 */
extern int FP12_YYY_iszilch(FP12_YYY *x);
/**	@brief Tests for FP12 equal to unity
 *
	@param x FP12 number to be tested
	@return 1 if unity, else returns 0
 */
extern int FP12_YYY_isunity(FP12_YYY *x);
/**	@brief Copy FP12 to another FP12
 *
	@param x FP12 instance, on exit = y
	@param y FP12 instance to be copied
 */
extern void FP12_YYY_copy(FP12_YYY *x,FP12_YYY *y);
/**	@brief Set FP12 to unity
 *
	@param x FP12 instance to be set to one
 */
extern void FP12_YYY_one(FP12_YYY *x);

/**	@brief Set FP12 to zero
 *
	@param x FP12 instance to be set to zero
 */
extern void FP12_YYY_zero(FP12_YYY *x);

/**	@brief Tests for equality of two FP12s
 *
	@param x FP12 instance to be compared
	@param y FP12 instance to be compared
	@return 1 if x=y, else returns 0
 */
extern int FP12_YYY_equals(FP12_YYY *x,FP12_YYY *y);
/**	@brief Conjugation of FP12
 *
	If y=(a,b,c) (where a,b,c are its three FP4 components) on exit x=(conj(a),-conj(b),conj(c))
	@param x FP12 instance, on exit = conj(y)
	@param y FP12 instance
 */
extern void FP12_YYY_conj(FP12_YYY *x,FP12_YYY *y);
/**	@brief Initialise FP12 from single FP4
 *
	Sets first FP4 component of an FP12, other components set to zero
	@param x FP12 instance to be initialised
	@param a FP4 to form first part of FP4
 */
extern void FP12_YYY_from_FP4(FP12_YYY *x,FP4_YYY *a);
/**	@brief Initialise FP12 from three FP4s
 *
	@param x FP12 instance to be initialised
	@param a FP4 to form first part of FP12
	@param b FP4 to form second part of FP12
	@param c FP4 to form third part of FP12
 */
extern void FP12_YYY_from_FP4s(FP12_YYY *x,FP4_YYY *a,FP4_YYY* b,FP4_YYY *c);
/**	@brief Fast Squaring of an FP12 in "unitary" form
 *
	@param x FP12 instance, on exit = y^2
	@param y FP4 instance, must be unitary
 */
extern void FP12_YYY_usqr(FP12_YYY *x,FP12_YYY *y);
/**	@brief Squaring an FP12
 *
	@param x FP12 instance, on exit = y^2
	@param y FP12 instance
 */
extern void FP12_YYY_sqr(FP12_YYY *x,FP12_YYY *y);

/**	@brief Fast multiplication of two sparse FP12s that arises from ATE pairing line functions
 *
	@param x FP12 instance, on exit = x*y
	@param y FP12 instance, of special form
 */
extern void FP12_YYY_smul(FP12_YYY *x,FP12_YYY *y);

/**	@brief Fast multiplication of what may be sparse multiplicands
 *
	@param x FP12 instance, on exit = x*y
	@param y FP12 instance, of special form
 */
extern void FP12_YYY_ssmul(FP12_YYY *x,FP12_YYY *y);


/**	@brief Full unconditional Multiplication of two FP12s
 *
	@param x FP12 instance, on exit = x*y
	@param y FP12 instance, the multiplier
 */
extern void FP12_YYY_mul(FP12_YYY *x,FP12_YYY *y);
/**	@brief Inverting an FP12
 *
	@param x FP12 instance, on exit = 1/y
	@param y FP12 instance
 */
extern void FP12_YYY_inv(FP12_YYY *x,FP12_YYY *y);
/**	@brief Raises an FP12 to the power of a BIG
 *
	@param r FP12 instance, on exit = y^b
	@param x FP12 instance
	@param b BIG number
 */
extern void FP12_YYY_pow(FP12_YYY *r,FP12_YYY *x,BIG_XXX b);
/**	@brief Raises an FP12 instance x to a small integer power, side-channel resistant
 *
	@param x FP12 instance, on exit = x^i
	@param i small integer exponent
	@param b maximum number of bits in exponent
 */
extern void FP12_YYY_pinpow(FP12_YYY *x,int i,int b);

/**	@brief Raises an FP12 instance x to a BIG power, compressed to FP4
 *
	@param c FP4 instance, on exit = x^(e mod r) as FP4
	@param x FP12 input
	@param e BIG exponent
	@param r BIG group order
 */
extern void FP12_YYY_compow(FP4_YYY *c,FP12_YYY *x,BIG_XXX e,BIG_XXX r);

/**	@brief Calculate x[0]^b[0].x[1]^b[1].x[2]^b[2].x[3]^b[3], side-channel resistant
 *
	@param r FP12 instance, on exit = x[0]^b[0].x[1]^b[1].x[2]^b[2].x[3]^b[3]
	@param x FP12 array with 4 FP12s
	@param b BIG array of 4 exponents
 */
extern void FP12_YYY_pow4(FP12_YYY *r,FP12_YYY *x,BIG_XXX *b);
/**	@brief Raises an FP12 to the power of the internal modulus p, using the Frobenius
 *
	@param x FP12 instance, on exit = x^p
	@param f FP2 precalculated Frobenius constant
 */
extern void FP12_YYY_frob(FP12_YYY *x,FP2_YYY *f);
/**	@brief Reduces all components of possibly unreduced FP12 mod Modulus
 *
	@param x FP12 instance, on exit reduced mod Modulus
 */
extern void FP12_YYY_reduce(FP12_YYY *x);
/**	@brief Normalises the components of an FP12
 *
	@param x FP12 instance to be normalised
 */
extern void FP12_YYY_norm(FP12_YYY *x);
/**	@brief Formats and outputs an FP12 to the console
 *
	@param x FP12 instance to be printed
 */
extern void FP12_YYY_output(FP12_YYY *x);
/**	@brief Formats and outputs an FP12 instance to an octet string
 *
	Serializes the components of an FP12 to big-endian base 256 form.
	@param S output octet string
	@param x FP12 instance to be converted to an octet string
 */
extern void FP12_YYY_toOctet(octet *S,FP12_YYY *x);
/**	@brief Creates an FP12 instance from an octet string
 *
	De-serializes the components of an FP12 to create an FP12 from big-endian base 256 components.
	@param x FP12 instance to be created from an octet string
	@param S input octet string

 */
extern void FP12_YYY_fromOctet(FP12_YYY *x,octet *S);
/**	@brief Calculate the trace of an FP12
 *
	@param t FP4 trace of x, on exit = tr(x)
	@param x FP12 instance

 */
extern void FP12_YYY_trace(FP4_YYY *t,FP12_YYY *x);

/**	@brief Conditional copy of FP12 number
 *
	Conditionally copies second parameter to the first (without branching)
	@param x FP12 instance, set to y if s!=0
	@param y another FP12 instance
	@param s copy only takes place if not equal to 0
 */
extern void FP12_YYY_cmove(FP12_YYY *x,FP12_YYY *y,int s);


#endif
