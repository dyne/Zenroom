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

#include "rsa_support.h"

#define ROUNDUP(a,b) ((a)-1)/(b)+1

/* general purpose hash function w=hash(p|n|x|y) */
int hashit(int sha,octet *p,int n,octet *w)
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

    if (p!=NULL) for (i=0; i<p->len; i++)
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
    if (n>=0)
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
    OCT_jbytes(w,hh,hlen);
    for (i=0; i<hlen; i++) hh[i]=0;

    return hlen;
}

/* Mask Generation Function */

static void MGF1(int sha,octet *z,int olen,octet *mask)
{
    char h[64];
    octet H= {0,sizeof(h),h};
    int hlen=sha;
    int counter,cthreshold;

    OCT_empty(mask);

    cthreshold=ROUNDUP(olen,hlen);
    for (counter=0; counter<cthreshold; counter++)
    {
        hashit(sha,z,counter,&H);
        if (mask->len+hlen>olen) OCT_jbytes(mask,H.val,olen%hlen);
        else                     OCT_joctet(mask,&H);
    }
    OCT_clear(&H);
}

/* SHAXXX identifier strings */
const unsigned char SHA256ID[]= {0x30,0x31,0x30,0x0d,0x06,0x09,0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x02,0x01,0x05,0x00,0x04,0x20};
const unsigned char SHA384ID[]= {0x30,0x41,0x30,0x0d,0x06,0x09,0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x02,0x02,0x05,0x00,0x04,0x30};
const unsigned char SHA512ID[]= {0x30,0x51,0x30,0x0d,0x06,0x09,0x60,0x86,0x48,0x01,0x65,0x03,0x04,0x02,0x03,0x05,0x00,0x04,0x40};

/* PKCS 1.5 padding of a message to be signed */

int PKCS15(int sha,octet *m,octet *w)
{
    int olen=w->max;
    int hlen=sha;
    int idlen=19;
    char h[64];
    octet H= {0,sizeof(h),h};

    if (olen<idlen+hlen+10) return 1;
    hashit(sha,m,-1,&H);

    OCT_empty(w);
    OCT_jbyte(w,0x00,1);
    OCT_jbyte(w,0x01,1);
    OCT_jbyte(w,0xff,olen-idlen-hlen-3);
    OCT_jbyte(w,0x00,1);

    if (hlen==32) OCT_jbytes(w,(char *)SHA256ID,idlen);
    if (hlen==48) OCT_jbytes(w,(char *)SHA384ID,idlen);
    if (hlen==64) OCT_jbytes(w,(char *)SHA512ID,idlen);

    OCT_joctet(w,&H);

    return 0;
}

/* OAEP Message Encoding for Encryption */

int OAEP_ENCODE(int sha,octet *m,csprng *RNG,octet *p,octet *f)
{
    int slen,olen=f->max-1;
    int mlen=m->len;
    int hlen,seedlen;
    char dbmask[MAX_RSA_BYTES],seed[64];
    octet DBMASK= {0,sizeof(dbmask),dbmask};
    octet SEED= {0,sizeof(seed),seed};

    hlen=seedlen=sha;
    if (mlen>olen-hlen-seedlen-1) return 1;
    if (m==f) return 1;  /* must be distinct octets */

    hashit(sha,p,-1,f);

    slen=olen-mlen-hlen-seedlen-1;

    OCT_jbyte(f,0,slen);
    OCT_jbyte(f,0x1,1);
    OCT_joctet(f,m);

    OCT_rand(&SEED,RNG,seedlen);

    MGF1(sha,&SEED,olen-seedlen,&DBMASK);

    OCT_xor(&DBMASK,f);
    MGF1(sha,&DBMASK,seedlen,f);

    OCT_xor(f,&SEED);

    OCT_joctet(f,&DBMASK);

    OCT_pad(f,f->max);
    OCT_clear(&SEED);
    OCT_clear(&DBMASK);

    return 0;
}

/* OAEP Message Decoding for Decryption */

int OAEP_DECODE(int sha,octet *p,octet *f)
{
    int comp,x,t;
    int i,k,olen=f->max-1;
    int hlen,seedlen;
    char dbmask[MAX_RSA_BYTES],seed[64],chash[64];
    octet DBMASK= {0,sizeof(dbmask),dbmask};
    octet SEED= {0,sizeof(seed),seed};
    octet CHASH= {0,sizeof(chash),chash};

    seedlen=hlen=sha;
    if (olen<seedlen+hlen+1) return 1;
    if (!OCT_pad(f,olen+1)) return 1;
    hashit(sha,p,-1,&CHASH);

    x=f->val[0];
    for (i=seedlen; i<olen; i++)
        DBMASK.val[i-seedlen]=f->val[i+1];
    DBMASK.len=olen-seedlen;

    MGF1(sha,&DBMASK,seedlen,&SEED);
    for (i=0; i<seedlen; i++) SEED.val[i]^=f->val[i+1];
    MGF1(sha,&SEED,olen-seedlen,f);
    OCT_xor(&DBMASK,f);

    comp=OCT_ncomp(&CHASH,&DBMASK,hlen);

    OCT_shl(&DBMASK,hlen);

    OCT_clear(&SEED);
    OCT_clear(&CHASH);

    for (k=0;; k++)
    {
        if (k>=DBMASK.len)
        {
            OCT_clear(&DBMASK);
            return 1;
        }
        if (DBMASK.val[k]!=0) break;
    }

    t=DBMASK.val[k];
    if (!comp || x!=0 || t!=0x01)
    {
        OCT_clear(&DBMASK);
        return 1;
    }

    OCT_shl(&DBMASK,k+1);
    OCT_copy(f,&DBMASK);
    OCT_clear(&DBMASK);

    return 0;
}
