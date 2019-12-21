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

#include "ecdh_ZZZ.h"

/* Calculate a public/private EC GF(p) key pair. W=S.G mod EC(p),
 * where S is the secret key and W is the public key
 * and G is fixed generator.
 * If RNG is NULL then the private key is provided externally in S
 * otherwise it is generated randomly internally */
int ECP_ZZZ_KEY_PAIR_GENERATE(csprng *RNG,octet* S,octet *W)
{
    BIG_XXX r,s;
    ECP_ZZZ G;
    int res=0;

    ECP_ZZZ_generator(&G);

    BIG_XXX_rcopy(r,CURVE_Order_ZZZ);
    if (RNG!=NULL)
    {
        BIG_XXX_randomnum(s,r,RNG);
    }
    else
    {
        BIG_XXX_fromBytes(s,S->val);
        BIG_XXX_mod(s,r);
    }

#ifdef AES_S
    BIG_XXX_mod2m(s,2*AES_S);
#endif

    S->len=EGS_ZZZ;
    BIG_XXX_toBytes(S->val,s);

    ECP_ZZZ_mul(&G,s);

    ECP_ZZZ_toOctet(W,&G,false);  /* To use point compression on public keys, change to true */

    return res;
}

/* Validate public key */
int ECP_ZZZ_PUBLIC_KEY_VALIDATE(octet *W)
{
    BIG_XXX q,r,k;
    ECP_ZZZ WP;
    int valid,nb;
    int res=0;

    BIG_XXX_rcopy(q,Modulus_YYY);
    BIG_XXX_rcopy(r,CURVE_Order_ZZZ);

    valid=ECP_ZZZ_fromOctet(&WP,W);
    if (!valid) res=ECDH_INVALID_PUBLIC_KEY;

    if (res==0)
    {
        /* Check point is not in wrong group */
        nb=BIG_XXX_nbits(q);
        BIG_XXX_one(k);
        BIG_XXX_shl(k,(nb+4)/2);
        BIG_XXX_add(k,q,k);
        BIG_XXX_sdiv(k,r); /* get co-factor */

        while (BIG_XXX_parity(k)==0)
        {
            ECP_ZZZ_dbl(&WP);
            BIG_XXX_fshr(k,1);
        }

        if (!BIG_XXX_isunity(k)) ECP_ZZZ_mul(&WP,k);
        if (ECP_ZZZ_isinf(&WP)) res=ECDH_INVALID_PUBLIC_KEY;
    }

    return res;
}

/* IEEE-1363 Diffie-Hellman online calculation Z=S.WD */
int ECP_ZZZ_SVDP_DH(octet *S,octet *WD,octet *Z)
{
    BIG_XXX r,s,wx;
    int valid;
    ECP_ZZZ W;
    int res=0;

    BIG_XXX_fromBytes(s,S->val);

    valid=ECP_ZZZ_fromOctet(&W,WD);

    if (!valid) res=ECDH_ERROR;
    if (res==0)
    {
        BIG_XXX_rcopy(r,CURVE_Order_ZZZ);
        BIG_XXX_mod(s,r);

        ECP_ZZZ_mul(&W,s);
        if (ECP_ZZZ_isinf(&W)) res=ECDH_ERROR;
        else
        {
#if CURVETYPE_ZZZ!=MONTGOMERY
            ECP_ZZZ_get(wx,wx,&W);
#else
            ECP_ZZZ_get(wx,&W);
#endif
            Z->len=MODBYTES_XXX;
            BIG_XXX_toBytes(Z->val,wx);
        }
    }
    return res;
}

#if CURVETYPE_ZZZ!=MONTGOMERY

