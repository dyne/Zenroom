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

/* An example of using multiple curves in an executible */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "ecdh_ED25519.h"
#include "mpin_BLS381.h"
#include "rsa_2048.h"
#include "rsa_3072.h"
#include "randapi.h"

#if CHUNK!=16
#include "ecdh_NIST256.h"
#include "ecdh_GOLDILOCKS.h"
#endif

int ecdh_ED25519(csprng *RNG)
{
    int i,res;
    unsigned long ran;
    char *pp="M0ng00se";
    // These octets are automatically protected against buffer overflow attacks
    // Note salt must be big enough to include an appended word
    // Note ECIES ciphertext C must be big enough to include at least 1 appended block
    // Recall EFS_ED25519 is field size in bytes. So EFS_ED25519=32 for 256-bit curve
    char s0[2*EGS_ED25519],s1[EGS_ED25519],w0[2*EFS_ED25519+1],w1[2*EFS_ED25519+1],z0[EFS_ED25519],z1[EFS_ED25519],key[AESKEY_ED25519],salt[40],pw[40];
    octet S0= {0,sizeof(s0),s0};
    octet S1= {0,sizeof(s1),s1};
    octet W0= {0,sizeof(w0),w0};
    octet W1= {0,sizeof(w1),w1};
    octet Z0= {0,sizeof(z0),z0};
    octet Z1= {0,sizeof(z1),z1};
    octet KEY= {0,sizeof(key),key};
    octet SALT= {0,sizeof(salt),salt};
    octet PW= {0,sizeof(pw),pw};

    SALT.len=8;
    for (i=0; i<8; i++) SALT.val[i]=i+1; // set Salt

    printf("Alice's Passphrase= %s\n",pp);

    OCT_empty(&PW);
    OCT_jstring(&PW,pp);   // set Password from string

    // private key S0 of size EGS_ED25519 bytes derived from Password and Salt

    PBKDF2(HASH_TYPE_ED25519,&PW,&SALT,1000,EGS_ED25519,&S0);

    printf("Alices private key= 0x");
    OCT_output(&S0);

    // Generate Key pair S/W

    ECP_ED25519_KEY_PAIR_GENERATE(NULL,&S0,&W0);
    printf("Alices public key= 0x");
    OCT_output(&W0);

    res=ECP_ED25519_PUBLIC_KEY_VALIDATE(&W0);
    if (res!=0)
    {
        printf("ECP Public Key is invalid!\n");
        return 0;
    }

    // Random private key for other party
    ECP_ED25519_KEY_PAIR_GENERATE(RNG,&S1,&W1);
    res=ECP_ED25519_PUBLIC_KEY_VALIDATE(&W1);
    if (res!=0)
    {
        printf("ECP Public Key is invalid!\n");
        return 0;
    }
    printf("Servers private key= 0x");
    OCT_output(&S1);
    printf("Servers public key= 0x");
    OCT_output(&W1);

    // Calculate common key using DH - IEEE 1363 method

    ECP_ED25519_SVDP_DH(&S0,&W1,&Z0);
    ECP_ED25519_SVDP_DH(&S1,&W0,&Z1);

    if (!OCT_comp(&Z0,&Z1))
    {
        printf("*** ECPSVDP-DH Failed\n");
        return 0;
    }

    KDF2(HASH_TYPE_ED25519,&Z0,NULL,AESKEY_ED25519,&KEY);

    printf("Alice's DH Key=  0x");
    OCT_output(&KEY);
    printf("Servers DH Key=  0x");
    OCT_output(&KEY);

#if CURVETYPE_ED25519 != MONTGOMERY

    char ds[EGS_ED25519],p1[30],p2[30],v[2*EFS_ED25519+1],m[32],c[64],t[32],cs[EGS_ED25519];
    octet DS= {0,sizeof(ds),ds};
    octet CS= {0,sizeof(cs),cs};
    octet P1= {0,sizeof(p1),p1};
    octet P2= {0,sizeof(p2),p2};
    octet V= {0,sizeof(v),v};
    octet M= {0,sizeof(m),m};
    octet C= {0,sizeof(c),c};
    octet T= {0,sizeof(t),t};

    printf("Testing ECIES\n");

    P1.len=3;
    P1.val[0]=0x0;
    P1.val[1]=0x1;
    P1.val[2]=0x2;
    P2.len=4;
    P2.val[0]=0x0;
    P2.val[1]=0x1;
    P2.val[2]=0x2;
    P2.val[3]=0x3;

    M.len=17;
    for (i=0; i<=16; i++) M.val[i]=i;

    ECP_ED25519_ECIES_ENCRYPT(HASH_TYPE_ED25519,&P1,&P2,RNG,&W1,&M,12,&V,&C,&T);

    printf("Ciphertext= \n");
    printf("V= 0x");
    OCT_output(&V);
    printf("C= 0x");
    OCT_output(&C);
    printf("T= 0x");
    OCT_output(&T);

    if (!ECP_ED25519_ECIES_DECRYPT(HASH_TYPE_ED25519,&P1,&P2,&V,&C,&T,&S1,&M))
    {
        printf("*** ECIES Decryption Failed\n");
        return 0;
    }
    else printf("Decryption succeeded\n");

    printf("Message is 0x");
    OCT_output(&M);


    printf("Testing ECDSA\n");

    if (ECP_ED25519_SP_DSA(HASH_TYPE_ED25519,RNG,NULL,&S0,&M,&CS,&DS)!=0)
    {
        printf("***ECDSA Signature Failed\n");
        return 0;
    }

    printf("Signature C = 0x");
    OCT_output(&CS);
    printf("Signature D = 0x");
    OCT_output(&DS);

    if (ECP_ED25519_VP_DSA(HASH_TYPE_ED25519,&W0,&M,&CS,&DS)!=0)
    {
        printf("***ECDSA Verification Failed\n");
        return 0;
    }
    else
    {
        printf("ECDSA Signature/Verification succeeded\n");
    }

#endif

    return 0;
}

