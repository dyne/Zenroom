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


/* RSA Functions - see main program below */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>

#include "rsa.h"

#define ROUNDUP(a,b) ((a)-1)/(b)+1

/* general purpose hash function w=hash(p|n|x|y) */
static void hashit(octet *p,int n,octet *w)
{
    int i,c[4];
    hash sha;
    char hh[32];

    HASH_init(&sha);
    if (p!=NULL)
        for (i=0;i<p->len;i++) HASH_process(&sha,p->val[i]);
	if (n>=0)
    {
        c[0]=(n>>24)&0xff;
        c[1]=(n>>16)&0xff;
        c[2]=(n>>8)&0xff;
        c[3]=(n)&0xff;
		for (i=0;i<4;i++) HASH_process(&sha,c[i]);
    }

    HASH_hash(&sha,hh);

    OCT_empty(w);
    OCT_jbytes(w,hh,32);
    for (i=0;i<32;i++) hh[i]=0;
}

/* Initialise a Cryptographically Strong Random Number Generator from
   an octet of raw random data */
void RSA_CREATE_CSPRNG(csprng *RNG,octet *RAW)
{
    RAND_seed(RNG,RAW->len,RAW->val);
}

void RSA_KILL_CSPRNG(csprng *RNG)
{
    RAND_clean(RNG);
}

/* generate an RSA key pair */

void RSA_KEY_PAIR(csprng *RNG,sign32 e,rsa_private_key *PRIV,rsa_public_key *PUB)
{ /* IEEE1363 A16.11/A16.12 more or less */

    int hE,m,r,bytes,hbytes,words,err,res=0;
    BIG t[HFLEN],p1[HFLEN],q1[HFLEN];

	for (;;)
	{

		FF_random(PRIV->p,RNG,HFLEN);
		while (FF_lastbits(PRIV->p,2)!=3) FF_inc(PRIV->p,1,HFLEN);
		while (!FF_prime(PRIV->p,RNG,HFLEN))
			FF_inc(PRIV->p,4,HFLEN);

		FF_copy(p1,PRIV->p,HFLEN);
		FF_dec(p1,1,HFLEN);

		if (FF_cfactor(p1,e,HFLEN)) continue;
		break;
	}

	for (;;)
	{
		FF_random(PRIV->q,RNG,HFLEN);
		while (FF_lastbits(PRIV->q,2)!=3) FF_inc(PRIV->q,1,HFLEN);
		while (!FF_prime(PRIV->q,RNG,HFLEN))
			FF_inc(PRIV->q,4,HFLEN);

		FF_copy(q1,PRIV->q,HFLEN);
		FF_dec(q1,1,HFLEN);
		if (FF_cfactor(q1,e,HFLEN)) continue;

		break;
	}

	FF_mul(PUB->n,PRIV->p,PRIV->q,HFLEN);
	PUB->e=e;

	FF_copy(t,p1,HFLEN);
	FF_shr(t,HFLEN);
	FF_init(PRIV->dp,e,HFLEN);
	FF_invmodp(PRIV->dp,PRIV->dp,t,HFLEN);
	if (FF_parity(PRIV->dp)==0) FF_add(PRIV->dp,PRIV->dp,t,HFLEN);
	FF_norm(PRIV->dp,HFLEN);

	FF_copy(t,q1,HFLEN);
	FF_shr(t,HFLEN);
	FF_init(PRIV->dq,e,HFLEN);
	FF_invmodp(PRIV->dq,PRIV->dq,t,HFLEN);
	if (FF_parity(PRIV->dq)==0) FF_add(PRIV->dq,PRIV->dq,t,HFLEN);
	FF_norm(PRIV->dq,HFLEN);

	FF_invmodp(PRIV->c,PRIV->p,PRIV->q,HFLEN);

	return;
}

/* Mask Generation Function */

void MGF1(octet *z,int olen,octet *mask)
{
	char h[32];
    octet H={0,sizeof(h),h};
	int hlen=32;
    int counter,cthreshold;

    OCT_empty(mask);

    cthreshold=ROUNDUP(olen,hlen);

    for (counter=0;counter<cthreshold;counter++)
    {
        hashit(z,counter,&H);
        if (mask->len+hlen>olen) OCT_jbytes(mask,H.val,olen%hlen);
        else                     OCT_joctet(mask,&H);
    }
    OCT_clear(&H);
}

/* OAEP Message Encoding for Encryption */

