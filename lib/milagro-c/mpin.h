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
 * @file mpin.h
 * @author Mike Scott and Kealan McCusker
 * @date 2nd June 2015
 * @brief M-Pin Header file
 *
 * Allows some user configuration
 * defines structures
 * declares functions
 *
 */

#ifndef MPIN_H
#define MPIN_H

#include "amcl.h"

/* Field size is assumed to be greater than or equal to group size */

#define PGS 32  /**< MPIN Group Size */
#define PFS 32  /**< MPIN Field Size */
#define PAS 16  /**< MPIN Symmetric Key Size */

#define MPIN_OK                     0  /**< Function completed without error */
/*#define MPIN_DOMAIN_ERROR          -11
#define MPIN_INVALID_PUBLIC_KEY    -12
#define MPIN_ERROR                 -13*/
#define MPIN_INVALID_POINT         -14	/**< Point is NOT on the curve */
/*#define MPIN_DOMAIN_NOT_FOUND      -15
#define MPIN_OUT_OF_MEMORY         -16
#define MPIN_DIV_BY_ZERO           -17
#define MPIN_WRONG_ORDER           -18*/
#define MPIN_BAD_PIN               -19  /**< Bad PIN number entered */


/* Configure your PIN here */

#define MAXPIN 10000 /**< max PIN */
#define PBLEN 14   /**< max length of PIN in bits */

#define TIME_SLOT_MINUTES 1440 /**< Time Slot = 1 day */
#define HASH_BYTES 32 /**< Number of bytes output by Hash function */

/* MPIN support functions */

/* MPIN primitives */

/**	@brief Hash an M-Pin Identity to an octet string
 *
	@param ID an octet containing the identity
	@param HID an octet containing the hashed identity
 */
DLL_EXPORT void MPIN_HASH_ID(octet *ID,octet *HID);
/**	@brief Get epoch time as unsigned integer
 *
	@return current epoch time in seconds
 */
DLL_EXPORT unsign32 MPIN_GET_TIME(void);
/**	@brief Generate Y=H(t,O), where t is epoch time, O is an octet, and H(.) is a hash function
 *
	@param t is epoch time in seconds
	@param O is an input octet
	@param Y is the output octet
 */
DLL_EXPORT void MPIN_GET_Y(int t,octet *O,octet *Y);
/**	@brief Extract a PIN number from a client secret
 *
	@param ID is the input client identity
	@param pin is an input PIN number
	@param CS is the client secret from which the PIN is to be extracted
	@return 0 or an error code
 */
DLL_EXPORT int MPIN_EXTRACT_PIN(octet *ID,int pin,octet *CS);
/**	@brief Perform client side of the one-pass version of the M-Pin protocol
 *
	If Time Permits are disabled, set d = 0, and UT is not generated and can be set to NULL.
	If Time Permits are enabled, and PIN error detection is OFF, U is not generated and can be set to NULL.
	If Time Permits are enabled, and PIN error detection is ON, U and UT are both generated.
	@param d is input date, in days since the epoch. Set to 0 if Time permits disabled
	@param ID is the input client identity
	@param R is a pointer to a cryptographically secure random number generator
	@param x an output internally randomly generated if R!=NULL, otherwise must be provided as an input
	@param pin is the input PIN number
	@param T is the input M-Pin token (the client secret with PIN portion removed)
	@param V is output = -(x+y)(CS+TP), where CS is the reconstructed client secret, and TP is the time permit
	@param U is output = x.H(ID)
	@param UT is output = x.(H(ID)+H(d|H(ID)))
	@param TP is the input time permit
	@param MESSAGE is the message to be signed
	@param t is input epoch time in seconds - a timestamp
	@param y is output H(t|U) or H(t|UT) if Time Permits enabled
	@return 0 or an error code
 */