#if CHUNK!=16
int ecdh_NIST256(csprng *RNG)
{
    int i,res;
    unsigned long ran;
    char *pp="M0ng00se";
    // These octets are automatically protected against buffer overflow attacks
    // Note salt must be big enough to include an appended word
    // Note ECIES ciphertext C must be big enough to include at least 1 appended block
    // Recall EFS_NIST256 is field size in bytes. So EFS_NIST256=32 for 256-bit curve
    char s0[2*EGS_NIST256],s1[EGS_NIST256],w0[2*EFS_NIST256+1],w1[2*EFS_NIST256+1],z0[EFS_NIST256],z1[EFS_NIST256],key[AESKEY_NIST256],salt[40],pw[40];
    octet S0= {0,sizeof(s0),s0};
    octet S1= {0,sizeof(s1),s1};
    octet W0= {0,sizeof(w0),w0};
    octet W1= {0,sizeof(w1),w1};
    octet Z0= {0,sizeof(z0),z0};
    octet Z1= {0,sizeof(z1),z1};
    octet KEY= {0,sizeof(key),key};
    octet SALT= {0,sizeof(salt),salt};
    octet PW= {0,sizeof(pw),pw};

    SALT.len=8;
    for (i=0; i<8; i++) SALT.val[i]=i+1; // set Salt

    printf("Alice's Passphrase= %s\n",pp);

    OCT_empty(&PW);
    OCT_jstring(&PW,pp);   // set Password from string

    // private key S0 of size EGS_NIST256 bytes derived from Password and Salt

    PBKDF2(HASH_TYPE_NIST256,&PW,&SALT,1000,EGS_NIST256,&S0);

    printf("Alices private key= 0x");
    OCT_output(&S0);

    // Generate Key pair S/W

    ECP_NIST256_KEY_PAIR_GENERATE(NULL,&S0,&W0);
    printf("Alices public key= 0x");
    OCT_output(&W0);

    res=ECP_NIST256_PUBLIC_KEY_VALIDATE(&W0);
    if (res!=0)
    {
        printf("ECP Public Key is invalid!\n");
        return 0;
    }

    // Random private key for other party
    ECP_NIST256_KEY_PAIR_GENERATE(RNG,&S1,&W1);
    res=ECP_NIST256_PUBLIC_KEY_VALIDATE(&W1);
    if (res!=0)
    {
        printf("ECP Public Key is invalid!\n");
        return 0;
    }
    printf("Servers private key= 0x");
    OCT_output(&S1);
    printf("Servers public key= 0x");
    OCT_output(&W1);

    // Calculate common key using DH - IEEE 1363 method

    ECP_NIST256_SVDP_DH(&S0,&W1,&Z0);
    ECP_NIST256_SVDP_DH(&S1,&W0,&Z1);

    if (!OCT_comp(&Z0,&Z1))
    {
        printf("*** ECPSVDP-DH Failed\n");
        return 0;
    }

    KDF2(HASH_TYPE_NIST256,&Z0,NULL,AESKEY_NIST256,&KEY);

    printf("Alice's DH Key=  0x");
    OCT_output(&KEY);
    printf("Servers DH Key=  0x");
    OCT_output(&KEY);

#if CURVETYPE_NIST256 != MONTGOMERY

    char ds[EGS_NIST256],p1[30],p2[30],v[2*EFS_NIST256+1],m[32],c[64],t[32],cs[EGS_NIST256];
    octet DS= {0,sizeof(ds),ds};
    octet CS= {0,sizeof(cs),cs};
    octet P1= {0,sizeof(p1),p1};
    octet P2= {0,sizeof(p2),p2};
    octet V= {0,sizeof(v),v};
    octet M= {0,sizeof(m),m};
    octet C= {0,sizeof(c),c};
    octet T= {0,sizeof(t),t};

    printf("Testing ECIES\n");

    P1.len=3;
    P1.val[0]=0x0;
    P1.val[1]=0x1;
    P1.val[2]=0x2;
    P2.len=4;
    P2.val[0]=0x0;
    P2.val[1]=0x1;
    P2.val[2]=0x2;
    P2.val[3]=0x3;

    M.len=17;
    for (i=0; i<=16; i++) M.val[i]=i;

    ECP_NIST256_ECIES_ENCRYPT(HASH_TYPE_NIST256,&P1,&P2,RNG,&W1,&M,12,&V,&C,&T);

    printf("Ciphertext= \n");
    printf("V= 0x");
    OCT_output(&V);
    printf("C= 0x");
    OCT_output(&C);
    printf("T= 0x");
    OCT_output(&T);

    if (!ECP_NIST256_ECIES_DECRYPT(HASH_TYPE_NIST256,&P1,&P2,&V,&C,&T,&S1,&M))
    {
        printf("*** ECIES Decryption Failed\n");
        return 0;
    }
    else printf("Decryption succeeded\n");

    printf("Message is 0x");
    OCT_output(&M);


    printf("Testing ECDSA\n");

    if (ECP_NIST256_SP_DSA(HASH_TYPE_NIST256,RNG,NULL,&S0,&M,&CS,&DS)!=0)
    {
        printf("***ECDSA Signature Failed\n");
        return 0;
    }

    printf("Signature C = 0x");
    OCT_output(&CS);
    printf("Signature D = 0x");
    OCT_output(&DS);

    if (ECP_NIST256_VP_DSA(HASH_TYPE_NIST256,&W0,&M,&CS,&DS)!=0)
    {
        printf("***ECDSA Verification Failed\n");
        return 0;
    }
    else
    {
        printf("ECDSA Signature/Verification succeeded\n");
    }

#endif

    return 0;
}