/* IEEE ECDSA Signature, C and D are signature on F using private key S */
int ECP_ZZZ_SP_DSA(int sha,csprng *RNG,octet *K,octet *S,octet *F,octet *C,octet *D)
{
    char h[128];
    octet H= {0,sizeof(h),h};

    BIG_XXX r,s,f,c,d,u,vx,w;
    ECP_ZZZ G,V;

    ehashit(sha,F,-1,NULL,&H,sha);

    ECP_ZZZ_generator(&G);

    BIG_XXX_rcopy(r,CURVE_Order_ZZZ);

    BIG_XXX_fromBytes(s,S->val);

    int hlen=H.len;
    if (H.len>MODBYTES_XXX) hlen=MODBYTES_XXX;
    BIG_XXX_fromBytesLen(f,H.val,hlen);

    if (RNG!=NULL)
    {
        do
        {
            BIG_XXX_randomnum(u,r,RNG);
            BIG_XXX_randomnum(w,r,RNG); /* side channel masking */

#ifdef AES_S
            BIG_XXX_mod2m(u,2*AES_S);
#endif
            ECP_ZZZ_copy(&V,&G);
            ECP_ZZZ_mul(&V,u);

            ECP_ZZZ_get(vx,vx,&V);

            BIG_XXX_copy(c,vx);
            BIG_XXX_mod(c,r);
            if (BIG_XXX_iszilch(c)) continue;

            BIG_XXX_modmul(u,u,w,r);

            BIG_XXX_invmodp(u,u,r);
            BIG_XXX_modmul(d,s,c,r);

            BIG_XXX_add(d,f,d);

            BIG_XXX_modmul(d,d,w,r);

            BIG_XXX_modmul(d,u,d,r);
        }
        while (BIG_XXX_iszilch(d));
    }
    else
    {
        BIG_XXX_fromBytes(u,K->val);
        BIG_XXX_mod(u,r);

#ifdef AES_S
        BIG_XXX_mod2m(u,2*AES_S);
#endif
        ECP_ZZZ_copy(&V,&G);
        ECP_ZZZ_mul(&V,u);

        ECP_ZZZ_get(vx,vx,&V);

        BIG_XXX_copy(c,vx);
        BIG_XXX_mod(c,r);
        if (BIG_XXX_iszilch(c)) return ECDH_ERROR;


        BIG_XXX_invmodp(u,u,r);
        BIG_XXX_modmul(d,s,c,r);

        BIG_XXX_add(d,f,d);

        BIG_XXX_modmul(d,u,d,r);
        if (BIG_XXX_iszilch(d)) return ECDH_ERROR;
    }

    C->len=D->len=EGS_ZZZ;

    BIG_XXX_toBytes(C->val,c);
    BIG_XXX_toBytes(D->val,d);

    return 0;
}

/* IEEE1363 ECDSA Signature Verification. Signature C and D on F is verified using public key W */
int ECP_ZZZ_VP_DSA(int sha,octet *W,octet *F, octet *C,octet *D)
{
    char h[128];
    octet H= {0,sizeof(h),h};

    BIG_XXX r,f,c,d,h2;
    int res=0;
    ECP_ZZZ G,WP;
    int valid;

    ehashit(sha,F,-1,NULL,&H,sha);

    ECP_ZZZ_generator(&G);

    BIG_XXX_rcopy(r,CURVE_Order_ZZZ);

    OCT_shl(C,C->len-MODBYTES_XXX);
    OCT_shl(D,D->len-MODBYTES_XXX);

    BIG_XXX_fromBytes(c,C->val);
    BIG_XXX_fromBytes(d,D->val);

    int hlen=H.len;
    if (hlen>MODBYTES_XXX) hlen=MODBYTES_XXX;

    BIG_XXX_fromBytesLen(f,H.val,hlen);

    //BIG_fromBytes(f,H.val);

    if (BIG_XXX_iszilch(c) || BIG_XXX_comp(c,r)>=0 || BIG_XXX_iszilch(d) || BIG_XXX_comp(d,r)>=0)
        res=ECDH_INVALID;

    if (res==0)
    {
        BIG_XXX_invmodp(d,d,r);
        BIG_XXX_modmul(f,f,d,r);
        BIG_XXX_modmul(h2,c,d,r);

        valid=ECP_ZZZ_fromOctet(&WP,W);

        if (!valid) res=ECDH_ERROR;
        else
        {
            ECP_ZZZ_mul2(&WP,&G,h2,f);

            if (ECP_ZZZ_isinf(&WP)) res=ECDH_INVALID;
            else
            {
                ECP_ZZZ_get(d,d,&WP);
                BIG_XXX_mod(d,r);
                if (BIG_XXX_comp(d,c)!=0) res=ECDH_INVALID;
            }
        }
    }

    return res;
}