DLL_EXPORT int MPIN_CLIENT(int d,octet *ID,csprng *R,octet *x,int pin,octet *T,octet *V,octet *U,octet *UT,octet *TP, octet* MESSAGE, int t, octet *y);
/**	@brief Perform first pass of the client side of the 3-pass version of the M-Pin protocol
 *
	If Time Permits are disabled, set d = 0, and UT is not generated and can be set to NULL.
	If Time Permits are enabled, and PIN error detection is OFF, U is not generated and can be set to NULL.
	If Time Permits are enabled, and PIN error detection is ON, U and UT are both generated.
	@param d is input date, in days since the epoch. Set to 0 if Time permits disabled
	@param ID is the input client identity
	@param R is a pointer to a cryptographically secure random number generator
	@param x an output internally randomly generated if R!=NULL, otherwise must be provided as an input
	@param pin is the input PIN number
	@param T is the input M-Pin token (the client secret with PIN portion removed)
	@param S is output = CS+TP, where CS=is the reconstructed client secret, and TP is the time permit
	@param U is output = x.H(ID)
	@param UT is output = x.(H(ID)+H(d|H(ID)))
	@param TP is the input time permit
	@return 0 or an error code
 */
DLL_EXPORT int MPIN_CLIENT_1(int d,octet *ID,csprng *R,octet *x,int pin,octet *T,octet *S,octet *U,octet *UT,octet *TP);
/**	@brief Generate a random group element
 *
	@param R is a pointer to a cryptographically secure random number generator
	@param S is the output random octet
	@return 0 or an error code
 */
DLL_EXPORT int MPIN_RANDOM_GENERATE(csprng *R,octet *S);
/**	@brief Perform second pass of the client side of the 3-pass version of the M-Pin protocol
 *
	@param x an input, a locally generated random number
	@param y an input random challenge from the server
	@param V on output = -(x+y).V
	@return 0 or an error code
 */
DLL_EXPORT int MPIN_CLIENT_2(octet *x,octet *y,octet *V);
/**	@brief Perform server side of the one-pass version of the M-Pin protocol
 *
	If Time Permits are disabled, set d = 0, and UT and HTID are not generated and can be set to NULL.
	If Time Permits are enabled, and PIN error detection is OFF, U and HID are not needed and can be set to NULL.
	If Time Permits are enabled, and PIN error detection is ON, U, UT, HID and HTID are all required.
	@param d is input date, in days since the epoch. Set to 0 if Time permits disabled
	@param HID is output H(ID), a hash of the client ID
	@param HTID is output H(ID)+H(d|H(ID))
	@param y is output H(t|U) or H(t|UT) if Time Permits enabled
	@param SS is the input server secret
	@param U is input from the client = x.H(ID)
	@param UT is input from the client= x.(H(ID)+H(d|H(ID)))
	@param V is an input from the client
	@param E is an output to help the Kangaroos to find the PIN error, or NULL if not required
	@param F is an output to help the Kangaroos to find the PIN error, or NULL if not required
	@param ID is the input claimed client identity
	@param MESSAGE is the message to be signed
	@param t is input epoch time in seconds - a timestamp
	@return 0 or an error code
 */
DLL_EXPORT int MPIN_SERVER(int d,octet *HID,octet *HTID,octet *y,octet *SS,octet *U,octet *UT,octet *V,octet *E,octet *F,octet *ID,octet *MESSAGE, int t);
/**	@brief Perform first pass of the server side of the 3-pass version of the M-Pin protocol
 *
	@param d is input date, in days since the epoch. Set to 0 if Time permits disabled
	@param ID is the input claimed client identity
	@param HID is output H(ID), a hash of the client ID
	@param HTID is output H(ID)+H(d|H(ID))
	@return 0 or an error code
 */
DLL_EXPORT void	MPIN_SERVER_1(int d,octet *ID,octet *HID,octet *HTID);
/**	@brief Perform third pass on the server side of the 3-pass version of the M-Pin protocol
 *
	If Time Permits are disabled, set d = 0, and UT and HTID are not needed and can be set to NULL.
	If Time Permits are enabled, and PIN error detection is OFF, U and HID are not needed and can be set to NULL.
	If Time Permits are enabled, and PIN error detection is ON, U, UT, HID and HTID are all required.
	@param d is input date, in days since the epoch. Set to 0 if Time permits disabled
	@param HID is input H(ID), a hash of the client ID
	@param HTID is input H(ID)+H(d|H(ID))
	@param y is the input server's randomly generated challenge
	@param SS is the input server secret
	@param U is input from the client = x.H(ID)
	@param UT is input from the client= x.(H(ID)+H(d|H(ID)))
	@param V is an input from the client
	@param E is an output to help the Kangaroos to find the PIN error, or NULL if not required
	@param F is an output to help the Kangaroos to find the PIN error, or NULL if not required
	@return 0 or an error code
 */