int ecdh_GOLDILOCKS(csprng *RNG)
{
    int i,res;
    unsigned long ran;
    char *pp="M0ng00se";
    // These octets are automatically protected against buffer overflow attacks
    // Note salt must be big enough to include an appended word
    // Note ECIES ciphertext C must be big enough to include at least 1 appended block
    // Recall EFS_GOLDILOCKS is field size in bytes. So EFS_GOLDILOCKS=32 for 256-bit curve
    char s0[2*EGS_GOLDILOCKS],s1[EGS_GOLDILOCKS],w0[2*EFS_GOLDILOCKS+1],w1[2*EFS_GOLDILOCKS+1],z0[EFS_GOLDILOCKS],z1[EFS_GOLDILOCKS],key[AESKEY_GOLDILOCKS],salt[40],pw[40];
    octet S0= {0,sizeof(s0),s0};
    octet S1= {0,sizeof(s1),s1};
    octet W0= {0,sizeof(w0),w0};
    octet W1= {0,sizeof(w1),w1};
    octet Z0= {0,sizeof(z0),z0};
    octet Z1= {0,sizeof(z1),z1};
    octet KEY= {0,sizeof(key),key};
    octet SALT= {0,sizeof(salt),salt};
    octet PW= {0,sizeof(pw),pw};

    SALT.len=8;
    for (i=0; i<8; i++) SALT.val[i]=i+1; // set Salt

    printf("Alice's Passphrase= %s\n",pp);

    OCT_empty(&PW);
    OCT_jstring(&PW,pp);   // set Password from string

    // private key S0 of size EGS_GOLDILOCKS bytes derived from Password and Salt

    PBKDF2(HASH_TYPE_GOLDILOCKS,&PW,&SALT,1000,EGS_GOLDILOCKS,&S0);

    printf("Alices private key= 0x");
    OCT_output(&S0);

    // Generate Key pair S/W

    ECP_GOLDILOCKS_KEY_PAIR_GENERATE(NULL,&S0,&W0);
    printf("Alices public key= 0x");
    OCT_output(&W0);

    res=ECP_GOLDILOCKS_PUBLIC_KEY_VALIDATE(&W0);
    if (res!=0)
    {
        printf("ECP Public Key is invalid!\n");
        return 0;
    }

    // Random private key for other party
    ECP_GOLDILOCKS_KEY_PAIR_GENERATE(RNG,&S1,&W1);
    res=ECP_GOLDILOCKS_PUBLIC_KEY_VALIDATE(&W1);
    if (res!=0)
    {
        printf("ECP Public Key is invalid!\n");
        return 0;
    }
    printf("Servers private key= 0x");
    OCT_output(&S1);
    printf("Servers public key= 0x");
    OCT_output(&W1);

    // Calculate common key using DH - IEEE 1363 method

    ECP_GOLDILOCKS_SVDP_DH(&S0,&W1,&Z0);
    ECP_GOLDILOCKS_SVDP_DH(&S1,&W0,&Z1);

    if (!OCT_comp(&Z0,&Z1))
    {
        printf("*** ECPSVDP-DH Failed\n");
        return 0;
    }

    KDF2(HASH_TYPE_GOLDILOCKS,&Z0,NULL,AESKEY_GOLDILOCKS,&KEY);

    printf("Alice's DH Key=  0x");
    OCT_output(&KEY);
    printf("Servers DH Key=  0x");
    OCT_output(&KEY);

#if CURVETYPE_GOLDILOCKS != MONTGOMERY

    char ds[EGS_GOLDILOCKS],p1[30],p2[30],v[2*EFS_GOLDILOCKS+1],m[32],c[64],t[32],cs[EGS_GOLDILOCKS];
    octet DS= {0,sizeof(ds),ds};
    octet CS= {0,sizeof(cs),cs};
    octet P1= {0,sizeof(p1),p1};
    octet P2= {0,sizeof(p2),p2};
    octet V= {0,sizeof(v),v};
    octet M= {0,sizeof(m),m};
    octet C= {0,sizeof(c),c};
    octet T= {0,sizeof(t),t};

    printf("Testing ECIES\n");

    P1.len=3;
    P1.val[0]=0x0;
    P1.val[1]=0x1;
    P1.val[2]=0x2;
    P2.len=4;
    P2.val[0]=0x0;
    P2.val[1]=0x1;
    P2.val[2]=0x2;
    P2.val[3]=0x3;

    M.len=17;
    for (i=0; i<=16; i++) M.val[i]=i;

    ECP_GOLDILOCKS_ECIES_ENCRYPT(HASH_TYPE_GOLDILOCKS,&P1,&P2,RNG,&W1,&M,12,&V,&C,&T);

    printf("Ciphertext= \n");
    printf("V= 0x");
    OCT_output(&V);
    printf("C= 0x");
    OCT_output(&C);
    printf("T= 0x");
    OCT_output(&T);

    if (!ECP_GOLDILOCKS_ECIES_DECRYPT(HASH_TYPE_GOLDILOCKS,&P1,&P2,&V,&C,&T,&S1,&M))
    {
        printf("*** ECIES Decryption Failed\n");
        return 0;
    }
    else printf("Decryption succeeded\n");

    printf("Message is 0x");
    OCT_output(&M);


    printf("Testing ECDSA\n");

    if (ECP_GOLDILOCKS_SP_DSA(HASH_TYPE_GOLDILOCKS,RNG,NULL,&S0,&M,&CS,&DS)!=0)
    {
        printf("***ECDSA Signature Failed\n");
        return 0;
    }

    printf("Signature C = 0x");
    OCT_output(&CS);
    printf("Signature D = 0x");
    OCT_output(&DS);

    if (ECP_GOLDILOCKS_VP_DSA(HASH_TYPE_GOLDILOCKS,&W0,&M,&CS,&DS)!=0)
    {
        printf("***ECDSA Verification Failed\n");
        return 0;
    }
    else
    {
        printf("ECDSA Signature/Verification succeeded\n");
    }

#endif

    return 0;
}
#endif

