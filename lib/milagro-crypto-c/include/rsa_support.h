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
 * @file rsa_support.h
 * @author Mike Scott
 * @brief RSA Support  Header File
 *
 */

#ifndef RSA_SUPPORT_H
#define RSA_SUPPORT_H

#include "amcl.h"

#define MAX_RSA_BYTES 512 /**< Maximum of 4096 */

/**	@brief PKCS V1.5 padding of a message prior to RSA signature
 *
	@param h is the hash type
	@param M is the input message
	@param W is the output encoding, ready for RSA signature
	@return 1 if OK, else 0
 */
extern int PKCS15(int h,octet *M,octet *W);
/**	@brief OAEP padding of a message prior to RSA encryption
 *
	@param h is the hash type
	@param M is the input message
	@param R is a pointer to a cryptographically secure random number generator
	@param P are input encoding parameter string (could be NULL)
	@param F is the output encoding, ready for RSA encryption
	@return 0 if OK, else 1
 */
extern int	OAEP_ENCODE(int h,octet *M,csprng *R,octet *P,octet *F);
/**	@brief OAEP unpadding of a message after RSA decryption
 *
	Unpadding is done in-place
	@param h is the hash type
	@param P are input encoding parameter string (could be NULL)
	@param F is input padded message, unpadded on output
	@return 0 if OK, else 1
 */
extern int  OAEP_DECODE(int h,octet *P,octet *F);

#endif