DLL_EXPORT int MPIN_SERVER_2(int d,octet *HID,octet *HTID,octet *y,octet *SS,octet *U,octet *UT,octet *V,octet *E,octet *F);
/**	@brief Add two members from the group G1
 *
	@param Q1 an input member of G1
	@param Q2 an input member of G1
	@param Q an output member of G1 = Q1+Q2
	@return 0 or an error code
 */
DLL_EXPORT int MPIN_RECOMBINE_G1(octet *Q1,octet *Q2,octet *Q);
/**	@brief Add two members from the group G2
 *
	@param P1 an input member of G2
	@param P2 an input member of G2
	@param P an output member of G2 = P1+P2
	@return 0 or an error code
 */
DLL_EXPORT int MPIN_RECOMBINE_G2(octet *P1,octet *P2,octet *P);
/**	@brief Use Kangaroos to find PIN error
 *
	@param E a member of the group GT
	@param F a member of the group GT =  E^e
	@return 0 if Kangaroos failed, or the PIN error e
 */
DLL_EXPORT int MPIN_KANGAROO(octet *E,octet *F);
/**	@brief Encoding of a Time Permit to make it indistinguishable from a random string
 *
	@param R is a pointer to a cryptographically secure random number generator
	@param TP is the input time permit, obfuscated on output
	@return 0 or an error code
 */
DLL_EXPORT int MPIN_ENCODING(csprng *R,octet *TP);
/**	@brief Encoding of an obfuscated Time Permit
 *
	@param TP is the input obfuscated time permit, restored on output
	@return 0 or an error code
 */
DLL_EXPORT int MPIN_DECODING(octet *TP);
/**	@brief Supply today's date as days from the epoch
 *
	@return today's date, as number of days elapsed since the epoch
 */
DLL_EXPORT unsign32 MPIN_today(void);
/**	@brief Initialise a random number generator
 *
	@param R is a pointer to a cryptographically secure random number generator
	@param S is an input truly random seed value
 */
DLL_EXPORT void MPIN_CREATE_CSPRNG(csprng *R,octet *S);
/**	@brief Kill a random number generator
 *
	Deletes all internal state
	@param R is a pointer to a cryptographically secure random number generator
 */
DLL_EXPORT void MPIN_KILL_CSPRNG(csprng *R);
/**	@brief Find a random multiple of a point in G1
 *
	@param R is a pointer to a cryptographically secure random number generator
	@param type determines type of action to be taken
	@param x an output internally randomly generated if R!=NULL, otherwise must be provided as an input
	@param G if type=0 a point in G1, else an octet to be mapped to G1
	@param W the output =x.G or x.M(G), where M(.) is a mapping
	@return 0 or an error code
 */
DLL_EXPORT int MPIN_GET_G1_MULTIPLE(csprng *R,int type,octet *x,octet *G,octet *W);
/**	@brief Create a client secret in G1 from a master secret and the client ID
 *
	@param S is an input master secret
	@param ID is the input client identity
	@param CS is the full client secret = s.H(ID)
	@return 0 or an error code
 */
DLL_EXPORT int MPIN_GET_CLIENT_SECRET(octet *S,octet *ID,octet *CS);
/**	@brief Create a Time Permit in G1 from a master secret and the client ID
 *
	@param d is input date, in days since the epoch.
	@param S is an input master secret
	@param ID is the input client identity
	@param TP is a Time Permit for the given date = s.H(d|H(ID))
	@return 0 or an error code
 */
DLL_EXPORT int MPIN_GET_CLIENT_PERMIT(int d,octet *S,octet *ID,octet *TP);
/**	@brief Create a server secret in G2 from a master secret
 *
	@param S is an input master secret
	@param SS is the server secret = s.Q where Q is a fixed generator of G2
	@return 0 or an error code
 */
