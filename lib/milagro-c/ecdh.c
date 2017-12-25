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

/* ECDH/ECIES/ECDSA Functions - see main program below */

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>

#include "ecdh.h"

#define ROUNDUP(a,b) ((a)-1)/(b)+1

/* general purpose hash function w=hash(p|n|x|y) */
static void hashit(octet *p,int n,octet *x,octet *y,octet *w)
{
    int i,c[4];
    hash sha;
    char hh[32];

    HASH_init(&sha);
    if (p!=NULL)
        for (i=0;i<p->len;i++) HASH_process(&sha,p->val[i]);
	if (n>0)
    {
        c[0]=(n>>24)&0xff;
        c[1]=(n>>16)&0xff;
        c[2]=(n>>8)&0xff;
        c[3]=(n)&0xff;
		for (i=0;i<4;i++) HASH_process(&sha,c[i]);
    }
    if (x!=NULL)
        for (i=0;i<x->len;i++) HASH_process(&sha,x->val[i]);
    if (y!=NULL)
        for (i=0;i<y->len;i++) HASH_process(&sha,y->val[i]);


    HASH_hash(&sha,hh);

    OCT_empty(w);
    OCT_jbytes(w,hh,32);
    for (i=0;i<32;i++) hh[i]=0;
}

/* Hash octet p to octet w */
void ECP_HASH(octet *p,octet *w)
{
	hashit(p,-1,NULL,NULL,w);
}

/* Initialise a Cryptographically Strong Random Number Generator from
   an octet of raw random data */
void ECP_CREATE_CSPRNG(csprng *RNG,octet *RAW)
{
    RAND_seed(RNG,RAW->len,RAW->val);
}

void ECP_KILL_CSPRNG(csprng *RNG)
{
    RAND_clean(RNG);
}

/* Calculate HMAC of m using key k. HMAC is tag of length olen */
int ECP_HMAC(octet *m,octet *k,int olen,octet *tag)
{
/* Input is from an octet m        *
 * olen is requested output length in bytes. k is the key  *
 * The output is the calculated tag */
    int hlen,b;
	char h[32],k0[64];
    octet H={0,sizeof(h),h};
	octet K0={0,sizeof(k0),k0};

    hlen=32; b=64;
    if (olen<4 || olen>hlen) return 0;

    if (k->len > b) hashit(k,-1,NULL,NULL,&K0);
    else            OCT_copy(&K0,k);

    OCT_jbyte(&K0,0,b-K0.len);

    OCT_xorbyte(&K0,0x36);

    hashit(&K0,-1,m,NULL,&H);

    OCT_xorbyte(&K0,0x6a);   /* 0x6a = 0x36 ^ 0x5c */
    hashit(&K0,-1,&H,NULL,&H);

    OCT_empty(tag);
    OCT_jbytes(tag,H.val,olen);

    return 1;
}

/* Key Derivation Functions */
/* Input octet z */
/* Output key of length olen */
/*
void KDF1(octet *z,int olen,octet *key)
{
    char h[32];
	octet H={0,sizeof(h),h};
    int counter,cthreshold;
    int hlen=32;

    OCT_empty(key);

    cthreshold=ROUNDUP(olen,hlen);

    for (counter=0;counter<cthreshold;counter++)
    {
        hashit(z,counter,NULL,NULL,&H);
        if (key->len+hlen>olen) OCT_jbytes(key,H.val,olen%hlen);
        else                    OCT_joctet(key,&H);
    }
}
*/
void ECP_KDF2(octet *z,octet *p,int olen,octet *key)
{
/* NOTE: the parameter olen is the length of the output k in bytes */
    char h[32];
	octet H={0,sizeof(h),h};
    int counter,cthreshold;
    int hlen=32;

    OCT_empty(key);

    cthreshold=ROUNDUP(olen,hlen);

    for (counter=1;counter<=cthreshold;counter++)
    {
        hashit(z,counter,p,NULL,&H);
        if (key->len+hlen>olen)  OCT_jbytes(key,H.val,olen%hlen);
        else                     OCT_joctet(key,&H);
    }
}

