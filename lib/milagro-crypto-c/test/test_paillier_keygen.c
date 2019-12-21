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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "amcl.h"
#include "randapi.h"
#include "paillier.h"

#define LINE_LEN 2000

void read_OCTET(octet* OCT, char* string)
{
    int len = strlen(string);
    char buff[len];
    memcpy(buff,string,len);
    char *end = strchr(buff,',');
    if (end == NULL)
    {
        printf("ERROR unexpected test vector %s\n",string);
        exit(EXIT_FAILURE);
    }
    end[0] = '\0';
    OCT_fromHex(OCT,buff);
}

void read_FF_2048(BIG_1024_58 *x, char* string, int n)
{
    int len = strlen(string);
    char oct[len/2];
    octet OCT = {0, len/2, oct};

    read_OCTET(&OCT, string);
    FF_2048_fromOctet(x, &OCT, n);
}

void read_FF_4096(BIG_512_60 *x, char* string, int n)
{
    int len = strlen(string);
    char oct[len/2];
    octet OCT = {0, len/2, oct};

    read_OCTET(&OCT, string);
    FF_4096_fromOctet(x, &OCT, n);
}

void ff_4096_compare(char *x_name, char* y_name, BIG_512_60 *x, BIG_512_60 *y, int n)
{
    if(FF_4096_comp(x, y, n))
    {
        fprintf(stderr, "FAILURE %s != %s\n", x_name, y_name);
        exit(EXIT_FAILURE);
    }
}

void ff_2048_compare(char *x_name, char* y_name, BIG_1024_58 *x, BIG_1024_58 *y, int n)
{
    if(FF_2048_comp(x, y, n))
    {
        fprintf(stderr, "FAILURE %s != %s\n", x_name, y_name);
        exit(EXIT_FAILURE);
    }
}

void clean_public(PAILLIER_public_key *PUB)
{
    FF_4096_zero(PUB->n, FFLEN_4096);
    FF_4096_zero(PUB->g, FFLEN_4096);
    FF_4096_zero(PUB->n2, FFLEN_4096);
}

