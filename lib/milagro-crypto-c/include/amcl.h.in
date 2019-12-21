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


#ifndef AMCL_H
#define AMCL_H

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <inttypes.h>
#include "arch.h"

#ifdef CMAKE
#define AMCL_VERSION_MAJOR @AMCL_VERSION_MAJOR@ /**< Major version of the library */
#define AMCL_VERSION_MINOR @AMCL_VERSION_MINOR@ /**< Minor version of the library */
#define AMCL_VERSION_PATCH @AMCL_VERSION_PATCH@ /**< Patch version of the library */
#define OS "@OS@"                               /**< Build OS */
#endif

/* modulus types */

#define NOT_SPECIAL 0	       /**< Modulus of no exploitable form */
#define PSEUDO_MERSENNE 1      /**< Pseudo-mersenne modulus of form $2^n-c$  */
#define MONTGOMERY_FRIENDLY 3  /**< Montgomery Friendly modulus of form $2^a(2^b-c)-1$  */
#define GENERALISED_MERSENNE 2 /**< Generalised-mersenne modulus of form $2^n-2^m-1$, GOLDILOCKS only */


/* Curve types */

#define WEIERSTRASS 0 /**< Short Weierstrass form curve  */
#define EDWARDS 1     /**< Edwards or Twisted Edwards curve  */
#define MONTGOMERY 2  /**< Montgomery form curve  */

/* Pairing-Friendly types */

#define NOT 0
#define BN 1
#define BLS 2

#define D_TYPE 0
#define M_TYPE 1

#define AMCL_FP_ZERO 0
#define AMCL_FP_UNITY 1
#define AMCL_FP_SPARSER 2
#define AMCL_FP_SPARSE 3
#define AMCL_FP_DENSE 4


/**
 * @brief SHA256 hash function instance */
typedef struct
{
    unsign32 length[2]; /**< 64-bit input length */
    unsign32 h[8];      /**< Internal state */
    unsign32 w[80];	/**< Internal state */
    int hlen;		/**< Hash length in bytes */
} hash256;

/**
 * @brief SHA384-512 hash function instance */
typedef struct
{
    unsign64 length[2]; /**< 64-bit input length */
    unsign64 h[8];      /**< Internal state */
    unsign64 w[80];	/**< Internal state */
    int hlen;           /**< Hash length in bytes */
} hash512;

/**
 * @brief SHA384 hash function instance */
typedef hash512 hash384;

/**
 * @brief SHA3 hash function instance */
typedef struct
{
    unsign64 length;   /**< 64-bit input length */
    unsign64 S[5][5];  /**< Internal state */
    int rate;          /**< TODO */
    int len;           /**< Hash length in bytes */
} sha3;

#define SHA256 32 /**< SHA-256 hashing */
#define SHA384 48 /**< SHA-384 hashing */
#define SHA512 64 /**< SHA-512 hashing */

#define SHA3_HASH224 28 /**< SHA3 224 bit hash */
#define SHA3_HASH256 32 /**< SHA3 256 bit hash */
#define SHA3_HASH384 48 /**< SHA3 384 bit hash */
#define SHA3_HASH512 64 /**< SHA3 512 bit hash */

#define SHAKE128 16 /**< SHAKE128   hash */
#define SHAKE256 32 /**< SHAKE256 hash */


/* NewHope parameters */

//q= 12289

#define RLWE_PRIME 0x3001	// q in Hex
#define RLWE_LGN 10			// Degree n=2^LGN
#define RLWE_ND 0xF7002FFF	// 1/(R-q) mod R
#define RLWE_ONE 0x2AC8		// R mod q
#define RLWE_R2MODP 0x1620	// R^2 mod q

/* Symmetric Encryption AES structure */

#define ECB   0  /**< Electronic Code Book */
#define CBC   1  /**< Cipher Block Chaining */
#define CFB1  2  /**< Cipher Feedback - 1 byte */
#define CFB2  3  /**< Cipher Feedback - 2 bytes */
#define CFB4  5  /**< Cipher Feedback - 4 bytes */
#define OFB1  14 /**< Output Feedback - 1 byte */
#define OFB2  15 /**< Output Feedback - 2 bytes */
#define OFB4  17 /**< Output Feedback - 4 bytes */
#define OFB8  21 /**< Output Feedback - 8 bytes */
#define OFB16 29 /**< Output Feedback - 16 bytes */
#define CTR1  30 /**< Counter Mode - 1 byte */
#define CTR2  31 /**< Counter Mode - 2 bytes */
#define CTR4  33 /**< Counter Mode - 4 bytes */
#define CTR8  37 /**< Counter Mode - 8 bytes */
#define CTR16 45 /**< Counter Mode - 16 bytes */

#define uchar unsigned char  /**<  Unsigned char */

