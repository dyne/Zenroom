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
   Example of Paillier crypto system.

   Homomorphic multiplicaton of ciphertext by a constant and
   homomorphic addition of ciphertexts
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "randapi.h"
#include "paillier.h"

#define NTHREADS 2

int paillier(csprng *RNG)
{
    // Key material
    PAILLIER_private_key PRIV;
    PAILLIER_public_key PUB;

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

    printf("Generating public/private key pair\n");
    PAILLIER_KEY_PAIR(RNG, NULL, NULL, &PUB, &PRIV);

    printf("P: ");
    FF_2048_output(PRIV.p, HFLEN_2048);
    printf("\n");
    printf("Q: ");
    FF_2048_output(PRIV.q, HFLEN_2048);
    printf("\n");

    printf("Public Key \n");
    printf("N: ");
    FF_4096_output(PUB.n, HFLEN_4096);
    printf("\n");
    printf("G: ");
    FF_4096_output(PUB.g, FFLEN_4096);
    printf("\n");

    printf("Secret Key \n");
    printf("L_p: ");
    FF_2048_output(PRIV.lp, HFLEN_2048);
    printf("\n");
    printf("L_q: ");
    FF_2048_output(PRIV.lq, HFLEN_2048);
    printf("\n");
    printf("M_p: ");
    FF_2048_output(PRIV.mp, HFLEN_2048);
    printf("\n");
    printf("M_q: ");
    FF_2048_output(PRIV.mq, HFLEN_2048);
    printf("\n");

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

    for(int i=0; i<NTHREADS; i++)
    {
        printf("PTIN[%d] ", i);
        OCT_output(&PTIN[i]);
        printf("\n");
    }

    // Encrypt plaintext
    for(int i=0; i<NTHREADS; i++)
    {
        PAILLIER_ENCRYPT(RNG, &PUB, &PTIN[i], &CT[i], NULL);
    }

    for(int i=0; i<NTHREADS; i++)
    {
        printf("CT[%d] ", i);
        OCT_output(&CT[i]);
        printf("\n");
    }

    // Decrypt ciphertexts
    for(int i=0; i<NTHREADS; i++)
    {
        PAILLIER_DECRYPT(&PRIV, &CT[i], &PTOUT[i]);
    }

    for(int i=0; i<NTHREADS; i++)
    {
        printf("PTOUT[%d] ", i);
        OCT_output(&PTOUT[i]);
        printf("\n");
    }

    for(int i=0; i<NTHREADS; i++)
    {
        PAILLIER_MULT(&PUB, &CT[i], &PTK[i], &CTA[i]);
    }

    PAILLIER_ADD(&PUB, &CTA[0], &CTA[1], &CT3);

    for(int i=0; i<NTHREADS; i++)
    {
        printf("CTA[%d] ", i);
        OCT_output(&CTA[i]);
        printf("\n");
    }
    printf("CT3: ");
    OCT_output(&CT3);
    printf("\n");

    PAILLIER_DECRYPT(&PRIV, &CT3, &PT3);

    printf("PT3: ");
    OCT_output(&PT3);
    printf("\n");

    // Clear sensitive memory
    PAILLIER_PRIVATE_KEY_KILL(&PRIV);

    OCT_clear(&PT3);
    for(int i=0; i<NTHREADS; i++)
    {
        OCT_clear(&PTIN[i]);
        OCT_clear(&PTOUT[i]);
    }

    return 0;
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

    printf("\nPaillier example\n");
    paillier(&RNG);

    KILL_CSPRNG(&RNG);
}