int RSA_OAEP_ENCODE(octet *m,csprng *RNG,octet *p,octet *f)
{
    int i,slen,olen=RFS-1;
    int mlen=m->len;
    int hlen,seedlen;
    char dbmask[RFS],seed[32];
	octet DBMASK={0,sizeof(dbmask),dbmask};
	octet SEED={0,sizeof(seed),seed};

    hlen=seedlen=32;
    if (mlen>olen-hlen-seedlen-1) return 0;
    if (m==f) return 0;  /* must be distinct octets */

    hashit(p,-1,f);

    slen=olen-mlen-hlen-seedlen-1;

    OCT_jbyte(f,0,slen);
    OCT_jbyte(f,0x1,1);
    OCT_joctet(f,m);

    OCT_rand(&SEED,RNG,seedlen);

    MGF1(&SEED,olen-seedlen,&DBMASK);

    OCT_xor(&DBMASK,f);
    MGF1(&DBMASK,seedlen,f);

    OCT_xor(f,&SEED);

    OCT_joctet(f,&DBMASK);

	OCT_pad(f,RFS);
    OCT_clear(&SEED);
    OCT_clear(&DBMASK);

    return 1;
}

/* OAEP Message Decoding for Decryption */

int RSA_OAEP_DECODE(octet *p,octet *f)
{
    int comp,x,t;
    int i,k,olen=RFS-1;
    int hlen,seedlen;
    char dbmask[RFS],seed[32],chash[32];;
	octet DBMASK={0,sizeof(dbmask),dbmask};
	octet SEED={0,sizeof(seed),seed};
	octet CHASH={0,sizeof(chash),chash};

    seedlen=hlen=32;;
    if (olen<seedlen+hlen+1) return 0;
    if (!OCT_pad(f,olen+1)) return 0;
    hashit(p,-1,&CHASH);

    x=f->val[0];
    for (i=seedlen;i<olen;i++)
        DBMASK.val[i-seedlen]=f->val[i+1];
    DBMASK.len=olen-seedlen;

    MGF1(&DBMASK,seedlen,&SEED);
    for (i=0;i<seedlen;i++) SEED.val[i]^=f->val[i+1];
    MGF1(&SEED,olen-seedlen,f);
    OCT_xor(&DBMASK,f);

    comp=OCT_ncomp(&CHASH,&DBMASK,hlen);

    OCT_shl(&DBMASK,hlen);

    OCT_clear(&SEED);
    OCT_clear(&CHASH);

    for (k=0;;k++)
    {
        if (k>=DBMASK.len)
        {
            OCT_clear(&DBMASK);
            return 0;
        }
        if (DBMASK.val[k]!=0) break;
    }

    t=DBMASK.val[k];
    if (!comp || x!=0 || t!=0x01)
    {
        OCT_clear(&DBMASK);
        return 0;
    }

    OCT_shl(&DBMASK,k+1);
    OCT_copy(f,&DBMASK);
    OCT_clear(&DBMASK);

    return 1;
}

/* destroy the Private Key structure */
void RSA_PRIVATE_KEY_KILL(rsa_private_key *PRIV)
{
    FF_zero(PRIV->p,HFLEN);
	FF_zero(PRIV->q,HFLEN);
	FF_zero(PRIV->dp,HFLEN);
	FF_zero(PRIV->dq,HFLEN);
	FF_zero(PRIV->c,HFLEN);
}

/* RSA encryption with the public key */
void RSA_ENCRYPT(rsa_public_key *PUB,octet *F,octet *G)
{
	BIG f[FFLEN];
	FF_fromOctet(f,F,FFLEN);

    FF_power(f,f,PUB->e,PUB->n,FFLEN);

	FF_toOctet(G,f,FFLEN);
}

/* RSA decryption with the private key */
void RSA_DECRYPT(rsa_private_key *PRIV,octet *G,octet *F)
{
	BIG g[FFLEN],t[FFLEN],jp[HFLEN],jq[HFLEN];

	FF_fromOctet(g,G,FFLEN);

	FF_dmod(jp,g,PRIV->p,HFLEN);
	FF_dmod(jq,g,PRIV->q,HFLEN);

	FF_skpow(jp,jp,PRIV->dp,PRIV->p,HFLEN);
	FF_skpow(jq,jq,PRIV->dq,PRIV->q,HFLEN);


	FF_zero(g,FFLEN);
	FF_copy(g,jp,HFLEN);
	FF_mod(jp,PRIV->q,HFLEN);
	if (FF_comp(jp,jq,HFLEN)>0)
		FF_add(jq,jq,PRIV->q,HFLEN);
	FF_sub(jq,jq,jp,HFLEN);
	FF_norm(jq,HFLEN);

	FF_mul(t,PRIV->c,jq,HFLEN);
	FF_dmod(jq,t,PRIV->q,HFLEN);

	FF_mul(t,jq,PRIV->p,HFLEN);
	FF_add(g,t,g,FFLEN);
	FF_norm(g,FFLEN);

	FF_toOctet(F,g,FFLEN);

	return;
}

