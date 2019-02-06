/**
 * @file utils.c
 * @author Mike Scott
 * @author Kealan McCusker
 * @date 28th July 2016
 * @brief AMCL Support functions for M-Pin servers
 *
 * LICENSE
 *
 * Licensed to the Apache Software Foundation (ASF) under one
 * or more contributor license agreements.  See the NOTICE file
 * distributed with this work for additional information
 * regarding copyright ownership.  The ASF licenses this file
 * to you under the Apache License, Version 2.0 (the
 * "License"); you may not use this file except in compliance
 * with the License.  You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

/* AMCL Support functions for M-Pin servers */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "amcl.h"
#include "utils.h"

/* Decode hex value */
void amcl_hex2bin(const char *src, char *dst, int src_len)
{
    int i;
    char v,c;
    for (i = 0; i < src_len/2; i++)
    {
        c = src[2*i];
        if (c >= '0' && c <= '9')
        {
            v = c - '0';
        }
        else if (c >= 'A' && c <= 'F')
        {
            v = c - 'A' + 10;
        }
        else if (c >= 'a' && c <= 'f')
        {
            v = c - 'a' + 10;
        }
        else
        {
            v = 0;
        }
        v <<= 4;
        c = src[2*i + 1];
        if (c >= '0' && c <= '9')
        {
            v += c - '0';
        }
        else if (c >= 'A' && c <= 'F')
        {
            v += c - 'A' + 10;
        }
        else if (c >= 'a' && c <= 'f')
        {
            v += c - 'a' + 10;
        }
        else
        {
            v = 0;
        }
        dst[i] = v;
    }
}

/* Encode binary string */
void amcl_bin2hex(char *src, char *dst, int src_len)
{
    int i;
    for (i = 0; i < src_len; i++)
    {
        sprintf(&dst[i*2],"%02x", (unsigned char) src[i]);
    }
}

/* Print encoded binary string in hex */
void amcl_print_hex(char *src, int src_len)
{
    int i;
    for (i = 0; i < src_len; i++)
    {
        printf("%02x", (unsigned char) src[i]);
    }
    printf("\n");
}

/* Generates a random six digit one time password */
int generateOTP(csprng* RNG)
{
    int OTP=0;

    int i = 0;
    int val = 0;
    char byte[6] = {0};
    int mult=1;

    // Generate random 6 digit random value
    for (i=0; i<6; i++)
    {
        byte[i]=RAND_byte(RNG);
        val = byte[i];
        OTP = ((abs(val) % 10) * mult) + OTP;
        mult = mult * 10;
    }

    return OTP;
}

/* Generate a random Octet */
void generateRandom(csprng *RNG,octet *randomValue)
{
    int i;
    for (i=0; i<randomValue->len; i++)
        randomValue->val[i]=RAND_byte(RNG);
}
