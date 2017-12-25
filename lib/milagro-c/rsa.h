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
 * @file rsa.h
 * @author Mike Scott and Kealan McCusker
 * @date 2nd June 2015
 * @brief RSA Header file for implementation of RSA protocol
 *
 * declares functions
 *
 */

#ifndef RSA_H
#define RSA_H

#include "amcl.h"

#define RFS MODBYTES*FFLEN /**< RSA Public Key Size in bytes */

/* RSA Auxiliary Functions */
/**	@brief Initialise a random number generator
 *
	@param R is a pointer to a cryptographically secure random number generator
	@param S is an input truly random seed value
 */
extern void RSA_CREATE_CSPRNG(csprng *R,octet *S);
/**	@brief Kill a random number generator
 *
	Deletes all internal state
	@param R is a pointer to a cryptographically secure random number generator
 */
extern void RSA_KILL_CSPRNG(csprng *R);
/**	@brief RSA Key Pair Generator
 *
	@param R is a pointer to a cryptographically secure random number generator
	@param e the encryption exponent
	@param PRIV the output RSA private key
	@param PUB the output RSA public key
 */
extern void RSA_KEY_PAIR(csprng *R,sign32 e,rsa_private_key* PRIV,rsa_public_key* PUB);
/**	@brief OAEP padding of a message prior to RSA encryption
 *
	@param M is the input message
	@param R is a pointer to a cryptographically secure random number generator
	@param P are input encoding parameter string (could be NULL)
	@param F is the output encoding, ready for RSA encryption
	@return 1 if OK, else 0
 */
extern int RSA_OAEP_ENCODE(octet *M,csprng *R,octet *P,octet *F);
/**	@brief OAEP unpadding of a message after RSA decryption
 *
	Unpadding is done in-place
	@param P are input encoding parameter string (could be NULL)
	@param F is input padded message, unpadded on output
	@return 1 if OK, else 0
 */
extern int RSA_OAEP_DECODE(octet *P,octet *F);
/**	@brief RSA encryption of suitably padded plaintext
 *
	@param PUB the input RSA public key
	@param F is input padded message
	@param G is the output ciphertext
 */
extern void RSA_ENCRYPT(rsa_public_key* PUB,octet *F,octet *G);
/**	@brief RSA decryption of ciphertext
 *
	@param PRIV the input RSA private key
	@param G is the input ciphertext
	@param F is output plaintext (requires unpadding)

 */
extern void RSA_DECRYPT(rsa_private_key* PRIV,octet *G,octet *F);
/**	@brief Destroy an RSA private Key
 *
	@param PRIV the input RSA private key. Destroyed on output.
 */
extern void RSA_PRIVATE_KEY_KILL(rsa_private_key *PRIV);

#endif
