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

/*
   Smoke test of Paillier crypto system.
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "randapi.h"
#include "paillier.h"

#define NTHREADS 2

char* PT3GOLDEN_hex = "0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a";

void ff_4096_compare(BIG_512_60 *a, BIG_512_60 *b, char *msg, int n)
{
    if(FF_4096_comp(a, b, n))
    {
        fprintf(stderr, "FAILURE %s\n", msg);
        exit(EXIT_FAILURE);
    }
}

void ff_2048_compare(BIG_1024_58 *a, BIG_1024_58 *b, char *msg, int n)
{
    if(FF_2048_comp(a, b, n))
    {
        fprintf(stderr, "FAILURE %s\n", msg);
        exit(EXIT_FAILURE);
    }
}

int paillier(csprng *RNG)
{
    BIG_1024_58 zero[FFLEN_2048];

    // Key material
    PAILLIER_private_key PRIV;
    PAILLIER_public_key PUB, PUBIN;

    char pub[HFS_4096];
    octet PUBOCT = {0,HFS_4096,pub};

    // Plaintext to encrypt
    char ptin[NTHREADS][FS_2048];
    octet PTIN[NTHREADS];
    char ptout[NTHREADS][FS_2048];
    octet PTOUT[NTHREADS];

    // Constant value for multiplication
    char ptko[NTHREADS][FS_2048];
    octet PTK[NTHREADS];

    // Encrypted PTIN values
    char cto[NTHREADS][FS_4096];
    octet CT[NTHREADS];

    // Homomorphic multiplicaton of plaintext by a constant ciphertext
    char cta[NTHREADS][FS_4096];
    octet CTA[NTHREADS];

    // Homomorphic addition of ciphertext
    char cto3[FS_4096] = {0};
    octet CT3 = {0,sizeof(cto3),cto3};

    // Output plaintext of addition of homomorphic multiplication values
    char pto3[FS_2048] = {0};
    octet PT3 = {sizeof(pto3),sizeof(pto3),pto3};

    // Expected output plaintext of addition of homomorphic multiplication values
    char ptog3[FS_2048] = {0};
    octet PT3GOLDEN = {sizeof(ptog3),sizeof(ptog3),ptog3};

    // Expected ouput is 26 / 0x1a i.e. 2*3 + 4*5
    int values[NTHREADS] = {2,4};
    int kvalues[NTHREADS] = {3,5};

    // Initialize octets
    for(int i=0; i<NTHREADS; i++)
    {
        PTIN[i].max = FS_2048;
        PTIN[i].val = ptin[i];
        OCT_clear(&PTIN[i]);

        PTOUT[i].max = FS_2048;
        PTOUT[i].val = ptout[i];
        OCT_clear(&PTOUT[i]);

        PTK[i].max = FS_2048;
        PTK[i].val = ptko[i];
        OCT_clear(&PTIN[i]);

        CT[i].max = FS_4096;
        CT[i].val = cto[i];
        OCT_clear(&PTIN[i]);

        CTA[i].max = FS_4096;
        CTA[i].val = cta[i];
        OCT_clear(&PTIN[i]);
    }

    PAILLIER_KEY_PAIR(RNG, NULL, NULL, &PUB, &PRIV);

    // Check public key i/o functions
    PAILLIER_PK_toOctet(&PUBOCT, &PUB);
    PAILLIER_PK_fromOctet(&PUBIN, &PUBOCT);

    ff_4096_compare(PUB.n,  PUBIN.n,  "n not correctly loaded",   FFLEN_4096);
    ff_4096_compare(PUB.g,  PUBIN.g,  "g not correctly loaded",   FFLEN_4096);
    ff_4096_compare(PUB.n2, PUBIN.n2, "n^2 not correctly loaded", FFLEN_4096);

    // Set plaintext values
    for(int i=0; i<NTHREADS; i++)
    {
        BIG_1024_58 pt[FFLEN_2048];
        FF_2048_init(pt, values[i],FFLEN_2048);
        FF_2048_toOctet(&PTIN[i], pt, FFLEN_2048);

        BIG_1024_58 ptk[FFLEN_2048];
        FF_2048_init(ptk, kvalues[i],FFLEN_2048);
        FF_2048_toOctet(&PTK[i], ptk, FFLEN_2048);
    }

    // Encrypt plaintext
    for(int i=0; i<NTHREADS; i++)
    {
        PAILLIER_ENCRYPT(RNG, &PUB, &PTIN[i], &CT[i], NULL);
    }

    // Decrypt ciphertexts
    for(int i=0; i<NTHREADS; i++)
    {
        PAILLIER_DECRYPT(&PRIV, &CT[i], &PTOUT[i]);
    }

    for(int i=0; i<NTHREADS; i++)
    {
        PAILLIER_MULT(&PUB, &CT[i], &PTK[i], &CTA[i]);
    }

    PAILLIER_ADD(&PUB, &CTA[0], &CTA[1], &CT3);

    PAILLIER_DECRYPT(&PRIV, &CT3, &PT3);

    OCT_fromHex(&PT3GOLDEN,PT3GOLDEN_hex);
    if(!OCT_comp(&PT3GOLDEN,&PT3))
    {
        fprintf(stderr, "FAILURE PT3 != PT3GOLDEN\n");
        exit(EXIT_FAILURE);
    }

    PAILLIER_PRIVATE_KEY_KILL(&PRIV);

    FF_2048_zero(zero, FFLEN_2048);
    ff_2048_compare(zero, PRIV.p,    "p not cleaned from private key",    HFLEN_2048);
    ff_2048_compare(zero, PRIV.q,    "q not cleaned from private key",    HFLEN_2048);
    ff_2048_compare(zero, PRIV.lp,   "lp not cleaned from private key",   HFLEN_2048);
    ff_2048_compare(zero, PRIV.lq,   "lq not cleaned from private key",   HFLEN_2048);
    ff_2048_compare(zero, PRIV.mp,   "mp not cleaned from private key",   HFLEN_2048);
    ff_2048_compare(zero, PRIV.mq,   "mq not cleaned from private key",   HFLEN_2048);
    ff_2048_compare(zero, PRIV.p2,   "p2 not cleaned from private key",   FFLEN_2048);
    ff_2048_compare(zero, PRIV.q2,   "q2 not cleaned from private key",   FFLEN_2048);
    ff_2048_compare(zero, PRIV.invp, "invp not cleaned from private key", FFLEN_2048);
    ff_2048_compare(zero, PRIV.invq, "invq not cleaned from private key", FFLEN_2048);

    OCT_clear(&CT3);
    OCT_clear(&PT3);
    for(int i=0; i<NTHREADS; i++)
    {
        OCT_clear(&PTIN[i]);
        OCT_clear(&PTOUT[i]);
        OCT_clear(&CT[i]);
        OCT_clear(&CTA[i]);
    }

    printf("SUCCESS\n");
    exit(EXIT_SUCCESS);
}

int main()
{
    char* seedHex = "78d0fb6705ce77dee47d03eb5b9c5d30";
    char seed[16] = {0};
    octet SEED = {sizeof(seed),sizeof(seed),seed};

    // CSPRNG
    csprng RNG;

    // fake random source
    OCT_fromHex(&SEED,seedHex);
    printf("SEED: ");
    OCT_output(&SEED);

    // initialise strong RNG
    CREATE_CSPRNG(&RNG,&SEED);

    paillier(&RNG);

    KILL_CSPRNG(&RNG);
}