#define PERMITS  // for time permits ON or OFF 
#define PINERROR // For PIN ERROR detection ON or OFF 
#define FULL     // for M-Pin Full or M-Pin regular 

int mpin_BLS381(csprng *RNG)
{
    int i,pin,rtn,err;
#ifdef PERMITS
    int date=today();
#else
    int date=0;
#endif
    unsigned long ran;
    char x[PGS_BLS381],s[PGS_BLS381],y[PGS_BLS381],client_id[100],sst[4*PFS_BLS381],token[2*PFS_BLS381+1],sec[2*PFS_BLS381+1],permit[2*PFS_BLS381+1],xcid[2*PFS_BLS381+1],xid[2*PFS_BLS381+1],e[12*PFS_BLS381],f[12*PFS_BLS381];
    char hcid[PFS_BLS381],hsid[PFS_BLS381],hid[2*PFS_BLS381+1],htid[2*PFS_BLS381+1],h[PGS_BLS381];
#ifdef FULL
    char r[PGS_BLS381],z[2*PFS_BLS381+1],w[PGS_BLS381],t[2*PFS_BLS381+1];
    char g1[12*PFS_BLS381],g2[12*PFS_BLS381];
    char ck[MPIN_PAS],sk[MPIN_PAS];
#endif
    octet S= {0,sizeof(s),s};
    octet X= {0,sizeof(x),x};
    octet Y= {0,sizeof(y),y};
    octet H= {0,sizeof(h),h};
    octet CLIENT_ID= {0,sizeof(client_id),client_id};
    octet SST= {0,sizeof(sst),sst};
    octet TOKEN= {0,sizeof(token),token};
    octet SEC= {0,sizeof(sec),sec};
    octet PERMIT= {0,sizeof(permit),permit};
    octet xCID= {0,sizeof(xcid),xcid};
    octet xID= {0,sizeof(xid),xid};
    octet HCID= {0,sizeof(hcid),hcid};
    octet HSID= {0,sizeof(hsid),hsid};
    octet HID= {0,sizeof(hid),hid};
    octet HTID= {0,sizeof(htid),htid};
    octet E= {0,sizeof(e),e};
    octet F= {0,sizeof(f),f};
#ifdef FULL
    octet R= {0,sizeof(r),r};
    octet Z= {0,sizeof(z),z};
    octet W= {0,sizeof(w),w};
    octet T= {0,sizeof(t),t};
    octet G1= {0,sizeof(g1),g1};
    octet G2= {0,sizeof(g2),g2};
    octet SK= {0,sizeof(sk),sk};
    octet CK= {0,sizeof(ck),ck};
#endif
    octet *pxID,*pxCID,*pHID,*pHTID,*pE,*pF,*pPERMIT,*prHID;
    char idhex[100];

    // Trusted Authority set-up
    MPIN_BLS381_RANDOM_GENERATE(RNG,&S);
    printf("Master Secret= ");
    OCT_output(&S);

    // Create Client Identity
    OCT_jstring(&CLIENT_ID,"testUser@milagro.com");
    HASH_ID(HASH_TYPE_BLS381,&CLIENT_ID,&HCID);  // Either Client or TA calculates Hash(ID) - you decide!

    printf("Client ID Hash= ");
    OCT_output(&HCID);
    printf("\n");

    OCT_toHex(&CLIENT_ID,idhex);
    printf("Client ID= %s\n",idhex);// OCT_toHex(&CLIENT_ID); printf("\n");

    MPIN_BLS381_GET_CLIENT_SECRET(&S,&HCID,&TOKEN);
    printf("Client Secret= ");
    OCT_output(&TOKEN);

// Client and Server are issued secrets by DTA
    MPIN_BLS381_GET_SERVER_SECRET(&S,&SST);
    printf("Server Secret= ");
    OCT_output(&SST);



    // Client extracts PIN from secret to create Token
    pin=1234;
    printf("Client extracts PIN= %d\n",pin);
    MPIN_BLS381_EXTRACT_PIN(HASH_TYPE_BLS381,&CLIENT_ID,pin,&TOKEN);
    printf("Client Token= ");
    OCT_output(&TOKEN);

#ifdef FULL
    MPIN_BLS381_PRECOMPUTE(&TOKEN,&HCID,NULL,&G1,&G2);
#endif

#ifdef PERMITS
    // Client gets "Time Permit" from DTA
    printf("Client gets Time Permit\n");

    MPIN_BLS381_GET_CLIENT_PERMIT(HASH_TYPE_BLS381,date,&S,&HCID,&PERMIT);
    printf("Time Permit= ");
    OCT_output(&PERMIT);

    // This encoding makes Time permit look random
    if (MPIN_BLS381_ENCODING(RNG,&PERMIT)!=0) printf("Encoding error\n");
    // printf("Encoded Time Permit= "); OCT_output(&PERMIT);
    if (MPIN_BLS381_DECODING(&PERMIT)!=0) printf("Decoding error\n");
    // printf("Decoded Time Permit= "); OCT_output(&PERMIT);
#endif

    // MPin Protocol

    // Client enters PIN
    //printf("\nPIN= ");
    //if(scanf("%d",&pin)) {};
    // to avoid silly compile error
    //getchar();
    pin = 1234;

    // Set date=0 and PERMIT=NULL if time permits not in use

    // Client First pass: Inputs CLIENT_ID, optional RNG, pin, TOKEN and PERMIT. Output xID = x.H(CLIENT_ID) and re-combined secret SEC
    // If PERMITS are is use, then date!=0 and PERMIT is added to secret and xCID = x.(H(CLIENT_ID)+H(date|H(CLIENT_ID)))
    // Random value x is supplied externally if RNG=NULL, otherwise generated and passed out by RNG

    // HSID - hashed client ID as calculated by the server
    // HCID - hashed client ID as calculated by the client

    // IMPORTANT: To save space and time..
    // If Time Permits OFF set xCID = NULL, HTID=NULL and use xID and HID only
    // If Time permits are ON, AND pin error detection is required then all of xID, xCID, HID and HTID are required
    // If Time permits are ON, AND pin error detection is NOT required, set xID=NULL, HID=NULL and use xCID and HTID only.



    pxID=&xID;
    pxCID=&xCID;
    pHID=&HID;
    pHTID=&HTID;
    pE=&E;
    pF=&F;
    pPERMIT=&PERMIT;

#ifdef PERMITS
    prHID=pHTID;
#ifndef PINERROR
    pxID=NULL;
//   pHID=NULL;  //new
#endif
#else
    prHID=pHID;
    pPERMIT=NULL;
    pxCID=NULL;
    pHTID=NULL;
#endif
#ifndef PINERROR
    pE=NULL;
    pF=NULL;
#endif

    // When set only send hashed IDs to server
    octet *pID;
#ifdef USE_ANONYMOUS
    pID = &HCID;
#else
    pID = &CLIENT_ID;
#endif

#ifdef SINGLE_PASS
    int timeValue;
    printf("MPIN Single Pass\n");
    timeValue = MPIN_BLS381_GET_TIME();

    rtn=MPIN_BLS381_CLIENT(HASH_TYPE_BLS381,date,&CLIENT_ID,RNG,&X,pin,&TOKEN,&SEC,pxID,pxCID,pPERMIT,NULL,timeValue,&Y);

    if (rtn != 0)
    {
        printf("MPIN_BLS381_CLIENT ERROR %d\n", rtn);
        return 1;
    }

#ifdef FULL
    MPIN_BLS381_GET_G1_MULTIPLE(RNG,1,&R,&HCID,&Z);  // Also Send Z=r.ID to Server, remember random r
#endif


    rtn=MPIN_BLS381_SERVER(HASH_TYPE_BLS381,date,pHID,pHTID,&Y,&SST,pxID,pxCID,&SEC,pE,pF,pID,NULL,timeValue);

#ifdef FULL
    HASH_ID(HASH_TYPE_BLS381,&CLIENT_ID,&HSID);  // new
    MPIN_BLS381_GET_G1_MULTIPLE(RNG,0,&W,prHID,&T);  // Also send T=w.ID to client, remember random w
#endif

#else // SINGLE_PASS
    printf("MPIN Multi Pass\n");
    if (MPIN_BLS381_CLIENT_1(HASH_TYPE_BLS381,date,&CLIENT_ID,RNG,&X,pin,&TOKEN,&SEC,pxID,pxCID,pPERMIT)!=0)
    {
        printf("Error from Client side - First Pass\n");
        return 0;
    }

    // Send U=x.ID to server, and recreate secret from token and pin

#ifdef FULL
    HASH_ID(HASH_TYPE_BLS381,&CLIENT_ID,&HCID);
    MPIN_BLS381_GET_G1_MULTIPLE(RNG,1,&R,&HCID,&Z);  // Also Send Z=r.ID to Server, remember random r, DH component
#endif

    // Server calculates H(ID) and H(ID)+H(T|H(ID)) (if time permits enabled), and maps them to points on the curve HID and HTID resp.
    MPIN_BLS381_SERVER_1(HASH_TYPE_BLS381,date,pID,pHID,pHTID);

    // Server generates Random number Y and sends it to Client
    MPIN_BLS381_RANDOM_GENERATE(RNG,&Y);

#ifdef FULL
    HASH_ID(HASH_TYPE_BLS381,&CLIENT_ID,&HSID); //new
    MPIN_BLS381_GET_G1_MULTIPLE(RNG,0,&W,prHID,&T);  // Also send T=w.ID to client, remember random w, DH component
#endif

    // Client Second Pass: Inputs Client secret SEC, x and y. Outputs -(x+y)*SEC
    if (MPIN_BLS381_CLIENT_2(&X,&Y,&SEC)!=0)
    {
        printf("Error from Client side - Second Pass\n");
        return 1;
    }

    // Server Second phase. Inputs hashed client id, random Y, -(x+y)*SEC, xID and xCID and Server secret SST. E and F help kangaroos to find error.
    // If PIN error not required, set E and F = NULL
    rtn=MPIN_BLS381_SERVER_2(date,pHID,pHTID,&Y,&SST,pxID,pxCID,&SEC,pE,pF,NULL);
#endif // SINGLE_PASS

    if (rtn!=0)
    {
        printf("Server says - Bad Pin.\n");
#ifdef PINERROR

        err=MPIN_BLS381_KANGAROO(&E,&F);
        if (err) printf("(Client PIN is out by %d)\n",err);

#endif
        return 1;
    }
    else
    {
        printf("Server says - PIN is good! You really are ");
        OCT_output_string(&CLIENT_ID);
        printf(".\n");
    }

#ifdef FULL

    HASH_ALL(HASH_TYPE_BLS381,&HCID,pxID,pxCID,&SEC,&Y,&Z,&T,&H);  // new
    MPIN_BLS381_CLIENT_KEY(HASH_TYPE_BLS381,&G1,&G2,pin,&R,&X,&H,&T,&CK);      // new H
    printf("Client Key = ");
    OCT_output(&CK);

    HASH_ALL(HASH_TYPE_BLS381,&HSID,pxID,pxCID,&SEC,&Y,&Z,&T,&H);
    MPIN_BLS381_SERVER_KEY(HASH_TYPE_BLS381,&Z,&SST,&W,&H,pHID,pxID,pxCID,&SK); // new H,pHID
    printf("Server Key = ");
    OCT_output(&SK);
#endif
    return 0;
}

