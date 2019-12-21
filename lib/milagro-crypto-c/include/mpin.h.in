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
 * @file mpin_ZZZ.h
 * @author Mike Scott
 * @brief M-Pin Header file
 *
 *
 */

#ifndef MPIN_ZZZ_H
#define MPIN_ZZZ_H

#include "pair_ZZZ.h"
#include "pbc_support.h"

/* Field size is assumed to be greater than or equal to group size */

#define PGS_ZZZ MODBYTES_XXX  /**< MPIN Group Size */
#define PFS_ZZZ MODBYTES_XXX  /**< MPIN Field Size */
//#define PAS_ZZZ 16            /**< MPIN Symmetric Key Size */

#define MPIN_OK             0   /**< Function completed without error */
#define MPIN_INVALID_POINT  -14	/**< Point is NOT on the curve */
#define MPIN_BAD_PIN        -19 /**< Bad PIN number entered */

#define MPIN_PAS 16          /**< MPIN Symmetric Key Size */
#define MAXPIN 10000         /**< max PIN */
#define PBLEN 14             /**< max length of PIN in bits */

//#define HASH_TYPE_MPIN_ZZZ SHA256   /**< Choose Hash function */

#define MESSAGE_SIZE 256        /**< Signature message size  */
#define M_SIZE_ZZZ (MESSAGE_SIZE+2*PFS_ZZZ+1)   /**< Signature message size and G1 size */

/* MPIN support functions */

/* MPIN primitives */


/**	@brief Generate Y=H(s,O), where s is epoch time, O is an octet, and H(.) is a hash function
 *
  	@param h is the hash type
	@param t is epoch time in seconds
	@param O is an input octet
	@param Y is the output octet
*/
void MPIN_ZZZ_GET_Y(int h,int t,octet *O,octet *Y);

/**	@brief Extract a PIN number from a client secret
 *
  	@param h is the hash type
	@param ID is the input client identity
	@param factor is an input factor
	@param facbits is the number of bits in the factor
	@param CS is the client secret from which the factor is to be extracted
	@return 0 or an error code
 */
int MPIN_ZZZ_EXTRACT_FACTOR(int h,octet *ID,int factor,int facbits,octet *CS);

/**	@brief Extract a PIN number from a client secret
 *
  	@param h is the hash type
	@param ID is the input client identity
	@param factor is an input factor
	@param facbits is the number of bits in the factor
	@param CS is the client secret to which the factor is to be added
	@return 0 or an error code
 */
int MPIN_ZZZ_RESTORE_FACTOR(int h,octet *ID,int factor,int facbits,octet *CS);


/**	@brief Extract a PIN number from a client secret
 *
  	@param h is the hash type
	@param ID is the input client identity
	@param pin is an input PIN number
	@param CS is the client secret from which the PIN is to be extracted
	@return 0 or an error code
 */
int MPIN_ZZZ_EXTRACT_PIN(int h,octet *ID,int pin,octet *CS);



/**	@brief Perform client side of the one-pass version of the M-Pin protocol
 *
	If Time Permits are disabled, set d = 0, and UT is not generated and can be set to NULL.
	If Time Permits are enabled, and PIN error detection is OFF, U is not generated and can be set to NULL.
	If Time Permits are enabled, and PIN error detection is ON, U and UT are both generated.
 	@param h is the hash type
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
int MPIN_ZZZ_CLIENT(int h,int d,octet *ID,csprng *R,octet *x,int pin,octet *T,octet *V,octet *U,octet *UT,octet *TP, octet* MESSAGE, int t, octet *y);
/**	@brief Perform first pass of the client side of the 3-pass version of the M-Pin protocol
 *
	If Time Permits are disabled, set d = 0, and UT is not generated and can be set to NULL.
	If Time Permits are enabled, and PIN error detection is OFF, U is not generated and can be set to NULL.
	If Time Permits are enabled, and PIN error detection is ON, U and UT are both generated.
 	@param h is the hash type
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
int MPIN_ZZZ_CLIENT_1(int h,int d,octet *ID,csprng *R,octet *x,int pin,octet *T,octet *S,octet *U,octet *UT,octet *TP);
/**	@brief Generate a random group element
 *
	@param R is a pointer to a cryptographically secure random number generator
	@param S is the output random octet
	@return 0 or an error code
 */
int MPIN_ZZZ_RANDOM_GENERATE(csprng *R,octet *S);
/**	@brief Perform second pass of the client side of the 3-pass version of the M-Pin protocol
 *
	@param x an input, a locally generated random number
	@param y an input random challenge from the server
	@param V on output = -(x+y).V
	@return 0 or an error code
 */
int MPIN_ZZZ_CLIENT_2(octet *x,octet *y,octet *V);
/**	@brief Perform server side of the one-pass version of the M-Pin protocol
 *
	If Time Permits are disabled, set d = 0, and UT and HTID are not generated and can be set to NULL.
	If Time Permits are enabled, and PIN error detection is OFF, U and HID are not needed and can be set to NULL.
	If Time Permits are enabled, and PIN error detection is ON, U, UT, HID and HTID are all required.
 	@param h is the hash type
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
	@param Pa is input from the client z.Q or NULL if the key-escrow less scheme is not used
	@return 0 or an error code
 */
int MPIN_ZZZ_SERVER(int h,int d,octet *HID,octet *HTID,octet *y,octet *SS,octet *U,octet *UT,octet *V,octet *E,octet *F,octet *ID,octet *MESSAGE, int t, octet *Pa);
/**	@brief Perform first pass of the server side of the 3-pass version of the M-Pin protocol
 *
 	@param h is the hash type
	@param d is input date, in days since the epoch. Set to 0 if Time permits disabled
	@param ID is the input claimed client identity
	@param HID is output H(ID), a hash of the client ID
	@param HTID is output H(ID)+H(d|H(ID))
	@return 0 or an error code
 */