/**
	@brief AES instance
*/


typedef struct
{
    int Nk;            /**< AES Key Length */
    int Nr;            /**< AES Number of rounds */
    int mode;          /**< AES mode of operation */
    unsign32 fkey[60]; /**< subkeys for encrypton */
    unsign32 rkey[60]; /**< subkeys for decrypton */
    char f[16];        /**< buffer for chaining vector */
} amcl_aes;

/* AES-GCM suppport.  */

#define GCM_ACCEPTING_HEADER 0   /**< GCM status */
#define GCM_ACCEPTING_CIPHER 1   /**< GCM status */
#define GCM_NOT_ACCEPTING_MORE 2 /**< GCM status */
#define GCM_FINISHED 3           /**< GCM status */
#define GCM_ENCRYPTING 0         /**< GCM mode */
#define GCM_DECRYPTING 1         /**< GCM mode */


/**
	@brief GCM mode instance, using AES internally
*/

typedef struct
{
    unsign32 table[128][4]; /**< 2k byte table */
    uchar stateX[16];	    /**< GCM Internal State */
    uchar Y_0[16];	    /**< GCM Internal State */
    unsign32 lenA[2];	    /**< GCM 64-bit length of header */
    unsign32 lenC[2];	    /**< GCM 64-bit length of ciphertext */
    int status;		    /**< GCM Status */
    amcl_aes a;		    /**< Internal Instance of AMCL_AES cipher */
} gcm;

/* Marsaglia & Zaman Random number generator constants */

#define NK   21 /**< PRNG constant */
#define NJ   6  /**< PRNG constant */
#define NV   8  /**< PRNG constant */


/**
	@brief Cryptographically secure pseudo-random number generator instance
*/

typedef struct
{
    unsign32 ira[NK]; /**< random number array   */
    int      rndptr;  /**< pointer into array */
    unsign32 borrow;  /**<  borrow as a result of subtraction */
    int pool_ptr;     /**< pointer into random pool */
    char pool[32];    /**< random pool */
} csprng;


/**
	@brief Portable representation of a big positive number
*/

typedef struct
{
    int len;   /**< length in bytes  */
    int max;   /**< max length allowed - enforce truncation  */
    char *val; /**< byte array  */
} octet;


/* Octet string handlers */
/**	@brief Formats and outputs an octet to the console in hex
 *
	@param O Octet to be output
 */
extern void OCT_output(octet *O);
/**	@brief Formats and outputs an octet to the console as a character string
 *
	@param O Octet to be output
 */
extern void OCT_output_string(octet *O);
/**	@brief Wipe clean an octet
 *
	@param O Octet to be cleaned
 */
extern void OCT_clear(octet *O);
/**	@brief Compare two octets
 *
	@param O first Octet to be compared
	@param P second Octet to be compared
	@return 1 if equal, else 0
 */
extern int  OCT_comp(octet *O,octet *P);
/**	@brief Compare first n bytes of two octets
 *
	@param O first Octet to be compared
	@param P second Octet to be compared
	@param n number of bytes to compare
	@return 1 if equal, else 0
 */
extern int  OCT_ncomp(octet *O,octet *P,int n);
/**	@brief Join from a C string to end of an octet
 *
	Truncates if there is no room
	@param O Octet to be written to
	@param s zero terminated string to be joined to octet
 */
extern void OCT_jstring(octet *O,char *s);
/**	@brief Join bytes to end of an octet
 *
	Truncates if there is no room
	@param O Octet to be written to
	@param s bytes to be joined to end of octet
	@param n number of bytes to join
 */
extern void OCT_jbytes(octet *O,char *s,int n);
/**	@brief Join single byte to end of an octet, repeated n times
 *
	Truncates if there is no room
	@param O Octet to be written to
	@param b byte to be joined to end of octet
	@param n number of times b is to be joined
 */
extern void OCT_jbyte(octet *O,int b,int n);
/**	@brief Join one octet to the end of another
 *
	Truncates if there is no room
	@param O Octet to be written to
	@param P Octet to be joined to the end of O
 */
extern void OCT_joctet(octet *O,octet *P);
/**	@brief XOR common bytes of a pair of Octets
 *
	@param O Octet - on exit = O xor P
	@param P Octet to be xored into O
 */
extern void OCT_xor(octet *O,octet *P);
/**	@brief reset Octet to zero length
 *
	@param O Octet to be emptied
 */
extern void OCT_empty(octet *O);
/**	@brief Pad out an Octet to the given length
 *
	Padding is done by inserting leading zeros, so abcd becomes 00abcd
	@param O Octet to be padded
	@param n new length of Octet
 */
extern int OCT_pad(octet *O,int n);
/**	@brief Convert an Octet to printable base64 number
 *
	@param b zero terminated byte array to take base64 conversion
	@param O Octet to be converted
 */