int rsa_2048(csprng *RNG)
{
    int i;
    unsigned long ran;
    char m[RFS_2048],ml[RFS_2048],c[RFS_2048],e[RFS_2048],s[RFS_2048];
    rsa_public_key_2048 pub;
    rsa_private_key_2048 priv;

    octet M= {0,sizeof(m),m};
    octet ML= {0,sizeof(ml),ml};
    octet C= {0,sizeof(c),c};
    octet E= {0,sizeof(e),e};
    octet S= {0,sizeof(s),s};

    printf("Generating public/private key pair\n");
    RSA_2048_KEY_PAIR(RNG,65537,&priv,&pub,NULL,NULL);

    printf("Encrypting test string\n");
    OCT_jstring(&M,(char *)"Hello World\n");

    OAEP_ENCODE(HASH_TYPE_RSA_2048,&M,RNG,NULL,&E); // OAEP encode message m to e

    RSA_2048_ENCRYPT(&pub,&E,&C);     // encrypt encoded message
    printf("Ciphertext= ");
    OCT_output(&C);

    printf("Decrypting test string\n");
    RSA_2048_DECRYPT(&priv,&C,&ML);   // ... and then decrypt it

    OAEP_DECODE(HASH_TYPE_RSA_2048,NULL,&ML);    // decode it
    OCT_output_string(&ML);

    printf("Signing message\n");
    PKCS15(HASH_TYPE_RSA_2048,&M,&C);

    RSA_2048_DECRYPT(&priv,&C,&S); // create signature in S

    printf("Signature= ");
    OCT_output(&S);

    RSA_2048_ENCRYPT(&pub,&S,&ML);

    if (OCT_comp(&C,&ML)) printf("Signature is valid\n");
    else printf("Signature is INVALID\n");

    RSA_2048_PRIVATE_KEY_KILL(&priv);

    OCT_clear(&M);
    OCT_clear(&ML);   // clean up afterwards
    OCT_clear(&C);
    OCT_clear(&E);

    return 0;
}


