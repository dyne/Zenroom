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
 * @file pair_ZZZ.h
 * @author Mike Scott
 * @brief PAIR Header File
 *
 */

#ifndef PAIR_ZZZ_H
#define PAIR_ZZZ_H

#include "fp12_YYY.h"
#include "ecp2_ZZZ.h"
#include "ecp_ZZZ.h"

/* Pairing constants */

extern const BIG_XXX CURVE_Bnx_ZZZ; /**< BN curve x parameter */
extern const BIG_XXX CURVE_Cru_ZZZ; /**< BN curve Cube Root of Unity */

extern const BIG_XXX CURVE_W_ZZZ[2];	 /**< BN curve constant for GLV decomposition */
extern const BIG_XXX CURVE_SB_ZZZ[2][2]; /**< BN curve constant for GLV decomposition */
extern const BIG_XXX CURVE_WB_ZZZ[4];	 /**< BN curve constant for GS decomposition */
extern const BIG_XXX CURVE_BB_ZZZ[4][4]; /**< BN curve constant for GS decomposition */

/* Pairing function prototypes */

/**	@brief Precompute line functions for n-pairing
 *
	@param r array of precomputed FP12 products of line functions
	@param PV ECP2 instance, an element of G2
	@param QV ECP instance, an element of G1

 */
extern void PAIR_ZZZ_another(FP12_YYY r[],ECP2_ZZZ* PV,ECP_ZZZ* QV);

/**	@brief Calculate Miller loop for Optimal ATE pairing e(P,Q)
 *
	@param r FP12 result of the pairing calculation e(P,Q)
	@param P ECP2 instance, an element of G2
	@param Q ECP instance, an element of G1

 */
extern void PAIR_ZZZ_ate(FP12_YYY *r,ECP2_ZZZ *P,ECP_ZZZ *Q);
/**	@brief Calculate Miller loop for Optimal ATE double-pairing e(P,Q).e(R,S)
 *
	Faster than calculating two separate pairings
	@param r FP12 result of the pairing calculation e(P,Q).e(R,S), an element of GT
	@param P ECP2 instance, an element of G2
	@param Q ECP instance, an element of G1
	@param R ECP2 instance, an element of G2
	@param S ECP instance, an element of G1
 */
extern void PAIR_ZZZ_double_ate(FP12_YYY *r,ECP2_ZZZ *P,ECP_ZZZ *Q,ECP2_ZZZ *R,ECP_ZZZ *S);
/**	@brief Final exponentiation of pairing, converts output of Miller loop to element in GT
 *
	Here p is the internal modulus, and r is the group order
	@param x FP12, on exit = x^((p^12-1)/r)
 */
extern void PAIR_ZZZ_fexp(FP12_YYY *x);
/**	@brief Fast point multiplication of a member of the group G1 by a BIG number
 *
	May exploit endomorphism for speed.
	@param Q ECP member of G1.
	@param b BIG multiplier

 */
extern void PAIR_ZZZ_G1mul(ECP_ZZZ *Q,BIG_XXX b);
/**	@brief Fast point multiplication of a member of the group G2 by a BIG number
 *
	May exploit endomorphism for speed.
	@param P ECP2 member of G1.
	@param b BIG multiplier

 */
extern void PAIR_ZZZ_G2mul(ECP2_ZZZ *P,BIG_XXX b);
/**	@brief Fast raising of a member of GT to a BIG power
 *
	May exploit endomorphism for speed.
	@param x FP12 member of GT.
	@param b BIG exponent

 */
extern void PAIR_ZZZ_GTpow(FP12_YYY *x,BIG_XXX b);
/**	@brief Tests FP12 for membership of GT
 *
	@param x FP12 instance
	@return 1 if x is in GT, else return 0

 */
extern int PAIR_ZZZ_GTmember(FP12_YYY *x);

/**	@brief Prepare Ate parameter
 *
	@param n BIG parameter
	@param n3 BIG paramter = 3*n
	@return number of nits in n3

 */
extern int PAIR_ZZZ_nbits(BIG_XXX n3,BIG_XXX n);

/**	@brief Initialise structure for multi-pairing
 *
	@param r FP12 array, to be initialised to 1

 */
extern void PAIR_ZZZ_initmp(FP12_YYY r[]);


/**	@brief Miller loop
 *
 	@param res FP12 result
	@param r FP12 precomputed array of accumulated line functions

 */
extern void PAIR_ZZZ_miller(FP12_YYY *res,FP12_YYY r[]);

#endif