/* Password based Key Derivation Function */
/* Input password p, salt s, and repeat count */
/* Output key of length olen */
void ECP_PBKDF2(octet *p,octet *s,int rep,int olen,octet *key)
{
	int i,j,len,d=ROUNDUP(olen,32);
	char f[EFS],u[EFS];
	octet F={0,sizeof(f),f};
	octet U={0,sizeof(u),u};
	OCT_empty(key);

	for (i=1;i<=d;i++)
	{
		len=s->len;
		OCT_jint(s,i,4);
		ECP_HMAC(s,p,EFS,&F);
		s->len=len;
		OCT_copy(&U,&F);
		for (j=2;j<=rep;j++)
		{
			ECP_HMAC(&U,p,EFS,&U);
			OCT_xor(&F,&U);
		}

		OCT_joctet(key,&F);
	}
	OCT_chop(key,NULL,olen);
}

/* AES encryption/decryption. Encrypt byte array M using key K and returns ciphertext */
void ECP_AES_CBC_IV0_ENCRYPT(octet *k,octet *m,octet *c)
{ /* AES CBC encryption, with Null IV and key k */
  /* Input is from an octet string m, output is to an octet string c */
  /* Input is padded as necessary to make up a full final block */
    aes a;
	int fin;
    int i,j,ipt,opt;
    char buff[16];
    int padlen;

	OCT_clear(c);
	if (m->len==0) return;
    AES_init(&a,CBC,k->val,NULL);

    ipt=opt=0;
    fin=0;
    for(;;)
    {
        for (i=0;i<16;i++)
        {
            if (ipt<m->len) buff[i]=m->val[ipt++];
            else {fin=1; break;}
        }
        if (fin) break;
        AES_encrypt(&a,buff);
        for (i=0;i<16;i++)
            if (opt<c->max) c->val[opt++]=buff[i];
    }

/* last block, filled up to i-th index */

    padlen=16-i;
    for (j=i;j<16;j++) buff[j]=padlen;
    AES_encrypt(&a,buff);
    for (i=0;i<16;i++)
        if (opt<c->max) c->val[opt++]=buff[i];
    AES_end(&a);
    c->len=opt;
}

/* decrypts and returns TRUE if all consistent, else returns FALSE */
int ECP_AES_CBC_IV0_DECRYPT(octet *k,octet *c,octet *m)
{ /* padding is removed */
    aes a;
    int i,ipt,opt,ch;
    char buff[16];
    int fin,bad;
    int padlen;
    ipt=opt=0;

    OCT_clear(m);
    if (c->len==0) return 1;
    ch=c->val[ipt++];

    AES_init(&a,CBC,k->val,NULL);
    fin=0;

    for(;;)
    {
        for (i=0;i<16;i++)
        {
            buff[i]=ch;
            if (ipt>=c->len) {fin=1; break;}
            else ch=c->val[ipt++];
        }
        AES_decrypt(&a,buff);
        if (fin) break;
        for (i=0;i<16;i++)
            if (opt<m->max) m->val[opt++]=buff[i];
    }
    AES_end(&a);
    bad=0;
    padlen=buff[15];
    if (i!=15 || padlen<1 || padlen>16) bad=1;
    if (padlen>=2 && padlen<=16)
        for (i=16-padlen;i<16;i++) if (buff[i]!=padlen) bad=1;

    if (!bad) for (i=0;i<16-padlen;i++)
        if (opt<m->max) m->val[opt++]=buff[i];

    m->len=opt;
    if (bad) return 0;
    return 1;
}

/* Calculate a public/private EC GF(p) key pair. W=S.G mod EC(p),
 * where S is the secret key and W is the public key
 * and G is fixed generator.
 * If RNG is NULL then the private key is provided externally in S
 * otherwise it is generated randomly internally */
int ECP_KEY_PAIR_GENERATE(csprng *RNG,octet* S,octet *W)
{
    BIG r,gx,gy,s;
    ECP G;
    int res=0;
	BIG_rcopy(gx,CURVE_Gx);

#if CURVETYPE!=MONTGOMERY
	BIG_rcopy(gy,CURVE_Gy);
    ECP_set(&G,gx,gy);
#else
    ECP_set(&G,gx);
#endif

	BIG_rcopy(r,CURVE_Order);
    if (RNG!=NULL)
		BIG_randomnum(s,r,RNG);
    else
	{
		BIG_fromBytes(s,S->val);
		BIG_mod(s,r);
	}

    ECP_mul(&G,s);
#if CURVETYPE!=MONTGOMERY
    ECP_get(gx,gy,&G);
#else
    ECP_get(gx,&G);
#endif
    if (RNG!=NULL)
	{
		S->len=EGS;
		BIG_toBytes(S->val,s);
	}
#if CURVETYPE!=MONTGOMERY
	W->len=2*EFS+1;	W->val[0]=4;
	BIG_toBytes(&(W->val[1]),gx);
	BIG_toBytes(&(W->val[EFS+1]),gy);
#else
	W->len=EFS+1;	W->val[0]=2;
	BIG_toBytes(&(W->val[1]),gx);
#endif

    return res;
}