int rsa_3072(csprng *RNG)
{
    int i;
    unsigned long ran;
    char m[RFS_3072],ml[RFS_3072],c[RFS_3072],e[RFS_3072],s[RFS_3072];
    rsa_public_key_3072 pub;
    rsa_private_key_3072 priv;

    octet M= {0,sizeof(m),m};
    octet ML= {0,sizeof(ml),ml};
    octet C= {0,sizeof(c),c};
    octet E= {0,sizeof(e),e};
    octet S= {0,sizeof(s),s};

    printf("Generating public/private key pair\n");
    RSA_3072_KEY_PAIR(RNG,65537,&priv,&pub,NULL,NULL);

    printf("Encrypting test string\n");
    OCT_jstring(&M,(char *)"Hello World\n");

    OAEP_ENCODE(HASH_TYPE_RSA_3072,&M,RNG,NULL,&E); // OAEP encode message m to e

    RSA_3072_ENCRYPT(&pub,&E,&C);     // encrypt encoded message
    printf("Ciphertext= ");
    OCT_output(&C);

    printf("Decrypting test string\n");
    RSA_3072_DECRYPT(&priv,&C,&ML);   // ... and then decrypt it

    OAEP_DECODE(HASH_TYPE_RSA_3072,NULL,&ML);    // decode it
    OCT_output_string(&ML);

    printf("Signing message\n");
    PKCS15(HASH_TYPE_RSA_3072,&M,&C);

    RSA_3072_DECRYPT(&priv,&C,&S); // create signature in S

    printf("Signature= ");
    OCT_output(&S);

    RSA_3072_ENCRYPT(&pub,&S,&ML);

    if (OCT_comp(&C,&ML)) printf("Signature is valid\n");
    else printf("Signature is INVALID\n");

    RSA_3072_PRIVATE_KEY_KILL(&priv);

    OCT_clear(&M);
    OCT_clear(&ML);   // clean up afterwards
    OCT_clear(&C);
    OCT_clear(&E);

    return 0;
}


