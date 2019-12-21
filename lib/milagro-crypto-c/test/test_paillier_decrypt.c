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
    char *linePtr=NULL;

    char pt[FS_2048]= {0};
    octet PT = {0,sizeof(pt),pt};

    int testNo=0;
    const char* TESTline = "TEST = ";

    PAILLIER_private_key PRIV;
    const char* Pline = "P = ";
    const char* Qline = "Q = ";
    const char* LPline = "LP = ";
    const char* MPline = "MP = ";
    const char* LQline = "LQ = ";
    const char* MQline = "MQ = ";

    char ptgolden[FS_2048]= {0};
    octet PTGOLDEN = {0,sizeof(ptgolden),ptgolden};
    const char* PTline = "PLAINTEXT = ";

    char ctgolden[FS_4096]= {0};
    octet CTGOLDEN = {0,sizeof(ctgolden),ctgolden};
    const char* CTline = "CIPHERTEXT = ";

    fp = fopen(argv[1], "r");
    if (fp == NULL)
    {
        printf("ERROR opening test vector file\n");
        exit(EXIT_FAILURE);
    }

    while (fgets(line, LINE_LEN, fp) != NULL)
    {
        // Read TEST Number
        if (!strncmp(line, TESTline, strlen(TESTline)))
        {
            len = strlen(TESTline);
            linePtr = line + len;
            sscanf(linePtr,"%d\n",&testNo);
        }

        // Read P
        if (!strncmp(line, Pline, strlen(Pline)))
        {
            len = strlen(Pline);
            linePtr = line + len;
            read_FF_2048(PRIV.p, linePtr, HFLEN_2048);

            FF_2048_zero(PRIV.p2, FFLEN_2048);
            FF_2048_sqr(PRIV.p2, PRIV.p, HFLEN_2048);
            FF_2048_norm(PRIV.p2, FFLEN_2048);

            FF_2048_zero(PRIV.invp, FFLEN_2048);
            FF_2048_invmod2m(PRIV.invp, PRIV.p, HFLEN_2048);
        }

        // Read Q
        if (!strncmp(line, Qline, strlen(Qline)))
        {
            len = strlen(Qline);
            linePtr = line + len;
            read_FF_2048(PRIV.q, linePtr, HFLEN_2048);

            FF_2048_zero(PRIV.q2, FFLEN_2048);
            FF_2048_sqr(PRIV.q2, PRIV.q, HFLEN_2048);
            FF_2048_norm(PRIV.q2, FFLEN_2048);

            FF_2048_zero(PRIV.invq, FFLEN_2048);
            FF_2048_invmod2m(PRIV.invq, PRIV.q, HFLEN_2048);
        }

        // Read LP
        if (!strncmp(line, LPline, strlen(LPline)))
        {
            len = strlen(LPline);
            linePtr = line + len;
            read_FF_2048(PRIV.lp, linePtr, HFLEN_2048);
        }

        // Read LQ
        if (!strncmp(line, LQline, strlen(LQline)))
        {
            len = strlen(LQline);
            linePtr = line + len;
            read_FF_2048(PRIV.lq, linePtr, HFLEN_2048);
        }

        // Read MP
        if (!strncmp(line, MPline, strlen(MPline)))
        {
            len = strlen(MPline);
            linePtr = line + len;
            read_FF_2048(PRIV.mp, linePtr, HFLEN_2048);
        }

        // Read MQ
        if (!strncmp(line, MQline, strlen(MQline)))
        {
            len = strlen(MQline);
            linePtr = line + len;
            read_FF_2048(PRIV.mq, linePtr, HFLEN_2048);
        }

        // Read CIPHERTEXT
        if (!strncmp(line, CTline, strlen(CTline)))
        {
            len = strlen(CTline);
            linePtr = line + len;
            read_OCTET(&CTGOLDEN,linePtr);
        }

        // Read PLAINTEXT and process test vector
        if (!strncmp(line, PTline, strlen(PTline)))
        {
            len = strlen(PTline);
            linePtr = line + len;
            read_OCTET(&PTGOLDEN,linePtr);

            PAILLIER_DECRYPT(&PRIV, &CTGOLDEN, &PT);

            if(!OCT_comp(&PTGOLDEN,&PT))
            {
                fprintf(stderr, "FAILURE Test %d\n", testNo);
                fclose(fp);
                exit(EXIT_FAILURE);
            }
        }
    }

    fclose(fp);

    printf("SUCCESS TEST PAILLIER DECRYPTION PASSED\n");
    exit(EXIT_SUCCESS);
}
