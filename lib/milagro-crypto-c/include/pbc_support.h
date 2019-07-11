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
 * @file pbc_support.h
 * @author Mike Scott
 * @brief Auxiliary functions for Pairing-based protocols
 *
 *
 */

#ifndef PBC_SUPPORT_H
#define PBC_SUPPORT_H

#include "amcl.h"

#define TIME_SLOT_MINUTES 1440  /**< Time Slot = 1 day */

/** @brief general purpose hash function w=hash(n|x)
 *
	@param sha is the hash type
	@param n integer involved in the hash
	@param x octect involved in the h ash
	@param w output
 */
extern void mhashit(int sha,int n,octet *x,octet *w);

void HASH_ALL(int h,octet *I,octet *U,octet *CU,octet *Y,octet *V,octet *R,octet *W,octet *H);
/**	@brief Hash an M-Pin Identity to an octet string
 *
 	@param h is the hash type
	@param ID an octet containing the identity
	@param HID an octet containing the hashed identity
 */
void HASH_ID(int h,octet *ID,octet *HID);
/**	@brief Get epoch time as unsigned integer
 *
	@return current epoch time in seconds
 */
unsign32 GET_TIME(void);
/**	@brief AES-GCM Encryption
 *
	@param K  AES key
	@param IV Initialization vector
	@param H Header
	@param P Plaintext
	@param C Ciphertext
	@param T Checksum
 */
void AES_GCM_ENCRYPT(octet *K,octet *IV,octet *H,octet *P,octet *C,octet *T);

/**	@brief AES-GCM Decryption
 *
	@param K  AES key
	@param IV Initialization vector
	@param H Header
	@param P Plaintext
	@param C Ciphertext
	@param T Checksum
 */
void AES_GCM_DECRYPT(octet *K,octet *IV,octet *H,octet *C,octet *P,octet *T);


#endif