/* IEEE1363 ECIES encryption. Encryption of plaintext M uses public key W and produces ciphertext V,C,T */
void ECP_ZZZ_ECIES_ENCRYPT(int sha,octet *P1,octet *P2,csprng *RNG,octet *W,octet *M,int tlen,octet *V,octet *C,octet *T)
{

    int i,len;
    char z[EFS_ZZZ],vz[3*EFS_ZZZ+1],k[2*AESKEY_ZZZ],k1[AESKEY_ZZZ],k2[AESKEY_ZZZ],l2[8],u[EFS_ZZZ];
    octet Z= {0,sizeof(z),z};
    octet VZ= {0,sizeof(vz),vz};
    octet K= {0,sizeof(k),k};
    octet K1= {0,sizeof(k1),k1};
    octet K2= {0,sizeof(k2),k2};
    octet L2= {0,sizeof(l2),l2};
    octet U= {0,sizeof(u),u};

    if (ECP_ZZZ_KEY_PAIR_GENERATE(RNG,&U,V)!=0) return;
    if (ECP_ZZZ_SVDP_DH(&U,W,&Z)!=0) return;

    OCT_copy(&VZ,V);
    OCT_joctet(&VZ,&Z);

    KDF2(sha,&VZ,P1,2*AESKEY_ZZZ,&K);

    K1.len=K2.len=AESKEY_ZZZ;
    for (i=0; i<AESKEY_ZZZ; i++)
    {
        K1.val[i]=K.val[i];
        K2.val[i]=K.val[AESKEY_ZZZ+i];
    }

    AES_CBC_IV0_ENCRYPT(&K1,M,C);

    OCT_jint(&L2,P2->len,8);

    len=C->len;
    OCT_joctet(C,P2);
    OCT_joctet(C,&L2);
    HMAC(sha,C,&K2,tlen,T);
    C->len=len;
}

/* IEEE1363 ECIES decryption. Decryption of ciphertext V,C,T using private key U outputs plaintext M */
int ECP_ZZZ_ECIES_DECRYPT(int sha,octet *P1,octet *P2,octet *V,octet *C,octet *T,octet *U,octet *M)
{

    int i,len;
    char z[EFS_ZZZ],vz[3*EFS_ZZZ+1],k[2*AESKEY_ZZZ],k1[AESKEY_ZZZ],k2[AESKEY_ZZZ],l2[8],tag[32];
    octet Z= {0,sizeof(z),z};
    octet VZ= {0,sizeof(vz),vz};
    octet K= {0,sizeof(k),k};
    octet K1= {0,sizeof(k1),k1};
    octet K2= {0,sizeof(k2),k2};
    octet L2= {0,sizeof(l2),l2};
    octet TAG= {0,sizeof(tag),tag};

    if (ECP_ZZZ_SVDP_DH(U,V,&Z)!=0) return 0;

    OCT_copy(&VZ,V);
    OCT_joctet(&VZ,&Z);

    KDF2(sha,&VZ,P1,2*AESKEY_ZZZ,&K);

    K1.len=K2.len=AESKEY_ZZZ;
    for (i=0; i<AESKEY_ZZZ; i++)
    {
        K1.val[i]=K.val[i];
        K2.val[i]=K.val[AESKEY_ZZZ+i];
    }

    if (!AES_CBC_IV0_DECRYPT(&K1,C,M)) return 0;

    OCT_jint(&L2,P2->len,8);

    len=C->len;
    OCT_joctet(C,P2);
    OCT_joctet(C,&L2);
    HMAC(sha,C,&K2,T->len,&TAG);
    C->len=len;

    if (!OCT_ncomp(T,&TAG,T->len)) return 0;

    return 1;

}

#endif
