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
#include <time.h>

#include "ecdh_support.h"

#define ROUNDUP(a,b) ((a)-1)/(b)+1

/* general purpose hash function w=hash(p|n|x|y) */
/* pad or truncate ouput to length pad if pad!=0 */
void ehashit(int sha,octet *p,int n,octet *x,octet *w,int pad)
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

    for (i=0; i<p->len; i++)
    {
        switch(sha)
        {
        case SHA256:
            HASH256_process(&sha256,p->val[i]);
            break;
        case SHA384:
            HASH384_process(&sha512,p->val[i]);
            break;
        case SHA512:
            HASH512_process(&sha512,p->val[i]);
            break;
        }
    }
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
    if (!pad)
        OCT_jbytes(w,hh,hlen);
    else
    {
        if (pad<=hlen)
            OCT_jbytes(w,hh,pad);
        else
        {
            OCT_jbyte(w,0,pad-hlen);
            OCT_jbytes(w,hh,hlen);

//            OCT_jbytes(w,hh,hlen);
//            OCT_jbyte(w,0,pad-hlen);
        }
    }
    return;
}

/* Hash octet p to octet w */
void HASH(int sha,octet *p,octet *w)
{
    ehashit(sha,p,-1,NULL,w,0);
}

/* Calculate HMAC of m using key k. HMAC is tag of length olen */
int AMCL_(HMAC)(int sha,octet *m,octet *k,int olen,octet *tag)
{
    /* Input is from an octet m        *
     * olen is requested output length in bytes. k is the key  *
     * The output is the calculated tag */
    int hlen,b;
    char h[128],k0[128];
    octet H= {0,sizeof(h),h};
    octet K0= {0,sizeof(k0),k0};

    hlen=sha;
    if (hlen>32) b=128;
    else b=64;

    if (olen<4 /*|| olen>hlen*/) return 0;

    if (k->len > b) ehashit(sha,k,-1,NULL,&K0,0);
    else            OCT_copy(&K0,k);

    OCT_jbyte(&K0,0,b-K0.len);

    OCT_xorbyte(&K0,0x36);

    ehashit(sha,&K0,-1,m,&H,0);

    OCT_xorbyte(&K0,0x6a);   /* 0x6a = 0x36 ^ 0x5c */
    ehashit(sha,&K0,-1,&H,&H,olen);

    OCT_empty(tag);

    OCT_jbytes(tag,H.val,olen);

    return 1;
}

void KDF2(int sha,octet *z,octet *p,int olen,octet *key)
{
    /* NOTE: the parameter olen is the length of the output k in bytes */
    char h[64];
    octet H= {0,sizeof(h),h};
    int counter,cthreshold;
    int hlen=sha;

    OCT_empty(key);

    cthreshold=ROUNDUP(olen,hlen);

    for (counter=1; counter<=cthreshold; counter++)
    {
        ehashit(sha,z,counter,p,&H,0);
        if (key->len+hlen>olen)  OCT_jbytes(key,H.val,olen%hlen);
        else                     OCT_joctet(key,&H);
    }

}

/* Password based Key Derivation Function */
/* Input password p, salt s, and repeat count */
/* Output key of length olen */
void PBKDF2(int sha,octet *p,octet *s,int rep,int olen,octet *key)
{
    int i,j,len,d=ROUNDUP(olen,sha);
    char f[64],u[64];
    octet F= {0,sizeof(f),f};
    octet U= {0,sizeof(u),u};
    OCT_empty(key);

    for (i=1; i<=d; i++)
    {
        len=s->len;
        OCT_jint(s,i,4);

        AMCL_(HMAC)(sha,s,p,sha,&F);

        s->len=len;
        OCT_copy(&U,&F);
        for (j=2; j<=rep; j++)
        {
            AMCL_(HMAC)(sha,&U,p,sha,&U);
            OCT_xor(&F,&U);
        }

        OCT_joctet(key,&F);
    }

    OCT_chop(key,NULL,olen);
}

/* AES encryption/decryption. Encrypt byte array M using key K and returns ciphertext */
void AES_CBC_IV0_ENCRYPT(octet *k,octet *m,octet *c)
{
    /* AES CBC encryption, with Null IV and key k */
    /* Input is from an octet string m, output is to an octet string c */
    /* Input is padded as necessary to make up a full final block */
    amcl_aes a;
    int fin;
    int i,j,ipt,opt;
    char buff[16];
    int padlen;

    OCT_clear(c);
    if (m->len==0) return;
    AES_init(&a,CBC,k->len,k->val,NULL);

    ipt=opt=0;
    fin=0;
    for(;;)
    {
        for (i=0; i<16; i++)
        {
            if (ipt<m->len) buff[i]=m->val[ipt++];
            else
            {
                fin=1;
                break;
            }
        }
        if (fin) break;
        AMCL_(AES_encrypt)(&a,buff);
        for (i=0; i<16; i++)
            if (opt<c->max) c->val[opt++]=buff[i];
    }

    /* last block, filled up to i-th index */

    padlen=16-i;
    for (j=i; j<16; j++) buff[j]=padlen;
    AMCL_(AES_encrypt)(&a,buff);
    for (i=0; i<16; i++)
        if (opt<c->max) c->val[opt++]=buff[i];
    AES_end(&a);
    c->len=opt;
}

/* decrypts and returns TRUE if all consistent, else returns FALSE */
int AES_CBC_IV0_DECRYPT(octet *k,octet *c,octet *m)
{
    /* padding is removed */
    amcl_aes a;
    int i,ipt,opt,ch;
    char buff[16];
    int fin,bad;
    int padlen;
    ipt=opt=0;

    OCT_clear(m);
    if (c->len==0) return 1;
    ch=c->val[ipt++];

    AES_init(&a,CBC,k->len,k->val,NULL);
    fin=0;

    for(;;)
    {
        for (i=0; i<16; i++)
        {
            buff[i]=ch;
            if (ipt>=c->len)
            {
                fin=1;
                break;
            }
            else ch=c->val[ipt++];
        }
        AMCL_(AES_decrypt)(&a,buff);
        if (fin) break;
        for (i=0; i<16; i++)
            if (opt<m->max) m->val[opt++]=buff[i];
    }
    AES_end(&a);
    bad=0;
    padlen=buff[15];
    if (i!=15 || padlen<1 || padlen>16) bad=1;
    if (padlen>=2 && padlen<=16)
        for (i=16-padlen; i<16; i++) if (buff[i]!=padlen) bad=1;

    if (!bad) for (i=0; i<16-padlen; i++)
            if (opt<m->max) m->val[opt++]=buff[i];

    m->len=opt;
    if (bad) return 0;
    return 1;
}