void MPIN_ZZZ_SERVER_1(int h,int d,octet *ID,octet *HID,octet *HTID);
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
	@param Pa is the input public key from the client, z.Q or NULL if the client uses regular mpin
	@return 0 or an error code
 */
int MPIN_ZZZ_SERVER_2(int d,octet *HID,octet *HTID,octet *y,octet *SS,octet *U,octet *UT,octet *V,octet *E,octet *F,octet *Pa);
/**	@brief Add two members from the group G1
 *
	@param Q1 an input member of G1
	@param Q2 an input member of G1
	@param Q an output member of G1 = Q1+Q2
	@return 0 or an error code
 */
int MPIN_ZZZ_RECOMBINE_G1(octet *Q1,octet *Q2,octet *Q);
/**	@brief Add two members from the group G2
 *
	@param P1 an input member of G2
	@param P2 an input member of G2
	@param P an output member of G2 = P1+P2
	@return 0 or an error code
 */
int MPIN_ZZZ_RECOMBINE_G2(octet *P1,octet *P2,octet *P);
/**	@brief Use Kangaroos to find PIN error
 *
	@param E a member of the group GT
	@param F a member of the group GT =  E^e
	@return 0 if Kangaroos failed, or the PIN error e
 */
int MPIN_ZZZ_KANGAROO(octet *E,octet *F);
/**	@brief Encoding of a Time Permit to make it indistinguishable from a random string
 *
	@param R is a pointer to a cryptographically secure random number generator
	@param TP is the input time permit, obfuscated on output
	@return 0 or an error code
 */
int MPIN_ZZZ_ENCODING(csprng *R,octet *TP);
/**	@brief Encoding of an obfuscated Time Permit
 *
	@param TP is the input obfuscated time permit, restored on output
	@return 0 or an error code
 */
int MPIN_ZZZ_DECODING(octet *TP);

/**	@brief Find a random multiple of a point in G1
 *
	@param R is a pointer to a cryptographically secure random number generator
	@param type determines type of action to be taken
	@param x an output internally randomly generated if R!=NULL, otherwise must be provided as an input
	@param G if type=0 a point in G1, else an octet to be mapped to G1
	@param W the output =x.G or x.M(G), where M(.) is a mapping
	@return 0 or an error code
 */
int MPIN_ZZZ_GET_G1_MULTIPLE(csprng *R,int type,octet *x,octet *G,octet *W);
/**	@brief Find a random multiple of a point in G1
 *
	@param R is a pointer to a cryptographically secure random number generator
	@param type determines type of action to betaken
	@param x an output internally randomly generated if R!=NULL, otherwise must be provided as an input
	@param G a point in G2
	@param W the output =x.G or (1/x).G
	@return 0 or an error code
 */
int MPIN_ZZZ_GET_G2_MULTIPLE(csprng *R,int type,octet *x,octet *G,octet *W);

/**	@brief Create a client secret in G1 from a master secret and the client ID
 *
	@param S is an input master secret
	@param ID is the input client identity
	@param CS is the full client secret = s.H(ID)
	@return 0 or an error code
 */
int MPIN_ZZZ_GET_CLIENT_SECRET(octet *S,octet *ID,octet *CS);
/**	@brief Create a Time Permit in G1 from a master secret and the client ID
 *
  	@param h is the hash type
	@param d is input date, in days since the epoch.
	@param S is an input master secret
	@param ID is the input client identity
	@param TP is a Time Permit for the given date = s.H(d|H(ID))
	@return 0 or an error code
 */
int MPIN_ZZZ_GET_CLIENT_PERMIT(int h,int d,octet *S,octet *ID,octet *TP);
/**	@brief Create a server secret in G2 from a master secret
 *
	@param S is an input master secret
	@param SS is the server secret = s.Q where Q is a fixed generator of G2
	@return 0 or an error code
 */
int MPIN_ZZZ_GET_SERVER_SECRET(octet *S,octet *SS);
/* int MPIN_TEST_PAIRING(octet *,octet *); */

/* For M-Pin Full */
/**	@brief Precompute values for use by the client side of M-Pin Full
 *
	@param T is the input M-Pin token (the client secret with PIN portion removed)
	@param ID is the input client identity
	@param CP is Public Key (or NULL)
	@param g1 precomputed output
	@param g2 precomputed output
	@return 0 or an error code
 */
int MPIN_ZZZ_PRECOMPUTE(octet *T,octet *ID,octet *CP,octet *g1,octet *g2);
/**	@brief Calculate Key on Server side for M-Pin Full
 *
	Uses UT internally for the key calculation, unless not available in which case U is used
 	@param h is the hash type
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
int MPIN_ZZZ_SERVER_KEY(int h,octet *Z,octet *SS,octet *w,octet *p,octet *I,octet *U,octet *UT,octet *K);
/**	@brief Calculate Key on Client side for M-Pin Full
 *
  	@param h is the hash type
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
int MPIN_ZZZ_CLIENT_KEY(int h,octet *g1,octet *g2,int pin,octet *r,octet *x,octet *p,octet *T,octet *K);

/** @brief Generates a random public key for the client z.Q
 *
	@param R is a pointer to a cryptographically secure random number generator
	@param Z an output internally randomly generated if R!=NULL, otherwise it must be provided as an input
	@param Pa the output public key for the client
 */
int MPIN_ZZZ_GET_DVS_KEYPAIR(csprng *R,octet *Z,octet *Pa);

#endif