extern void OCT_tobase64(char *b,octet *O);
/**	@brief Populate an Octet from base64 number
 *
 	@param O Octet to be populated
	@param b zero terminated base64 string

 */
extern void OCT_frombase64(octet *O,char *b);
/**	@brief Copy one Octet into another
 *
 	@param O Octet to be copied to
	@param P Octet to be copied from

 */
extern void OCT_copy(octet *O,octet *P);
/**	@brief XOR every byte of an octet with input m
 *
 	@param O Octet
	@param m byte to be XORed with every byte of O

 */
extern void OCT_xorbyte(octet *O,int m);
/**	@brief Chops Octet into two, leaving first n bytes in O, moving the rest to P
 *
 	@param O Octet to be chopped
	@param P new Octet to be created
	@param n number of bytes to chop off O

 */
extern void OCT_chop(octet *O,octet *P,int n);
/**	@brief Join n bytes of integer m to end of Octet O (big endian)
 *
	Typically n is 4 for a 32-bit integer
 	@param O Octet to be appended to
	@param m integer to be appended to O
	@param n number of bytes in m

 */
extern void OCT_jint(octet *O,int m,int n);
/**	@brief Create an Octet from bytes taken from a random number generator
 *
	Truncates if there is no room
 	@param O Octet to be populated
	@param R an instance of a Cryptographically Secure Random Number Generator
	@param n number of bytes to extracted from R

 */
extern void OCT_rand(octet *O,csprng *R,int n);
/**	@brief Shifts Octet left by n bytes
 *
	Leftmost bytes disappear
 	@param O Octet to be shifted
	@param n number of bytes to shift

 */
extern void OCT_shl(octet *O,int n);
/**	@brief Convert a hex number to an Octet
 *
	@param dst Octet
	@param src Hex string to be converted
 */
extern void OCT_fromHex(octet *dst,char *src);
/**	@brief Convert an Octet to printable hex number
 *
	@param dst hex value
	@param src Octet to be converted
 */
extern void OCT_toHex(octet *src,char *dst);
/**	@brief Convert an Octet to string
 *
	@param dst string value
	@param src Octet to be converted
 */
extern void OCT_toStr(octet *src,char *dst);



/* Hash function */
/**	@brief Initialise an instance of SHA256
 *
	@param H an instance SHA256
 */
extern void HASH256_init(hash256 *H);
/**	@brief Add a byte to the hash
 *
	@param H an instance SHA256
	@param b byte to be included in hash
 */
extern void HASH256_process(hash256 *H,int b);
/**	@brief Generate 32-byte hash
 *
	@param H an instance SHA256
	@param h is the output 32-byte hash
 */
extern void HASH256_hash(hash256 *H,char *h);


/**	@brief Initialise an instance of SHA384
 *
	@param H an instance SHA384
 */
extern void HASH384_init(hash384 *H);
/**	@brief Add a byte to the hash
 *
	@param H an instance SHA384
	@param b byte to be included in hash
 */
extern void HASH384_process(hash384 *H,int b);
/**	@brief Generate 48-byte hash
 *
	@param H an instance SHA384
	@param h is the output 48-byte hash
 */
extern void HASH384_hash(hash384 *H,char *h);


/**	@brief Initialise an instance of SHA512
 *
	@param H an instance SHA512
 */
extern void HASH512_init(hash512 *H);
/**	@brief Add a byte to the hash
 *
	@param H an instance SHA512
	@param b byte to be included in hash
 */
extern void HASH512_process(hash512 *H,int b);
/**	@brief Generate 64-byte hash
 *
	@param H an instance SHA512
	@param h is the output 64-byte hash
 */
extern void HASH512_hash(hash512 *H,char *h);


/**	@brief Initialise an instance of SHA3
 *
	@param H an instance SHA3
	@param t the instance type
 */
extern void  SHA3_init(sha3 *H,int t);
/**	@brief process a byte for SHA3
 *
	@param H an instance SHA3
	@param b a byte of date to be processed
 */
extern void  SHA3_process(sha3 *H,int b);
/**	@brief create fixed length hash output of SHA3
 *
	@param H an instance SHA3
	@param h a byte array to take hash
 */
extern void  SHA3_hash(sha3 *H,char *h);
/**	@brief create variable length hash output of SHA3
 *
	@param H an instance SHA3
	@param h a byte array to take hash
	@param len is the length of the hash
 */
extern void  SHA3_shake(sha3 *H,char *h,int len);
/**	@brief generate further hash output of SHA3
 *
	@param H an instance SHA3
	@param h a byte array to take hash
	@param len is the length of the hash
 */
extern void  SHA3_squeeze(sha3 *H,char *h,int len);



