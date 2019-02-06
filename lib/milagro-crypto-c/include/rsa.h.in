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
 * @file rsa_WWW.h
 * @author Mike Scott
 * @brief RSA Header file for implementation of RSA protocol
 *
 * declares functions
 *
 */

#ifndef RSA_WWW_H
#define RSA_WWW_H

#include "ff_WWW.h"
#include "rsa_support.h"

/*** START OF USER CONFIGURABLE SECTION -  ***/

#define HASH_TYPE_RSA_WWW SHA256 /**< Chosen Hash algorithm */

/*** END OF USER CONFIGURABLE SECTION ***/

#define RFS_WWW MODBYTES_XXX*FFLEN_WWW /**< RSA Public Key Size in bytes */


/**
	@brief Integer Factorisation Public Key
*/

typedef struct
{
    sign32 e;     /**< RSA exponent (typically 65537) */
    BIG_XXX n[FFLEN_WWW]; /**< An array of BIGs to store public key */
} rsa_public_key_WWW;

/**
	@brief Integer Factorisation Private Key
*/

typedef struct
{
    BIG_XXX p[FFLEN_WWW/2];  /**< secret prime p  */
    BIG_XXX q[FFLEN_WWW/2];  /**< secret prime q  */
    BIG_XXX dp[FFLEN_WWW/2]; /**< decrypting exponent mod (p-1)  */
    BIG_XXX dq[FFLEN_WWW/2]; /**< decrypting exponent mod (q-1)  */
    BIG_XXX c[FFLEN_WWW/2];  /**< 1/p mod q */
} rsa_private_key_WWW;

/* RSA Auxiliary Functions */

/**	@brief RSA Key Pair Generator
 *
	@param R is a pointer to a cryptographically secure random number generator
	@param e the encryption exponent
	@param PRIV the output RSA private key
	@param PUB the output RSA public key
        @param P Input prime number. Used when R is equal to NULL for testing
        @param Q Inpuy prime number. Used when R is equal to NULL for testing
 */
extern void RSA_WWW_KEY_PAIR(csprng *R,sign32 e,rsa_private_key_WWW* PRIV,rsa_public_key_WWW* PUB,octet *P, octet* Q);

/**	@brief RSA encryption of suitably padded plaintext
 *
	@param PUB the input RSA public key
	@param F is input padded message
	@param G is the output ciphertext
 */
extern void RSA_WWW_ENCRYPT(rsa_public_key_WWW* PUB,octet *F,octet *G);
/**	@brief RSA decryption of ciphertext
 *
	@param PRIV the input RSA private key
	@param G is the input ciphertext
	@param F is output plaintext (requires unpadding)

 */
extern void RSA_WWW_DECRYPT(rsa_private_key_WWW* PRIV,octet *G,octet *F);
/**	@brief Destroy an RSA private Key
 *
	@param PRIV the input RSA private key. Destroyed on output.
 */
extern void RSA_WWW_PRIVATE_KEY_KILL(rsa_private_key_WWW *PRIV);
/**	@brief Populates an RSA public key from an octet string
 *
	Creates RSA public key from big-endian base 256 form.
	@param x FF instance to be created from an octet string
	@param S input octet string
 */
extern void RSA_WWW_fromOctet(BIG_XXX *x,octet *S);



#endif
