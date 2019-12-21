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
 * @file paillier.h
 * @brief Paillier declarations
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "ff_4096.h"
#include "ff_2048.h"

// Field size
#define FS_4096 MODBYTES_512_60*FFLEN_4096    /**< 4096 field size in bytes */
#define FS_2048 MODBYTES_1024_58*FFLEN_2048   /**< 2048 field size in bytes */

// Half field size
#define HFS_4096 MODBYTES_512_60*HFLEN_4096   /**< Half 4096 field size in bytes */
#define HFS_2048 MODBYTES_1024_58*HFLEN_2048  /**< Half 2048 field size in bytes */

/*!
 * \brief Paillier Public Key
 */
typedef struct{
    BIG_512_60 n[FFLEN_4096]; /**< Paillier Modulus - \f$ n = pq \f$ */
    BIG_512_60 g[FFLEN_4096]; /**< Public Base - \f$ g = n+1 \f$ */

    BIG_512_60 n2[FFLEN_4096]; /**< Precomputed \f$ n^2 \f$ */
}PAILLIER_public_key;

/*!
 * \brief Paillier Private Key
 */
typedef struct{
    BIG_1024_58 p[HFLEN_2048]; /**< Secret Prime */
    BIG_1024_58 q[HFLEN_2048]; /**< Secret Prime */

    BIG_1024_58 lp[HFLEN_2048]; /**< Private Key modulo \f$ p \f$ (Euler totient of \f$ p \f$) */
    BIG_1024_58 lq[HFLEN_2048]; /**< Private Key modulo \f$ q \f$ (Euler totient of \f$ q \f$) */

    BIG_1024_58 invp[FFLEN_2048]; /**< Precomputed \f$ p^{-1} \pmod{2^m} \f$ */
    BIG_1024_58 invq[FFLEN_2048]; /**< Precomputed \f$ q^{-1} \pmod{2^m} \f$ */

    BIG_1024_58 p2[FFLEN_2048]; /**< Precomputed \f$ p^2 \f$ */
    BIG_1024_58 q2[FFLEN_2048]; /**< Precomputed \f$ q^2 \f$ */

    BIG_1024_58 mp[HFLEN_2048]; /**< Precomputed \f$ L(g^{lp} \pmod{p^2})^{-1} \f$ */
    BIG_1024_58 mq[HFLEN_2048]; /**< Precomputed \f$ L(g^{lq} \pmod{q^2})^{-1} \f$ */
}PAILLIER_private_key;

/*! \brief Generate the key pair
 *
 *  Pick large prime numbers of the same size \f$ p \f$ and \f$ q \f$
 *
 *  <ol>
 *  <li> \f$ n = pq \f$
 *  <li> \f$ g = n + 1 \f$
 *  <li> \f$ l = (p-1)(q-1) \f$
 *  <li> \f$ m = l^{-1} \pmod{n} \f$
 *  </ol>
 *
 *  @param  RNG              Pointer to a cryptographically secure random number generator
 *  @param  P                Prime number. If RNG is NULL then this value is read
 *  @param  Q                Prime number. If RNG is NULL then this value is read
 *  @param  PUB              Public key
 *  @param  PRIV             Private key
 */
void PAILLIER_KEY_PAIR(csprng *RNG, octet *P, octet* Q, PAILLIER_public_key *PUB, PAILLIER_private_key *PRIV);

/*! \brief Clear private key
 *
 *  @param PRIV             Private key to clean
 */
void PAILLIER_PRIVATE_KEY_KILL(PAILLIER_private_key *PRIV);

/*! \brief Encrypt a plaintext
 *
 *  These are the encryption steps.
 *
 *  <ol>
 *  <li> \f$ m < n \f$
 *  <li> \f$ r < n \f$
 *  <li> \f$ c = g^m.r^n\pmod{n^2} \f$
 *  </ol>
 *
 *  @param  RNG              Pointer to a cryptographically secure random number generator
 *  @param  PUB              Public key
 *  @param  PT               Plaintext
 *  @param  CT               Ciphertext
 *  @param  R                R value for testing. If RNG is NULL then this value is read.
 */
void PAILLIER_ENCRYPT(csprng *RNG, PAILLIER_public_key *PUB, octet* PT, octet* CT, octet* R);

/*! \brief Decrypt ciphertext
 *
 *  These are the decryption steps modulo n.
 *  The computations are carried out modulo p and q
 *  and combined using the CRT.
 *
 *  <ol>
 *  <li> \f$ ctl = ct^l \pmod{n^2} - 1 \f$
 *  <li> \f$ ctln = ctl / n \f$
 *  <li> \f$ pt = ctln * m \pmod{n} \f$
 *  </ol>
 *
 *  @param   PRIV             Private key
 *  @param   CT               Ciphertext
 *  @param   PT               Plaintext
 */
void PAILLIER_DECRYPT(PAILLIER_private_key *PRIV, octet* CT, octet* PT);

/*! \brief Homomorphic addition of plaintexts
 *
 *  \f$ E(m1+m2) = E(m1)*E(m2) \f$
 *
 *  <ol>
 *  <li> \f$ ct = ct1*ct2 \pmod{n^2} \f$
 *  </ol>
 *
 *  @param   PUB              Public key
 *  @param   CT1              Ciphertext one
 *  @param   CT2              Ciphertext two
 *  @param   CT               Ciphertext
 *  @return                   Returns 0 or else error code
 */
void PAILLIER_ADD(PAILLIER_public_key *PUB, octet* CT1, octet* CT2, octet* CT);

/*! \brief Homomorphic multipication of plaintexts
 *
 *  \f$ E(m1*m2) = E(m1)^{m2} \f$
 *
 *  <ol>
 *  <li> \f$ ct = ct1^{m2} \pmod{n^2} \f$
 *  </ol>
 *
 *  @param   PUB              Public key
 *  @param   CT1              Ciphertext one
 *  @param   PT               Plaintext constant
 *  @param   CT               Ciphertext
 */
void PAILLIER_MULT(PAILLIER_public_key *PUB, octet* CT1, octet* PT, octet* CT);

/*! \brief Read a public key from its octet representation
 *
 * @param   PUB   Public key
 * @param   PK    Octet representation of the public key
 */
void PAILLIER_PK_fromOctet(PAILLIER_public_key *PUB, octet *PK);

/*! \brief Write a public key to an octet
 *
 * @param   PK    Destination octet
 * @param   PUB   Public key
 */
void PAILLIER_PK_toOctet(octet *PK, PAILLIER_public_key *PUB);
