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

void read_FF_4096(BIG_512_60 *x, char* string, int n)
{
    int len = strlen(string);
    char oct[len/2];
    octet OCT = {0, len/2, oct};

    read_OCTET(&OCT, string);
    FF_4096_fromOctet(x, &OCT, n);
}

int main(int argc, char** argv)
{
    if (argc != 2)
    {
        printf("usage: ./test_paillier_mult [path to test vector file]\n");
        exit(EXIT_FAILURE);
    }

    int len=0;
    FILE *fp=NULL;

    char line[LINE_LEN]= {0};
    char *linePtr=NULL;

    char ct[FS_4096]= {0};
    octet CT = {0,sizeof(ct),ct};

    int testNo=0;
    const char* TESTline = "TEST = ";

    PAILLIER_public_key PUB;
    const char* Nline = "N = ";

    char ct1golden[FS_4096]= {0};
    octet CT1GOLDEN = {0,sizeof(ct1golden),ct1golden};
    const char* CT1line = "CIPHERTEXT1 = ";

    char pt2golden[FS_2048]= {0};
    octet PT2GOLDEN = {0,sizeof(pt2golden),pt2golden};
    const char* PT2line = "PLAINTEXT2 = ";

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
        if (!strncmp(line,TESTline, strlen(TESTline)))
        {
            len = strlen(TESTline);
            linePtr = line + len;
            sscanf(linePtr,"%d\n",&testNo);
        }

        // Read N
        if (!strncmp(line,Nline, strlen(Nline)))
        {
            len = strlen(Nline);
            linePtr = line + len;
            read_FF_4096(PUB.n, linePtr, HFLEN_4096);

            FF_4096_sqr(PUB.n2, PUB.n, HFLEN_4096);
            FF_4096_norm(PUB.n2, FFLEN_4096);
        }

        // Read CIPHERTEXT1
        if (!strncmp(line,CT1line, strlen(CT1line)))
        {
            len = strlen(CT1line);
            linePtr = line + len;
            read_OCTET(&CT1GOLDEN,linePtr);
        }

        // Read PLAINTEXT2
        if (!strncmp(line,PT2line, strlen(PT2line)))
        {
            len = strlen(PT2line);
            linePtr = line + len;
            read_OCTET(&PT2GOLDEN,linePtr);
        }

        // Read CIPHERTEXT and process test vector
        if (!strncmp(line,CTline, strlen(CTline)))
        {
            len = strlen(CTline);
            linePtr = line + len;
            read_OCTET(&CTGOLDEN,linePtr);

            PAILLIER_MULT(&PUB, &CT1GOLDEN, &PT2GOLDEN, &CT);

            if(!OCT_comp(&CTGOLDEN,&CT))
            {
                fprintf(stderr, "FAILURE Test %d\n", testNo);
                fclose(fp);
                exit(EXIT_FAILURE);
            }
        }
    }

    fclose(fp);

    printf("SUCCESS TEST PAILLIER MULTIPLICATION PASSED\n");
    exit(EXIT_SUCCESS);
}
