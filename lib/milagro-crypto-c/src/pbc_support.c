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

/* Symmetric crypto support functions Functions  */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "pbc_support.h"

/* general purpose hash function w=hash(p|n|x|y) */
void mhashit(int sha,int n,octet *x,octet *w)
{
    int i,c[4],hlen;
    hash256 sha256;
    hash512 sha512;
    char hh[64];

    switch (sha)
    {
    case SHA256:
        HASH256_init(&sha256);
        break;
    case SHA384:
        HASH384_init(&sha512);
        break;
    case SHA512:
        HASH512_init(&sha512);
        break;
    }

    hlen=sha;

    if (n>0)
    {
        c[0]=(n>>24)&0xff;
        c[1]=(n>>16)&0xff;
        c[2]=(n>>8)&0xff;
        c[3]=(n)&0xff;
        for (i=0; i<4; i++)
        {
            switch(sha)
            {
            case SHA256:
                HASH256_process(&sha256,c[i]);
                break;
            case SHA384:
                HASH384_process(&sha512,c[i]);
                break;
            case SHA512:
                HASH512_process(&sha512,c[i]);
                break;
            }
        }
    }

    if (x!=NULL) for (i=0; i<x->len; i++)
        {
            switch(sha)
            {
            case SHA256:
                HASH256_process(&sha256,x->val[i]);

                break;
            case SHA384:
                HASH384_process(&sha512,x->val[i]);
                break;
            case SHA512:
                HASH512_process(&sha512,x->val[i]);
                break;
            }
        }

    for (i=0; i<hlen; i++) hh[i]=0;
    switch (sha)
    {
    case SHA256:
        HASH256_hash(&sha256,hh);
        break;
    case SHA384:
        HASH384_hash(&sha512,hh);
        break;
    case SHA512:
        HASH512_hash(&sha512,hh);
        break;
    }

    OCT_empty(w);

    if (hlen>=w->max)
        OCT_jbytes(w,hh,w->max);
    else
    {
        OCT_jbyte(w,0,w->max-hlen);
        OCT_jbytes(w,hh,hlen);
    }
}

/* Hash the M-Pin transcript - new */

void HASH_ALL(int sha,octet *HID,octet *xID,octet *xCID,octet *SEC,octet *Y,octet *R,octet *W,octet *H)
{
    char t[1284];   // assumes max modulus of 1024-bits
    octet T= {0,sizeof(t),t};

    OCT_joctet(&T,HID);
    if (xCID!=NULL) OCT_joctet(&T,xCID);
    else OCT_joctet(&T,xID);
    OCT_joctet(&T,SEC);
    OCT_joctet(&T,Y);
    OCT_joctet(&T,R);
    OCT_joctet(&T,W);

    mhashit(sha,0,&T,H);
}

void HASH_ID(int sha,octet *ID,octet *HID)
{
    mhashit(sha,0,ID,HID);
}

/* AES-GCM Encryption of octets, K is key, H is header,
   P is plaintext, C is ciphertext, T is authentication tag */
void AES_GCM_ENCRYPT(octet *K,octet *IV,octet *H,octet *P,octet *C,octet *T)
{
    gcm g;
    GCM_init(&g,K->len,K->val,IV->len,IV->val);
    GCM_add_header(&g,H->val,H->len);
    GCM_add_plain(&g,C->val,P->val,P->len);
    C->len=P->len;
    GCM_finish(&g,T->val);
    T->len=16;
}

/* AES-GCM Decryption of octets, K is key, H is header,
   P is plaintext, C is ciphertext, T is authentication tag */
void AES_GCM_DECRYPT(octet *K,octet *IV,octet *H,octet *C,octet *P,octet *T)
{
    gcm g;
    GCM_init(&g,K->len,K->val,IV->len,IV->val);
    GCM_add_header(&g,H->val,H->len);
    GCM_add_cipher(&g,P->val,C->val,C->len);
    P->len=C->len;
    GCM_finish(&g,T->val);
    T->len=16;
}

