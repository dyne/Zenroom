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
 * @file ecdh_support.h
 * @author Mike Scott
 * @brief ECDH Support Header File
 *
 */

#ifndef ECC_SUPPORT_H
#define ECC_SUPPORT_H

#include "amcl.h"

/* Auxiliary Functions */

/** @brief general purpose hash function w=hash(p|n|x|y)
 *
	@param sha is the hash type
	@param p first octect involved in the hash
	@param n integer involved in the hash
	@param x second octect involved in the h ash
	@param w output
	@param pad padding
 */
extern void ehashit(int sha,octet *p,int n,octet *x,octet *w,int pad);

/**	@brief hash an octet into another octet
 *
 	@param h is the hash type
	@param I input octet
	@param O output octet - H(I)
 */
extern void HASH(int h,octet *I,octet *O);
/**	@brief HMAC of message M using key K to create tag of length len in octet tag
 *
	IEEE-1363 MAC1 function. Uses SHA256 internally.
	@param h is the hash type
	@param M input message octet
	@param K input encryption key
	@param len is output desired length of HMAC tag
	@param tag is the output HMAC
	@return 0 for bad parameters, else 1
 */
extern int HMAC(int h,octet *M,octet *K,int len,octet *tag);

/*extern void KDF1(octet *,int,octet *);*/

/**	@brief Key Derivation Function - generates key K from inputs Z and P
 *
	IEEE-1363 KDF2 Key Derivation Function. Uses SHA256 internally.
	@param h is the hash type
	@param Z input octet
	@param P input key derivation parameters - can be NULL
	@param len is output desired length of key
	@param K is the derived key
 */
extern void KDF2(int h,octet *Z,octet *P,int len,octet *K);
/**	@brief Password Based Key Derivation Function - generates key K from password, salt and repeat counter
 *
	PBKDF2 Password Based Key Derivation Function. Uses SHA256 internally.
	@param h is the hash type
	@param P input password
	@param S input salt
	@param rep Number of times to be iterated.
	@param len is output desired length
	@param K is the derived key
 */
extern void PBKDF2(int h,octet *P,octet *S,int rep,int len,octet *K);
/**	@brief AES encrypts a plaintext to a ciphtertext
 *
	IEEE-1363 AES_CBC_IV0_ENCRYPT function. Encrypts in CBC mode with a zero IV, padding as necessary to create a full final block.
	@param K AES key
	@param P input plaintext octet
	@param C output ciphertext octet
 */
extern void AES_CBC_IV0_ENCRYPT(octet *K,octet *P,octet *C);
/**	@brief AES encrypts a plaintext to a ciphtertext
 *
	IEEE-1363 AES_CBC_IV0_DECRYPT function. Decrypts in CBC mode with a zero IV.
	@param K AES key
	@param C input ciphertext octet
	@param P output plaintext octet
	@return 0 if bad input, else 1
 */
extern int AES_CBC_IV0_DECRYPT(octet *K,octet *C,octet *P);

/* ECDH primitives - support functions */
/**	@brief Generate an ECC public/private key pair
 *
	@param R is a pointer to a cryptographically secure random number generator
	@param s the private key, an output internally randomly generated if R!=NULL, otherwise must be provided as an input
	@param W the output public key, which is s.G, where G is a fixed generator
	@return 0 or an error code
 */

#endif