DLL_EXPORT int MPIN_GET_SERVER_SECRET(octet *S,octet *SS);
/* DLL_EXPORT int MPIN_TEST_PAIRING(octet *,octet *); */

/* For M-Pin Full */
/**	@brief Precompute values for use by the client side of M-Pin Full
 *
	@param T is the input M-Pin token (the client secret with PIN portion removed)
	@param ID is the input client identity
	@param g1 precomputed output
	@param g2 precomputed output
	@return 0 or an error code
 */
DLL_EXPORT int MPIN_PRECOMPUTE(octet *T,octet *ID,octet *g1,octet *g2);
/**	@brief Calculate Key on Server side for M-Pin Full
 *
	Uses UT internally for the key calculation, unless not available in which case U is used
	@param Z is the input Client-side Diffie-Hellman component
	@param SS is the input server secret
	@param w is an input random number generated by the server
	@param p is an input, hash of the protocol transcript
	@param I is the hashed input client ID = H(ID)
	@param U is input from the client = x.H(ID)
	@param UT is input from the client= x.(H(ID)+H(d|H(ID)))
	@param K is the output calculated shared key
	@return 0 or an error code
 */
DLL_EXPORT int MPIN_SERVER_KEY(octet *Z,octet *SS,octet *w,octet *p,octet *I,octet *U,octet *UT,octet *K);
/**	@brief Calculate Key on Client side for M-Pin Full
 *
	@param g1 precomputed input
	@param g2 precomputed input
	@param pin is the input PIN number
	@param r is an input, a locally generated random number
	@param x is an input, a locally generated random number
	@param p is an input, hash of the protocol transcript
	@param T is the input Server-side Diffie-Hellman component
	@param K is the output calculated shared key
	@return 0 or an error code
 */
DLL_EXPORT int MPIN_CLIENT_KEY(octet *g1,octet *g2,int pin,octet *r,octet *x,octet *p,octet *T,octet *K);

/**	@brief AES-GCM Encryption
 *
	@param K  AES key
	@param IV Initialization vector
	@param H Header
	@param P Plaintext
	@param C Ciphertext
	@param T Checksum
 */
DLL_EXPORT void MPIN_AES_GCM_ENCRYPT(octet *K,octet *IV,octet *H,octet *P,octet *C,octet *T);

/**	@brief AES-GCM Decryption
 *
	@param K  AES key
	@param IV Initialization vector
	@param H Header
	@param P Plaintext
	@param C Ciphertext
	@param T Checksum
 */
DLL_EXPORT void MPIN_AES_GCM_DECRYPT(octet *K,octet *IV,octet *H,octet *C,octet *P,octet *T);

/**	@brief HMAC of message M using key K to create tag of length len in octet tag
 *
	IEEE-1363 MAC1 function. Uses SHA256 internally.
	@param M input message octet
	@param K input encryption key
	@param len is output desired length of HMAC tag
	@param tag is the output HMAC
	@return 0 for bad parameters, else 1
 */
DLL_EXPORT int MPIN_HMAC(octet *M,octet *K,int len,octet *tag);

/**	@brief Password Based Key Derivation Function - generates key K from password, salt and repeat counter
 *
	PBKDF2 Password Based Key Derivation Function. Uses SHA256 internally.
	@param P input password
	@param S input salt
	@param rep Number of times to be iterated.
	@param len is output desired length of key
	@param K is the derived key
 */
DLL_EXPORT void MPIN_PBKDF2(octet *P,octet *S,int rep,int len,octet *K);

/** @brief Hash the session transcript 
	@param I is the hashed input client ID = H(ID)
	@param U is the client output = x.H(ID)
	@param CU is the client output = x.(H(ID)+H(T|H(ID)))
	@param Y is the server challenge
	@param V is the client part response
	@param R is the client part response
	@param W is the server part response
	@param H the output is the hash of all of the above that apply
*/
DLL_EXPORT void MPIN_HASH_ALL(octet *I,octet *U,octet *CU,octet *V,octet *Y,octet *R,octet *W,octet *H);

#endif