/* AES functions */
/**	@brief Reset AES mode or IV
 *
	@param A an instance of the AMCL_AES
	@param m is the new active mode of operation (ECB, CBC, OFB, CFB etc)
	@param iv the new Initialisation Vector
 */
extern void AES_reset(amcl_aes *A,int m,char *iv);
/**	@brief Extract chaining vector from AMCL_AES instance
 *
	@param A an instance of the AMCL_AES
	@param f the extracted chaining vector
 */
extern void AES_getreg(amcl_aes *A,char * f);
/**	@brief Initialise an instance of AMCL_AES and its mode of operation
 *
	@param A an instance AMCL_AES
	@param m is the active mode of operation (ECB, CBC, OFB, CFB etc)
	@param n is the key length in bytes, 16, 24 or 32
	@param k the AES key as an array of 16 bytes
	@param iv the Initialisation Vector
	@return 0 for invalid n
 */
extern int AES_init(amcl_aes *A,int m,int n,char *k,char *iv);
/**	@brief Encrypt a single 16 byte block in ECB mode
 *
	@param A an instance of the AMCL_AES
	@param b is an array of 16 plaintext bytes, on exit becomes ciphertext
 */
extern void AES_ecb_encrypt(amcl_aes *A,uchar * b);
/**	@brief Decrypt a single 16 byte block in ECB mode
 *
	@param A an instance of the AMCL_AES
	@param b is an array of 16 cipherext bytes, on exit becomes plaintext
 */
extern void AES_ecb_decrypt(amcl_aes *A,uchar * b);
/**	@brief Encrypt a single 16 byte block in active mode
 *
	@param A an instance of the AMCL_AES
	@param b is an array of 16 plaintext bytes, on exit becomes ciphertext
	@return 0, or overflow bytes from CFB mode
 */
extern unsign32 AES_encrypt(amcl_aes *A,char *b );
/**	@brief Decrypt a single 16 byte block in active mode
 *
	@param A an instance of the AMCL_AES
	@param b is an array of 16 ciphertext bytes, on exit becomes plaintext
	@return 0, or overflow bytes from CFB mode
 */
extern unsign32 AES_decrypt(amcl_aes *A,char *b);
/**	@brief Clean up after application of AES
 *
	@param A an instance of the AMCL_AES
 */
extern void AES_end(amcl_aes *A);


/* AES-GCM functions */
/**	@brief Initialise an instance of AES-GCM mode
 *
	@param G an instance AES-GCM
	@param nk is the key length in bytes, 16, 24 or 32
	@param k the AES key as an array of 16 bytes
	@param n the number of bytes in the Initialisation Vector (IV)
	@param iv the IV
 */
extern void GCM_init(gcm *G,int nk,char *k,int n,char *iv);
/**	@brief Add header (material to be authenticated but not encrypted)
 *
	Note that this function can be called any number of times with n a multiple of 16, and then one last time with any value for n
	@param G an instance AES-GCM
	@param b is the header material to be added
	@param n the number of bytes in the header
 */
extern int GCM_add_header(gcm *G,char *b,int n);
/**	@brief Add plaintext and extract ciphertext
 *
	Note that this function can be called any number of times with n a multiple of 16, and then one last time with any value for n
	@param G an instance AES-GCM
	@param c is the ciphertext generated
	@param p is the plaintext material to be added
	@param n the number of bytes in the plaintext
 */
extern int GCM_add_plain(gcm *G,char *c,char *p,int n);
/**	@brief Add ciphertext and extract plaintext
 *
	Note that this function can be called any number of times with n a multiple of 16, and then one last time with any value for n
	@param G an instance AES-GCM
	@param p is the plaintext generated
	@param c is the ciphertext material to be added
	@param n the number of bytes in the ciphertext
 */
extern int GCM_add_cipher(gcm *G,char *p,char *c,int n);
/**	@brief Finish off and extract authentication tag (HMAC)
 *
	@param G is an active instance AES-GCM
	@param t is the output 16 byte authentication tag
 */
extern void GCM_finish(gcm *G,char *t);



/* random numbers */
/**	@brief Seed a random number generator from an array of bytes
 *
	The provided seed should be truly random
	@param R an instance of a Cryptographically Secure Random Number Generator
	@param n the number of seed bytes provided
	@param b an array of seed bytes

 */
extern void RAND_seed(csprng *R,int n,char *b);
/**	@brief Delete all internal state of a random number generator
 *
	@param R an instance of a Cryptographically Secure Random Number Generator
 */
extern void RAND_clean(csprng *R);
/**	@brief Return a random byte from a random number generator
 *
	@param R an instance of a Cryptographically Secure Random Number Generator
	@return a random byte
 */
extern int RAND_byte(csprng *R);



#endif