/* validate public key. Set full=true for fuller check */
int ECP_PUBLIC_KEY_VALIDATE(int full,octet *W)
{
    BIG q,r,wx,wy;
    ECP WP;
    int valid;
    int res=0;

	BIG_rcopy(q,Modulus);
	BIG_rcopy(r,CURVE_Order);

	BIG_fromBytes(wx,&(W->val[1]));
    if (BIG_comp(wx,q)>=0) res=ECDH_INVALID_PUBLIC_KEY;
#if CURVETYPE!=MONTGOMERY
	BIG_fromBytes(wy,&(W->val[EFS+1]));
	if (BIG_comp(wy,q)>=0) res=ECDH_INVALID_PUBLIC_KEY;
#endif
    if (res==0)
    {
#if CURVETYPE!=MONTGOMERY
        valid=ECP_set(&WP,wx,wy);
#else
	    valid=ECP_set(&WP,wx);
#endif
        if (!valid || ECP_isinf(&WP)) res=ECDH_INVALID_PUBLIC_KEY;
        if (res==0 && full)
        {
            ECP_mul(&WP,r);
            if (!ECP_isinf(&WP)) res=ECDH_INVALID_PUBLIC_KEY;
        }
    }

    return res;
}

/* IEEE-1363 Diffie-Hellman online calculation Z=S.WD */
int ECP_SVDP_DH(octet *S,octet *WD,octet *Z)
{
    BIG r,s,wx,wy;
    int valid;
    ECP W;
    int res=0;

	BIG_fromBytes(s,S->val);

	BIG_fromBytes(wx,&(WD->val[1]));
#if CURVETYPE!=MONTGOMERY
	BIG_fromBytes(wy,&(WD->val[EFS+1]));
	valid=ECP_set(&W,wx,wy);
#else
	valid=ECP_set(&W,wx);
#endif
	if (!valid) res=ECDH_ERROR;
	if (res==0)
	{
		BIG_rcopy(r,CURVE_Order);
		BIG_mod(s,r);

	    ECP_mul(&W,s);
        if (ECP_isinf(&W)) res=ECDH_ERROR;
        else
        {
#if CURVETYPE!=MONTGOMERY
            ECP_get(wx,wx,&W);
#else
	        ECP_get(wx,&W);
#endif
			Z->len=32;
			BIG_toBytes(Z->val,wx);
        }
    }
    return res;
}

#if CURVETYPE!=MONTGOMERY

/* IEEE ECDSA Signature, C and D are signature on F using private key S */
int ECP_SP_DSA(csprng *RNG,octet *S,octet *F,octet *C,octet *D)
{
	char h[32];
	octet H={0,sizeof(h),h};

    BIG gx,gy,r,s,f,c,d,u,vx;
    ECP G,V;

	hashit(F,-1,NULL,NULL,&H);

	BIG_rcopy(gx,CURVE_Gx);
	BIG_rcopy(gy,CURVE_Gy);
	BIG_rcopy(r,CURVE_Order);

	BIG_fromBytes(s,S->val);
	BIG_fromBytes(f,H.val);

    ECP_set(&G,gx,gy);

    do {
		BIG_randomnum(u,r,RNG);
        ECP_copy(&V,&G);
        ECP_mul(&V,u);

        ECP_get(vx,vx,&V);

		BIG_copy(c,vx);
		BIG_mod(c,r);
		if (BIG_iszilch(c)) continue;

		BIG_invmodp(u,u,r);
		BIG_modmul(d,s,c,r);

		BIG_add(d,f,d);

		BIG_modmul(d,u,d,r);

	} while (BIG_iszilch(d));

	C->len=D->len=EGS;

	BIG_toBytes(C->val,c);
	BIG_toBytes(D->val,d);

    return 0;
}

