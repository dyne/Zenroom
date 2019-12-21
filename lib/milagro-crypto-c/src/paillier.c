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

/* test driver and function exerciser for Paillier functions */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "ff_4096.h"
#include "ff_2048.h"
#include "paillier.h"

// generate a Paillier key pair 
void PAILLIER_KEY_PAIR(csprng *RNG, octet *P, octet* Q, PAILLIER_public_key *PUB, PAILLIER_private_key *PRIV)
{
    char oct[FS_2048];
    octet OCT = {0, FS_2048, oct};

    // Public key
    BIG_1024_58 g[FFLEN_2048];

    // Workspace for CRT precomputations
    BIG_1024_58 ff[FFLEN_2048];
    BIG_1024_58 dff[2*FFLEN_2048];

    /* Private key */

    if (RNG!=NULL)
    {
        // p
        FF_2048_random(PRIV->p, RNG, HFLEN_2048);
        while (FF_2048_lastbits(PRIV->p, 2) != 3)
        {
            FF_2048_inc(PRIV->p, 1, HFLEN_2048);
        }
        while (!FF_2048_prime(PRIV->p, RNG, HFLEN_2048))
        {
            FF_2048_inc(PRIV->p, 4, HFLEN_2048);
        }

        // q
        FF_2048_random(PRIV->q, RNG, HFLEN_2048);
        while (FF_2048_lastbits(PRIV->q, 2) != 3)
        {
            FF_2048_inc(PRIV->q, 1, HFLEN_2048);
        }
        while (!FF_2048_prime(PRIV->q, RNG, HFLEN_2048))
        {
            FF_2048_inc(PRIV->q, 4, HFLEN_2048);
        }
    }
    else
    {
        FF_2048_fromOctet(PRIV->p, P, HFLEN_2048);
        FF_2048_fromOctet(PRIV->q, Q, HFLEN_2048);
    }

    // lp = p-1, lq = q-1
    FF_2048_copy(PRIV->lp, PRIV->p, HFLEN_2048);
    FF_2048_copy(PRIV->lq, PRIV->q, HFLEN_2048);
    FF_2048_dec(PRIV->lp, 1, HFLEN_2048);
    FF_2048_dec(PRIV->lq, 1, HFLEN_2048);

    /* Precomputations for Secret Key */

    // p^{-1}, q^{-1} mod 2^m for division trick
    FF_2048_zero(PRIV->invp, FFLEN_2048);
    FF_2048_zero(PRIV->invq, FFLEN_2048);
    FF_2048_invmod2m(PRIV->invp, PRIV->p, HFLEN_2048);
    FF_2048_invmod2m(PRIV->invq, PRIV->q, HFLEN_2048);

    // p^2, q^2
    FF_2048_sqr(PRIV->p2, PRIV->p, HFLEN_2048);
    FF_2048_sqr(PRIV->q2, PRIV->q, HFLEN_2048);
    FF_2048_norm(PRIV->p2, FFLEN_2048);
    FF_2048_norm(PRIV->q2, FFLEN_2048);

    // g = n + 1
    FF_2048_mul(g, PRIV->p, PRIV->q, HFLEN_2048);
    FF_2048_inc(g, 1, FFLEN_2048);

    // (((g^(p-1) mod p^2) - 1) / p)^(-1) mod p for dec/enc with CRT
    FF_2048_skpow(ff, g, PRIV->lp, PRIV->p2, FFLEN_2048, HFLEN_2048);
    FF_2048_dec(ff, 1, FFLEN_2048);
    FF_2048_mul(dff, ff, PRIV->invp, FFLEN_2048);
    FF_2048_invmodp(PRIV->mp, dff, PRIV->p, HFLEN_2048);

    // (((g^(q-1) mod q^2) - 1) / q)^(-1) mod q for dec/enc with CRT
    FF_2048_skpow(ff, g, PRIV->lq, PRIV->q2, FFLEN_2048, HFLEN_2048);
    FF_2048_dec(ff, 1, FFLEN_2048);
    FF_2048_mul(dff, ff, PRIV->invq, FFLEN_2048);
    FF_2048_invmodp(PRIV->mq, dff, PRIV->q, HFLEN_2048);

    /* Public Key */

    // g = n + 1
    FF_2048_toOctet(&OCT, g, FFLEN_2048);
    FF_4096_zero(PUB->g, FFLEN_4096);
    FF_4096_fromOctet(PUB->g, &OCT, HFLEN_4096);
    OCT_empty(&OCT);

    // n
    FF_2048_dec(g, 1, FFLEN_2048);
    FF_2048_toOctet(&OCT, g, FFLEN_2048);
    FF_4096_zero(PUB->n, FFLEN_4096);
    FF_4096_fromOctet(PUB->n, &OCT, HFLEN_4096);
    OCT_empty(&OCT);

    // Precompute n^2 for public key
    FF_4096_sqr(PUB->n2, PUB->n, HFLEN_4096);
    FF_4096_norm(PUB->n2, FFLEN_4096);

    // Clean memory
    FF_2048_zero(ff, FFLEN_2048);
    FF_2048_zero(dff, 2*FFLEN_2048);
}