int main(int argc, char** argv)
{
    if (argc != 2)
    {
        printf("usage: ./test_paillier_decrypt [path to test vector file]\n");
        exit(EXIT_FAILURE);
    }

    int len=0;
    FILE *fp;

    char line[LINE_LEN]= {0};
    char * linePtr=NULL;

    int testSeed=0;

    PAILLIER_private_key PRIV;
    PAILLIER_public_key PUB;

    int testNo=0;
    const char* TESTline = "TEST = ";

    char seedgolden[32]= {0};
    octet SEEDGOLDEN = {0,sizeof(seedgolden),seedgolden};
    const char* SEEDline = "SEED = ";

    char pgolden[HFS_2048]= {0};
    octet PGOLDEN = {0,sizeof(pgolden),pgolden};
    const char* Pline = "P = ";

    char qgolden[HFS_2048]={0};
    octet QGOLDEN = {0,sizeof(qgolden),qgolden};
    const char* Qline = "Q = ";

    PAILLIER_private_key PRIVGOLDEN;
    PAILLIER_public_key PUBGOLDEN;
    const char* Nline = "N = ";
    const char* Gline = "G = ";
    const char* LPline = "LP = ";
    const char* MPline = "MP = ";
    const char* LQline = "LQ = ";
    const char* MQline = "MQ = ";

    // Clean GOLDEN keys, the generated keys should be cleaned
    // during initialisation
    PAILLIER_PRIVATE_KEY_KILL(&PRIVGOLDEN);
    clean_public(&PUBGOLDEN);

    fp = fopen(argv[1], "r");
    if (fp == NULL)
    {
        printf("ERROR opening test vector file\n");
        exit(EXIT_FAILURE);
    }

    while (fgets(line, LINE_LEN, fp) != NULL)
    {
        // Read TEST Number
        if (!strncmp(line,TESTline, strlen(TESTline)))
        {
            len = strlen(TESTline);
            linePtr = line + len;
            sscanf(linePtr,"%d\n",&testNo);
        }

        // Read SEED
        if (!strncmp(line,SEEDline, strlen(SEEDline)))
        {
            len = strlen(SEEDline);
            linePtr = line + len;
            read_OCTET(&SEEDGOLDEN,linePtr);
            testSeed = 1;
        }

        // Read G
        if (!strncmp(line, Gline, strlen(Gline)))
        {
            len = strlen(Gline);
            linePtr = line + len;
            read_FF_4096(PUBGOLDEN.g, linePtr, HFLEN_4096);
        }

        // Read N
        if (!strncmp(line, Nline, strlen(Nline)))
        {
            len = strlen(Nline);
            linePtr = line + len;

            FF_4096_zero(PUBGOLDEN.n, FFLEN_4096);
            read_FF_4096(PUBGOLDEN.n, linePtr, HFLEN_4096);

            FF_4096_sqr(PUBGOLDEN.n2, PUBGOLDEN.n, HFLEN_4096);
            FF_4096_norm(PUBGOLDEN.n2, FFLEN_4096);
        }

        // Read P
        if (!strncmp(line, Pline, strlen(Pline)))
        {
            len = strlen(Pline);
            linePtr = line + len;
            read_OCTET(&PGOLDEN, linePtr);
            read_FF_2048(PRIVGOLDEN.p, linePtr, HFLEN_2048);

            FF_2048_sqr(PRIVGOLDEN.p2, PRIVGOLDEN.p, HFLEN_2048);
            FF_2048_norm(PRIVGOLDEN.p2, FFLEN_2048);
            FF_2048_invmod2m(PRIVGOLDEN.invp, PRIVGOLDEN.p, HFLEN_2048);
        }

        // Read Q
        if (!strncmp(line, Qline, strlen(Qline)))
        {
            len = strlen(Qline);
            linePtr = line + len;
            read_OCTET(&QGOLDEN, linePtr);
            read_FF_2048(PRIVGOLDEN.q, linePtr, HFLEN_2048);

            FF_2048_sqr(PRIVGOLDEN.q2, PRIVGOLDEN.q, HFLEN_2048);
            FF_2048_norm(PRIVGOLDEN.q2, FFLEN_2048);
            FF_2048_invmod2m(PRIVGOLDEN.invq, PRIVGOLDEN.q, HFLEN_2048);
        }

        // Read LP
        if (!strncmp(line, LPline, strlen(LPline)))
        {
            len = strlen(LPline);
            linePtr = line + len;
            read_FF_2048(PRIVGOLDEN.lp, linePtr, HFLEN_2048);
        }

        // Read LQ
        if (!strncmp(line, LQline, strlen(LQline)))
        {
            len = strlen(LQline);
            linePtr = line + len;
            read_FF_2048(PRIVGOLDEN.lq, linePtr, HFLEN_2048);
        }

        // Read MP
        if (!strncmp(line, MPline, strlen(MPline)))
        {
            len = strlen(MPline);
            linePtr = line + len;
            read_FF_2048(PRIVGOLDEN.mp, linePtr, HFLEN_2048);
        }

        // Read MQ and process test vector
        if (!strncmp(line, MQline, strlen(MQline)))
        {
            len = strlen(MQline);
            linePtr = line + len;
            read_FF_2048(PRIVGOLDEN.mq, linePtr, HFLEN_2048);

            if (testSeed)
            {
                testSeed=0;

                // CSPRNG
                csprng RNG;

                // initialise strong RNG
                CREATE_CSPRNG(&RNG,&SEEDGOLDEN);

                PAILLIER_KEY_PAIR(&RNG, NULL, NULL, &PUB, &PRIV);
            }
            else
            {
                PAILLIER_KEY_PAIR(NULL, &PGOLDEN, &QGOLDEN, &PUB, &PRIV);
            }

            ff_2048_compare("PRIV.p",    "PRIVGOLDEN.p",    PRIV.p,    PRIVGOLDEN.p,    HFLEN_2048);
            ff_2048_compare("PRIV.q",    "PRIVGOLDEN.q",    PRIV.q,    PRIVGOLDEN.q,    HFLEN_2048);
            ff_2048_compare("PRIV.lp",   "PRIVGOLDEN.lp",   PRIV.lp,   PRIVGOLDEN.lp,   HFLEN_2048);
            ff_2048_compare("PRIV.mp",   "PRIVGOLDEN.mp",   PRIV.mp,   PRIVGOLDEN.mp,   HFLEN_2048);
            ff_2048_compare("PRIV.lq",   "PRIVGOLDEN.lq",   PRIV.lq,   PRIVGOLDEN.lq,   HFLEN_2048);
            ff_2048_compare("PRIV.mq",   "PRIVGOLDEN.mq",   PRIV.mq,   PRIVGOLDEN.mq,   HFLEN_2048);
            ff_2048_compare("PRIV.invp", "PRIVGOLDEN.invp", PRIV.invp, PRIVGOLDEN.invp, FFLEN_2048);
            ff_2048_compare("PRIV.p2",   "PRIVGOLDEN.p2",   PRIV.p2,   PRIVGOLDEN.p2,   FFLEN_2048);
            ff_2048_compare("PRIV.invq", "PRIVGOLDEN.invq", PRIV.invq, PRIVGOLDEN.invq, FFLEN_2048);
            ff_2048_compare("PRIV.q2",   "PRIVGOLDEN.q2",   PRIV.q2,   PRIVGOLDEN.q2,   FFLEN_2048);

            ff_4096_compare("PUB.n",  "PUBGOLDEN.n",  PUB.n,  PUBGOLDEN.n,  FFLEN_4096);
            ff_4096_compare("PUB.g",  "PUBGOLDEN.g",  PUB.g,  PUBGOLDEN.g,  FFLEN_4096);
            ff_4096_compare("PUB.n2", "PUBGOLDEN.n2", PUB.n2, PUBGOLDEN.n2, FFLEN_4096);

            // Clean keys for next test vector
            PAILLIER_PRIVATE_KEY_KILL(&PRIV);
            PAILLIER_PRIVATE_KEY_KILL(&PRIVGOLDEN);

            clean_public(&PUB);
            clean_public(&PUBGOLDEN);
        }
    }

    fclose(fp);

    printf("SUCCESS TEST PAILLIER KEYGEN PASSED\n");
    exit(EXIT_SUCCESS);
}