/* IEEE1363 ECDSA Signature Verification. Signature C and D on F is verified using public key W */
int ECP_VP_DSA(octet *W,octet *F, octet *C,octet *D)
{
	char h[32];
	octet H={0,sizeof(h),h};

    BIG r,gx,gy,wx,wy,f,c,d,h2;
    int res=0;
    ECP G,WP;
    int valid;

 	hashit(F,-1,NULL,NULL,&H);

	BIG_rcopy(gx,CURVE_Gx);
	BIG_rcopy(gy,CURVE_Gy);
	BIG_rcopy(r,CURVE_Order);

	BIG_fromBytes(c,C->val);
	BIG_fromBytes(d,D->val);
	BIG_fromBytes(f,H.val);

    if (BIG_iszilch(c) || BIG_comp(c,r)>=0 || BIG_iszilch(d) || BIG_comp(d,r)>=0)
		res=ECDH_INVALID;

    if (res==0)
    {
		BIG_invmodp(d,d,r);
		BIG_modmul(f,f,d,r);
		BIG_modmul(h2,c,d,r);

		ECP_set(&G,gx,gy);

		BIG_fromBytes(wx,&(W->val[1]));
		BIG_fromBytes(wy,&(W->val[EFS+1]));

		valid=ECP_set(&WP,wx,wy);

        if (!valid) res=ECDH_ERROR;
        else
        {
			ECP_mul2(&WP,&G,h2,f);

            if (ECP_isinf(&WP)) res=ECDH_INVALID;
            else
            {
                ECP_get(d,d,&WP);
				BIG_mod(d,r);
                if (BIG_comp(d,c)!=0) res=ECDH_INVALID;
            }
        }
    }

    return res;
}

/* IEEE1363 ECIES encryption. Encryption of plaintext M uses public key W and produces ciphertext V,C,T */
void ECP_ECIES_ENCRYPT(octet *P1,octet *P2,csprng *RNG,octet *W,octet *M,int tlen,octet *V,octet *C,octet *T)
{

	int i,len;
	char z[EFS],vz[3*EFS+2],k[32],k1[16],k2[16],l2[8],u[EFS];
	octet Z={0,sizeof(z),z};
	octet VZ={0,sizeof(vz),vz};
	octet K={0,sizeof(k),k};
	octet K1={0,sizeof(k1),k1};
	octet K2={0,sizeof(k2),k2};
	octet L2={0,sizeof(l2),l2};
	octet U={0,sizeof(u),u};

    if (ECP_KEY_PAIR_GENERATE(RNG,&U,V)!=0) return;
    if (ECP_SVDP_DH(&U,W,&Z)!=0) return;

    OCT_copy(&VZ,V);
    OCT_joctet(&VZ,&Z);

    ECP_KDF2(&VZ,P1,EFS,&K);

    K1.len=K2.len=16;
    for (i=0;i<16;i++) {K1.val[i]=K.val[i]; K2.val[i]=K.val[16+i];}

    ECP_AES_CBC_IV0_ENCRYPT(&K1,M,C);

    OCT_jint(&L2,P2->len,8);

    len=C->len;
    OCT_joctet(C,P2);
    OCT_joctet(C,&L2);
    ECP_HMAC(C,&K2,tlen,T);
    C->len=len;
}

/* IEEE1363 ECIES decryption. Decryption of ciphertext V,C,T using private key U outputs plaintext M */
int ECP_ECIES_DECRYPT(octet *P1,octet *P2,octet *V,octet *C,octet *T,octet *U,octet *M)
{

	int i,len;
	char z[EFS],vz[3*EFS+2],k[32],k1[16],k2[16],l2[8],tag[32];
	octet Z={0,sizeof(z),z};
	octet VZ={0,sizeof(vz),vz};
	octet K={0,sizeof(k),k};
	octet K1={0,sizeof(k1),k1};
	octet K2={0,sizeof(k2),k2};
	octet L2={0,sizeof(l2),l2};
	octet TAG={0,sizeof(tag),tag};

	if (ECP_SVDP_DH(U,V,&Z)!=0) return 0;

    OCT_copy(&VZ,V);
    OCT_joctet(&VZ,&Z);

	ECP_KDF2(&VZ,P1,EFS,&K);

	K1.len=K2.len=16;
    for (i=0;i<16;i++) {K1.val[i]=K.val[i]; K2.val[i]=K.val[16+i];}

	if (!ECP_AES_CBC_IV0_DECRYPT(&K1,C,M)) return 0;

	OCT_jint(&L2,P2->len,8);

	len=C->len;
	OCT_joctet(C,P2);
    OCT_joctet(C,&L2);
	ECP_HMAC(C,&K2,T->len,&TAG);
	C->len=len;

	if (!OCT_comp(T,&TAG)) return 0;

	return 1;

}

#endif