/* Clean secrets from private key */
void PAILLIER_PRIVATE_KEY_KILL(PAILLIER_private_key *PRIV)
{
    FF_2048_zero(PRIV->p,    HFLEN_2048);
    FF_2048_zero(PRIV->q,    HFLEN_2048);
    FF_2048_zero(PRIV->lp,   HFLEN_2048);
    FF_2048_zero(PRIV->lq,   HFLEN_2048);
    FF_2048_zero(PRIV->p2,   FFLEN_2048);
    FF_2048_zero(PRIV->q2,   FFLEN_2048);
    FF_2048_zero(PRIV->mp,   HFLEN_2048);
    FF_2048_zero(PRIV->mq,   HFLEN_2048);
    FF_2048_zero(PRIV->invp, FFLEN_2048);
    FF_2048_zero(PRIV->invq, FFLEN_2048);
}

// Paillier encryption
void PAILLIER_ENCRYPT(csprng *RNG, PAILLIER_public_key *PUB, octet* PT, octet* CT, octet* R)
{
    // Random r < n^2
    BIG_512_60 r[FFLEN_4096];

    // plaintext
    BIG_512_60 pt[HFLEN_4096];

    // ciphertext
    BIG_512_60 ct[FFLEN_4096];

    FF_4096_fromOctet(pt,PT,HFLEN_4096);

    // In production generate R from RNG
    if (RNG!=NULL)
    {
        FF_4096_randomnum(r, PUB->n2, RNG,FFLEN_4096);
    }
    else
    {
        FF_4096_fromOctet(r, R, FFLEN_4096);
    }

    // ct = g^pt * r^n mod n2
    FF_4096_skpow2(ct, PUB->g, pt, r, PUB->n, PUB->n2, FFLEN_4096, HFLEN_4096);

    // Output
    FF_4096_toOctet(CT, ct, FFLEN_4096);

    // Output R for Debug
    if (R!=NULL)
    {
        FF_4096_toOctet(R, r, HFLEN_4096);
    }

    // Clean memory
    FF_4096_zero(r, FFLEN_4096);
    FF_4096_zero(pt, HFLEN_4096);
}