int main()
{
    int i,res;
    unsigned long ran;

    char raw[100];
    octet RAW= {0,sizeof(raw),raw};
    csprng RNG;                // Crypto Strong RNG

    time((time_t *)&ran);

    RAW.len=100;				// fake random seed source
    RAW.val[0]=ran;
    RAW.val[1]=ran>>8;
    RAW.val[2]=ran>>16;
    RAW.val[3]=ran>>24;
    for (i=0; i<100; i++) RAW.val[i]=i;

    CREATE_CSPRNG(&RNG,&RAW);   // initialise strong RNG

    printf("\nTesting MPIN protocols for curve BLS381\n");
    mpin_BLS381(&RNG);
    printf("\nTesting ECDH protocols for curve ED25519\n");
    ecdh_ED25519(&RNG);
#if CHUNK!=16
    printf("\nTesting ECDH protocols for curve NIST256\n");
    ecdh_NIST256(&RNG);
    printf("\nTesting ECDH protocols for curve GOLDILOCKS\n");
    ecdh_GOLDILOCKS(&RNG);
#endif
    printf("\nTesting RSA protocols for 2048-bit RSA\n");
    rsa_2048(&RNG);

    printf("\nTesting RSA protocols for 3072-bit RSA\n");
    rsa_3072(&RNG);

    KILL_CSPRNG(&RNG);
}