// Paillier decryption
void PAILLIER_DECRYPT(PAILLIER_private_key *PRIV, octet* CT, octet* PT)
{
    // Chiphertext
    BIG_1024_58 ct[2 * FFLEN_2048];

    // Plaintext
    BIG_1024_58 pt[FFLEN_2048];
    BIG_1024_58 ptp[HFLEN_2048];
    BIG_1024_58 ptq[HFLEN_2048];

    // Work space
    BIG_1024_58 ctl[FFLEN_2048];
    BIG_1024_58 ctln[2 * FFLEN_2048];

    FF_2048_fromOctet(ct, CT, 2 * FFLEN_2048);

    /* Decryption modulo p */

    FF_2048_dmod(ctl, ct, PRIV->p2, FFLEN_2048);

    // Compute ctl = (ct^lp mod p2 - 1)
    FF_2048_skpow(ctl, ctl, PRIV->lp, PRIV->p2, FFLEN_2048, HFLEN_2048);
    FF_2048_dec(ctl, 1, FFLEN_2048);

    // ctln = ctl / p
    // Division by p using the inverse mod 2^m trick
    FF_2048_mul(ctln, ctl, PRIV->invp, FFLEN_2048);

    // ptp = ctln * mp mod p
    FF_2048_mul(ptp, ctln, PRIV->mp, HFLEN_2048);
    FF_2048_dmod(ptp, ptp, PRIV->p, HFLEN_2048);

    /* Decryption modulo q */

    FF_2048_dmod(ctl, ct, PRIV->q2, FFLEN_2048);

    // Compute ctl = (ct^lq mod q2 - 1)
    FF_2048_skpow(ctl, ctl, PRIV->lq, PRIV->q2, FFLEN_2048, HFLEN_2048);
    FF_2048_dec(ctl, 1, FFLEN_2048);

    // ctln = ctl / q
    // Division by q using the inverse mod 2^m trick
    FF_2048_mul(ctln, ctl, PRIV->invq, FFLEN_2048);

    // ptq = ctln * mq mod q
    FF_2048_mul(ptq, ctln, PRIV->mq, HFLEN_2048);
    FF_2048_dmod(ptq, ptq, PRIV->q, HFLEN_2048);

    /* Combine results using CRT */
    FF_2048_crt(pt, ptp, ptq, PRIV->p, PRIV->q, HFLEN_2048);

    // Output
    FF_2048_toOctet(PT, pt, FFLEN_2048);

    // Clean memory
    FF_2048_zero(pt,   FFLEN_2048);
    FF_2048_zero(ptp,  HFLEN_2048);
    FF_2048_zero(ptq,  HFLEN_2048);
    FF_2048_zero(ctl,  FFLEN_2048);
    FF_2048_zero(ctln, 2 * FFLEN_2048);
}

// Homomorphic addition of plaintexts 
void PAILLIER_ADD(PAILLIER_public_key *PUB, octet* CT1, octet* CT2, octet* CT)
{
    // ciphertext
    BIG_512_60 ct1[FFLEN_4096];
    BIG_512_60 ct2[FFLEN_4096];
    BIG_512_60 ct[2 * FFLEN_4096];

    FF_4096_fromOctet(ct1, CT1, FFLEN_4096);
    FF_4096_fromOctet(ct2, CT2, FFLEN_4096);

    // ct = ct1 * ct2 mod n^2
    FF_4096_mul(ct, ct1, ct2, FFLEN_4096);
    FF_4096_dmod(ct, ct, PUB->n2, FFLEN_4096);

    // Output
    FF_4096_toOctet(CT, ct, FFLEN_4096);
}

// Homomorphic multiplication of plaintext
void PAILLIER_MULT(PAILLIER_public_key *PUB, octet* CT1, octet* PT, octet* CT)
{
    // Ciphertext
    BIG_512_60 ct1[FFLEN_4096];

    // Plaintext
    BIG_512_60 pt[HFLEN_4096];

    // Ciphertext output. ct = ct1 ^ pt mod n^2
    BIG_512_60 ct[FFLEN_4096];

    FF_4096_fromOctet(pt, PT, HFLEN_4096);
    FF_4096_fromOctet(ct1, CT1, FFLEN_4096);

    // ct1^pt mod n^2
    FF_4096_skpow(ct, ct1, pt, PUB->n2, FFLEN_4096, HFLEN_4096);

    // output
    FF_4096_toOctet(CT, ct, FFLEN_4096);

    // Clean memory
    FF_4096_zero(pt, HFLEN_4096);
}

// Read a public key from its octet representation
void PAILLIER_PK_fromOctet(PAILLIER_public_key *PUB, octet *PK)
{
    FF_4096_zero(PUB->n, FFLEN_4096);
    FF_4096_fromOctet(PUB->n, PK, HFLEN_4096);

    FF_4096_sqr(PUB->n2, PUB->n, HFLEN_4096);
    FF_4096_norm(PUB->n2, FFLEN_4096);

    FF_4096_copy(PUB->g, PUB->n, FFLEN_4096);
    FF_4096_inc(PUB->g, 1, HFLEN_4096);
}

// Write a public key to an octet
void PAILLIER_PK_toOctet(octet *PK, PAILLIER_public_key *PUB)
{
    FF_4096_toOctet(PK, PUB->n, HFLEN_4096);
}
