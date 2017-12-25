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

/**
 * @file wcc.c
 * @author Mike Scott and Kealan McCusker
 * @date 28th April 2016
 * @brief Wang / Chow Choo (WCC) definitions
 *
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "wcc.h"

// #define DEBUG

/* general purpose hashing functions */
static void start_hash(hash *sha)
{
  HASH_init(sha);
}

static void add_to_hash(hash *sha,octet *x)
{
  int i;
  for (i=0;i<x->len;i++)
  {
    /*printf("%d,",(unsigned char)x->val[i]);*/
    HASH_process(sha,x->val[i]);
  }
}

static void finish_hash(hash *sha,octet *w)
{
  int i;
  char hh[HASH_BYTES];
  HASH_hash(sha,hh);

  OCT_empty(w);
  OCT_jbytes(w,hh,HASH_BYTES);
  for (i=0;i<HASH_BYTES;i++) hh[i]=0;
}

/* map octet string to point on curve */
static void mapit(octet *h,ECP *P)
{
  BIG q,px;
  BIG_fromBytes(px,h->val);
  BIG_rcopy(q,Modulus);
  BIG_mod(px,q);

  while (!ECP_setx(P,px,0))
    BIG_inc(px,1);
}

/* maps to hash value to point on G2 */
static void mapit2(octet *h,ECP2 *Q)
{
  BIG q,one,Fx,Fy,x,hv;
  FP2 X;
  ECP2 T,K;
  BIG_fromBytes(hv,h->val);
  BIG_rcopy(q,Modulus);
  BIG_one(one);
  BIG_mod(hv,q);

  for (;;)
  {
    FP2_from_BIGs(&X,one,hv);
    if (ECP2_setx(Q,&X)) break;
    BIG_inc(hv,1);
  }

  /* Fast Hashing to G2 - Fuentes-Castaneda, Knapp and Rodriguez-Henriquez */
  BIG_rcopy(Fx,CURVE_Fra);
  BIG_rcopy(Fy,CURVE_Frb);
  FP2_from_BIGs(&X,Fx,Fy);
  BIG_rcopy(x,CURVE_Bnx);

  ECP2_copy(&T,Q);
  ECP2_mul(&T,x);
  ECP2_neg(&T);  /* our x is negative */
  ECP2_copy(&K,&T);
  ECP2_dbl(&K);
  ECP2_add(&K,&T);
  ECP2_affine(&K);

  ECP2_frob(&K,&X);
  ECP2_frob(Q,&X); ECP2_frob(Q,&X); ECP2_frob(Q,&X);
  ECP2_add(Q,&T);
  ECP2_add(Q,&K);
  ECP2_frob(&T,&X); ECP2_frob(&T,&X);
  ECP2_add(Q,&T);
  ECP2_affine(Q);
}

/* Hash number (optional) and octet to octet */
static void hashit(int n,octet *x,octet *h)
{
  int i,c[4];
  hash sha;
  char hh[HASH_BYTES];
  BIG px;

  HASH_init(&sha);
  if (n>0)
  {
    c[0]=(n>>24)&0xff;
    c[1]=(n>>16)&0xff;
    c[2]=(n>>8)&0xff;
    c[3]=(n)&0xff;
    for (i=0;i<4;i++) HASH_process(&sha,c[i]);
  }
  for (i=0;i<x->len;i++) HASH_process(&sha,x->val[i]);
  HASH_hash(&sha,hh);
  OCT_empty(h);
  OCT_jbytes(h,hh,HASH_BYTES);
  for (i=0;i<HASH_BYTES;i++) hh[i]=0;
}


/*! \brief Hash EC Points and Id to an integer 
 *
 *  Perform sha256 of EC Points and Id. Map to an integer modulus the 
 *  curve order
 * 
 *  <ol>
 *  <li> x = toInteger(sha256(A,B,C,D))
 *  <li> h = x % q where q is the curve order
 *  </ol>
 *
 *  @param  A        EC Point
 *  @param  B        EC Point
 *  @param  C        EC Point
 *  @param  D        Identity
 *  @return h        Integer
 */
void WCC_Hq(octet *A,octet *B,octet *C,octet *D,octet *h)
{
  int i;
  hash sha;
  char hh[HASH_BYTES];
  BIG q,hs;

  BIG_rcopy(q,CURVE_Order);

#ifdef DEBUG
  printf("WCC_Hq: A: ");
  OCT_output(A);
  printf("\n");
  printf("WCC_Hq: B: ");
  OCT_output(B);
  printf("\n");
  printf("WCC_Hq: C: ");
  OCT_output(C);
  printf("\n");
  printf("WCC_Hq: D: ");
  OCT_output(D);
  printf("\n");
#endif

  HASH_init(&sha);
  for (i=0;i<A->len;i++) {
    HASH_process(&sha,A->val[i]);
  }

  for (i=0;i<B->len;i++) {
    HASH_process(&sha,B->val[i]);
  }

  for (i=0;i<C->len;i++) {
    HASH_process(&sha,C->val[i]);
  }

  for (i=0;i<D->len;i++) {
    HASH_process(&sha,D->val[i]);
  }

  HASH_hash(&sha,hh);

  BIG_fromBytes(hs,hh);
  BIG_mod(hs,q);
  for (i=0;i<HASH_BYTES;i++) {
    hh[i]=0;
  }
  BIG_toBytes(h->val,hs);
  h->len=PGS;
}

/*! \brief Calculate value in G1 multiplied by an integer
 *
 *  Calculate a value in G1. VG1 = s*H1(ID) where ID is the identity.
 * 
 *  <ol>
 *  <li> VG1 = s*H1(ID)
 *  </ol>
 *
 *  @param  hashDone    ID value is already hashed if set to 1
 *  @param  S           integer modulus curve order
 *  @param  ID          ID value or sha256(ID)
 *  @param  VG1         EC point VG1 = s*H1(ID)
 *  @return rtn         Returns 0 if successful or else an error code  
 */
int WCC_GET_G1_MULTIPLE(int hashDone, octet *S,octet *ID,octet *VG1)
{
  BIG s;
  ECP P;
  char h[HASH_BYTES];
  octet H={0,sizeof(h),h};

  if (hashDone) {
    mapit(ID,&P);
  } else {
    hashit(0,ID,&H);
    mapit(&H,&P);
  }

  BIG_fromBytes(s,S->val);
  PAIR_G1mul(&P,s);

  ECP_toOctet(VG1,&P);
  return 0;
}

/*! \brief Calculate a value in G1 used for when time permits are enabled
 *
 *  Calculate a value in G1 used for when time permits are enabled
 * 
 *  <ol>
 *  <li> VG1 = s*H1(ID) + s*H1(date|sha256(ID))
 *  </ol>
 *
 *  @param  date        Epoch days
 *  @param  S           integer modulus curve order
 *  @param  ID          ID value or sha256(ID)
 *  @param  VG1         EC point in G1
 *  @return rtn         Returns 0 if successful or else an error code  
 */
int WCC_GET_G1_TPMULT(int date, octet *S,octet *ID,octet *VG1)
{
  BIG s;
  ECP P,Q;
  char h1[HASH_BYTES];
  octet H1={0,sizeof(h1),h1};
  char h2[HASH_BYTES];
  octet H2={0,sizeof(h2),h2};

  // H1(ID)
  hashit(0,ID,&H1);
  mapit(&H1,&P);

  // H1(date|sha256(ID))
  hashit(date,&H1,&H2);
  mapit(&H2,&Q);

  // P = P + Q
  ECP_add(&P,&Q);

  // P = s(P+Q)
  BIG_fromBytes(s,S->val);
  PAIR_G1mul(&P,s);

  ECP_toOctet(VG1,&P);
  return 0;
}

/*! \brief Calculate a value in G2 used for when time permits are enabled
 *
 *  Calculate a value in G2 used for when time permits are enabled
 * 
 *  <ol>
 *  <li> VG2 = s*H1(ID) + s*H1(date|sha256(ID))
 *  </ol>
 *
 *  @param  date        Epoch days
 *  @param  S           integer modulus curve order
 *  @param  ID          ID value or sha256(ID)
 *  @param  VG2         EC point in G2
 *  @return rtn         Returns 0 if successful or else an error code  
 */
int WCC_GET_G2_TPMULT(int date, octet *S,octet *ID,octet *VG2)
{
  BIG s;
  ECP2 P,Q;
  char h1[HASH_BYTES];
  octet H1={0,sizeof(h1),h1};
  char h2[HASH_BYTES];
  octet H2={0,sizeof(h2),h2};

  // H1(ID)
  hashit(0,ID,&H1);
  mapit2(&H1,&P);

  // H1(date|sha256(ID))
  hashit(date,&H1,&H2);
  mapit2(&H2,&Q);

  // P = P + Q
  ECP2_add(&P,&Q);

  // P = s(P+Q)
  BIG_fromBytes(s,S->val);
  PAIR_G2mul(&P,s);

  ECP2_toOctet(VG2,&P);
  return 0;
}

/*! \brief Calculate value in G2 multiplied by an integer
 *
 *  Calculate a value in G2. VG2 = s*H2(ID) where ID is the identity.
 * 
 *  <ol>
 *  <li> VG2 = s*H2(ID)
 *  </ol>
 *
 *  @param  hashDone  ID is value is already hashed if set to 1
 *  @param  S         integer modulus curve order
 *  @param  ID        ID Value or sha256(ID)
 *  @param  VG2       EC Point VG2 = s*H2(ID)
 *  @return rtn       Returns 0 if successful or else an error code  
 */
int WCC_GET_G2_MULTIPLE(int hashDone, octet *S,octet *ID,octet *VG2)
{
  BIG s;
  ECP2 P;
  char h[HASH_BYTES];
  octet H={0,sizeof(h),h};

  if (hashDone) {
    mapit2(ID,&P);
  } else {
    hashit(0,ID,&H);
    mapit2(&H,&P);
  }

  BIG_fromBytes(s,S->val);
  PAIR_G2mul(&P,s);

  ECP2_toOctet(VG2,&P);
  return 0;
}

/*! \brief Calculate time permit in G2 
 *
 *  Calculate time permit in G2. 
 * 
 *  <ol>
 *  <li> TPG2=s*H2(date|sha256(ID))
 *  </ol>
 *
 *  @param  date      Epoch days
 *  @param  S         Master secret
 *  @param  HID       sha256(ID)
 *  @param  TPG2      Time Permit in G2
 *  @return rtn       Returns 0 if successful or else an error code  
 */
int WCC_GET_G2_PERMIT(int date,octet *S,octet *HID,octet *TPG2)
{
  BIG s;
  ECP2 P;
  char h[HASH_BYTES];
  octet H={0,sizeof(h),h};

  hashit(date,HID,&H);
  mapit2(&H,&P);
  BIG_fromBytes(s,S->val);
  PAIR_G2mul(&P,s);

  ECP2_toOctet(TPG2,&P);
  return 0;
}

/*! \brief Calculate the sender AES key
 *
 *  Calculate the sender AES Key
 * 
 *  <ol>
 *  <li> j=e((x+pia).AKeyG1,pib.BG2+PbG2)
 *  <li> K=H(j,x.PgG1)
 *  </ol>
 *
 *  @param  date        Epoch days
 *  @param  xOct        Random x < q where q is the curve order
 *  @param  piaOct      Hq(PaG1,PbG2,PgG1)
 *  @param  pibOct      Hq(PbG2,PaG1,PgG1)
 *  @param  PbG2Oct     y.BG2 where y < q
 *  @param  PgG1Oct     w.AG1 where w < q
 *  @param  AKeyG1Oct   Sender key 
 *  @param  ATPG1Oct    Sender time permit 
 *  @param  IdBOct      Receiver identity
 *  @return AESKeyOct   AES key
 *  @return rtn         Returns 0 if successful or else an error code  
 */
int WCC_SENDER_KEY(int date, octet *xOct, octet *piaOct, octet *pibOct, octet *PbG2Oct, octet *PgG1Oct, octet *AKeyG1Oct, octet *ATPG1Oct, octet *IdBOct, octet *AESKeyOct)
{
  ECP sAG1,ATPG1,PgG1;
  ECP2 BG2,dateBG2,PbG2;
  char hv1[HASH_BYTES],hv2[HASH_BYTES];
  octet HV1={0,sizeof(hv1),hv1};
  octet HV2={0,sizeof(hv2),hv2};

  // Pairing outputs
  FP12 g;
  char pair[12*PFS];
  octet PAIR={0,sizeof(pair),pair};

  FP4 c;
  BIG t,x,z,pia,pib;
  char ht[HASH_BYTES];
  octet HT={0,sizeof(ht),ht};
  hash sha;
  char xpgg1[2*PFS+1];
  octet xPgG1Oct={0,sizeof(xpgg1), xpgg1};

  BIG_fromBytes(x,xOct->val);
  BIG_fromBytes(pia,piaOct->val);
  BIG_fromBytes(pib,pibOct->val);

  if (!ECP2_fromOctet(&PbG2,PbG2Oct)) {
#ifdef DEBUG
    printf("PbG2Oct Invalid Point: ");
    OCT_output(PbG2Oct);
    printf("\n");
#endif
    return WCC_INVALID_POINT;
  }

  if (!ECP_fromOctet(&PgG1,PgG1Oct)) {
#ifdef DEBUG
    printf("PgG1Oct Invalid Point: ");
    OCT_output(PgG1Oct);
    printf("\n");
#endif
    return WCC_INVALID_POINT;
  }

  hashit(0,IdBOct,&HV1);
  mapit2(&HV1,&BG2);

  if (!ECP_fromOctet(&sAG1,AKeyG1Oct)) {
#ifdef DEBUG
    printf("AKeyG1Oct Invalid Point: ");
    OCT_output(AKeyG1Oct);
    printf("\n");
#endif
    return WCC_INVALID_POINT;
  }

  // Use time permits
  if (date)
    {
      // calculate e( (s*A+s*H(date|H(AID))) , (B+H(date|H(BID))) )
      if (!ECP_fromOctet(&ATPG1,ATPG1Oct)) {
#ifdef DEBUG
        printf("ATPG1Oct Invalid Point: ");
        OCT_output(ATPG1Oct);
        printf("\n");
        return WCC_INVALID_POINT;
#endif
      }

      // H2(date|sha256(IdB))
      hashit(date,&HV1,&HV2);
      mapit2(&HV2,&dateBG2);

      // sAG1 = sAG1 + ATPG1
      ECP_add(&sAG1, &ATPG1);
      // BG2 = BG2 + H(date|H(IdB))
      ECP2_add(&BG2, &dateBG2);
    }
  // z =  x + pia
  BIG_add(z,x,pia);

  // (x+pia).AKeyG1
  PAIR_G1mul(&sAG1,z);

  // pib.BG2
  PAIR_G2mul(&BG2,pib);

  // pib.BG2+PbG2
  ECP2_add(&BG2, &PbG2);

  PAIR_ate(&g,&BG2,&sAG1);
  PAIR_fexp(&g);
  // printf("WCC_SENDER_KEY e(sAG1,BG2) = ");FP12_output(&g); printf("\n");

  // x.PgG1
  PAIR_G1mul(&PgG1,x);
  ECP_toOctet(&xPgG1Oct,&PgG1);

  // Generate AES Key : K=H(k,x.PgG1)
  FP12_trace(&c,&g);
  HT.len=HASH_BYTES;
  start_hash(&sha);
  BIG_copy(t,c.a.a); FP_redc(t); BIG_toBytes(&(HT.val[0]),t);
  add_to_hash(&sha,&HT);
  BIG_copy(t,c.a.b); FP_redc(t); BIG_toBytes(&(HT.val[0]),t);
  add_to_hash(&sha,&HT);
  BIG_copy(t,c.b.a); FP_redc(t); BIG_toBytes(&(HT.val[0]),t);
  add_to_hash(&sha,&HT);
  BIG_copy(t,c.b.b); FP_redc(t); BIG_toBytes(&(HT.val[0]),t);
  add_to_hash(&sha,&HT);
  add_to_hash(&sha,&xPgG1Oct);
  finish_hash(&sha,&HT);
  OCT_empty(AESKeyOct);
  OCT_jbytes(AESKeyOct,HT.val,PAS);

  return 0;
}

/*! \brief Calculate the receiver AES key
 *
 *  Calculate time permit in G2. 
 * 
 *  <ol>
 *  <li> j=e(pia.AG1+PaG1,(y+pib).BKeyG2)
 *  <li> K=H(j,w.PaG1)
 *  </ol>
 *
 *  @param  date        Epoch days
 *  @param  yOct        Random y < q where q is the curve order
 *  @param  wOct        Random w < q where q is the curve order
 *  @param  piaOct      Hq(PaG1,PbG2,PgG1)
 *  @param  pibOct      Hq(PbG2,PaG1,PgG1)
 *  @param  PaG1Oct     x.AG1 where x < q
 *  @param  PgG1Oct     w.AG1 where w < q
 *  @param  BKeyG2Oct   Receiver key 
 *  @param  BTPG2Oct    Receiver time permit 
 *  @param  IdAOct      Sender identity
 *  @return AESKeyOct   AES key
 *  @return rtn         Returns 0 if successful or else an error code  
 */
int WCC_RECEIVER_KEY(int date, octet *yOct, octet *wOct,  octet *piaOct, octet *pibOct,  octet *PaG1Oct, octet *PgG1Oct, octet *BKeyG2Oct,octet *BTPG2Oct,  octet *IdAOct, octet *AESKeyOct)
{
  ECP AG1,dateAG1,PgG1,PaG1;
  ECP2 sBG2,BTPG2;
  char hv1[HASH_BYTES],hv2[HASH_BYTES];
  octet HV1={0,sizeof(hv1),hv1};
  octet HV2={0,sizeof(hv2),hv2};

  // Pairing outputs
  FP12 g;
  char pair[12*PFS];
  octet PAIR={0,sizeof(pair),pair};

  FP4 c;
  BIG t,w,y,pia,pib;;
  char ht[HASH_BYTES];
  octet HT={0,sizeof(ht),ht};
  hash sha;
  char wpag1[2*PFS+1];
  octet wPaG1Oct={0,sizeof(wpag1), wpag1};
  BIG_fromBytes(y,yOct->val);
  BIG_fromBytes(w,wOct->val);
  BIG_fromBytes(pia,piaOct->val);
  BIG_fromBytes(pib,pibOct->val);

  if (!ECP_fromOctet(&PaG1,PaG1Oct))
    return WCC_INVALID_POINT;

  if (!ECP_fromOctet(&PgG1,PgG1Oct))
    return WCC_INVALID_POINT;

  hashit(0,IdAOct,&HV1);
  mapit(&HV1,&AG1);

  if (!ECP2_fromOctet(&sBG2,BKeyG2Oct))
    return WCC_INVALID_POINT;

  if (date) {       
    // Calculate e( (A+H(date|H(AID))) , (s*B+s*H(date|H(IdB))) )
    if (!ECP2_fromOctet(&BTPG2,BTPG2Oct))   
      return WCC_INVALID_POINT;

    // H1(date|sha256(AID))
    hashit(date,&HV1,&HV2);
    mapit(&HV2,&dateAG1);

    // sBG2 = sBG2 + TPG2
    ECP2_add(&sBG2, &BTPG2);
    // AG1 = AG1 + H(date|H(AID))
    ECP_add(&AG1, &dateAG1);
  }
  // y =  y + pib
  BIG_add(y,y,pib);

  // (y+pib).BKeyG2
  PAIR_G2mul(&sBG2,y);

  // pia.AG1
  PAIR_G1mul(&AG1,pia);

  // pia.AG1+PaG1
  ECP_add(&AG1, &PaG1);

  PAIR_ate(&g,&sBG2,&AG1);
  PAIR_fexp(&g);
  // printf("WCC_RECEIVER_KEY e(AG1,sBG2) = ");FP12_output(&g); printf("\n");

  // w.PaG1
  PAIR_G1mul(&PaG1,w);
  ECP_toOctet(&wPaG1Oct,&PaG1);

  // Generate AES Key: K=H(k,w.PaG1)
  FP12_trace(&c,&g);
  HT.len=HASH_BYTES;
  start_hash(&sha);
  BIG_copy(t,c.a.a); FP_redc(t); BIG_toBytes(&(HT.val[0]),t);
  add_to_hash(&sha,&HT);
  BIG_copy(t,c.a.b); FP_redc(t); BIG_toBytes(&(HT.val[0]),t);
  add_to_hash(&sha,&HT);
  BIG_copy(t,c.b.a); FP_redc(t); BIG_toBytes(&(HT.val[0]),t);
  add_to_hash(&sha,&HT);
  BIG_copy(t,c.b.b); FP_redc(t); BIG_toBytes(&(HT.val[0]),t);
  add_to_hash(&sha,&HT);
  add_to_hash(&sha,&wPaG1Oct);
  finish_hash(&sha,&HT);
  OCT_empty(AESKeyOct);
  OCT_jbytes(AESKeyOct,HT.val,PAS);

  return 0;

}

/*! \brief Encrypt data using AES GCM
 *
 *  AES is run as a block cypher in the GCM  mode of operation. The key size is 128 bits.
 *  This function will encrypt any data length.
 *
 *  @param  K             128 bit secret key
 *  @param  IV            96 bit initialization vector
 *  @param  H             Additional authenticated data (AAD). This data is authenticated, but not encrypted.
 *  @param  P             Plaintext
 *  @return C             Ciphertext. It is the same length as the plaintext.
 *  @return T             128 bit authentication tag.
 */
void WCC_AES_GCM_ENCRYPT(octet *K,octet *IV,octet *H,octet *P,octet *C,octet *T)
{
  gcm g;
  GCM_init(&g,K->val,IV->len,IV->val);
  GCM_add_header(&g,H->val,H->len);
  GCM_add_plain(&g,C->val,P->val,P->len);
  C->len=P->len;
  GCM_finish(&g,T->val);
  T->len=16;
}

/*! \brief Decrypt data using AES GCM
 *
 *  AES is run as a block cypher in the GCM  mode of operation. The key size is 128 bits.
 *  This function will decrypt any data length.
 *
 *  @param  K             128 bit secret key
 *  @param  IV            96 bit initialization vector
 *  @param  H             Additional authenticated data (AAD). This data is authenticated, but not encrypted.
 *  @param  C             Ciphertext.
 *  @return P             Decrypted data. It is the same length as the ciphertext.Plaintext
 *  @return T             128 bit authentication tag.
 */
void WCC_AES_GCM_DECRYPT(octet *K,octet *IV,octet *H,octet *C,octet *P,octet *T)
{
  gcm g;
  GCM_init(&g,K->val,IV->len,IV->val);
  GCM_add_header(&g,H->val,H->len);
  GCM_add_cipher(&g,P->val,C->val,C->len);
  P->len=C->len;
  GCM_finish(&g,T->val);
  T->len=16;
}

/*!  \brief Get today's date as days from the epoch
 *
 *   @return today's date, as number of days elapsed since the epoch
 */
unsign32 WCC_today(void)
{
  unsign32 ti=(unsign32)time(NULL);
  return (long)(ti/(60*TIME_SLOT_MINUTES));
}

/*!  \brief Initialise a random number generator
 *
 *   @param RNG     cryptographically secure random number generator
 *   @param SEED    random seed value
 */
void WCC_CREATE_CSPRNG(csprng *RNG,octet *SEED)
{
  RAND_seed(RNG,SEED->len,SEED->val);
}

/*!  \brief Kill a random number generator
 *   
 *   Deletes all internal state
 * 
 *   @param RNG    cryptographically secure random number generator
 */
void WCC_KILL_CSPRNG(csprng *RNG)
{
  RAND_clean(RNG);
}

/*!  \brief Perform sha256
 *   
 *   Hash ID
 * 
 *   @param  ID     Value to hash
 *   @return HID    sha256 hashed value
 */
void WCC_HASH_ID(octet *ID,octet *HID)
{
  hashit(0,ID,HID);
}

/*!  \brief Generate a random integer
 *   
 *   Generate a random number modulus the group order
 * 
 *   @param  RNG    cryptographically secure random number generator
 *   @return S      Random integer modulus the group order
 */
int WCC_RANDOM_GENERATE(csprng *RNG,octet* S)
{
  BIG r,s;
  BIG_rcopy(r,CURVE_Order);
  BIG_randomnum(s,r,RNG);
  BIG_toBytes(S->val,s);
  S->len=PGS;
  return 0;
}


/*! \brief Calculate time permit in G2 
 *
 *  Calculate time permit in G2. 
 * 
 *  <ol>
 *  <li> TPG1=s*H1(date|sha256(ID))
 *  </ol>
 *
 *  @param  date      Epoch days
 *  @param  S         Master secret
 *  @param  HID       sha256(ID)
 *  @param  TPG1      Time Permit in G1
 *  @return rtn       Returns 0 if successful or else an error code  
 */
int WCC_GET_G1_PERMIT(int date,octet *S,octet *HID,octet *TPG1)
{
  BIG s;
  ECP P;
  char h[HASH_BYTES];
  octet H={0,sizeof(h),h};

  hashit(date,HID,&H);
  mapit(&H,&P);
  BIG_fromBytes(s,S->val);
  PAIR_G1mul(&P,s);

  ECP_toOctet(TPG1,&P);
  return 0;
}

/*! \brief Add two members from the group G1
 *
 *   @param  R1      member of G1 
 *   @param  R2      member of G1 
 *   @return R       member of G1 = R1+R2
 *   @return         Returns 0 if successful or else an error code
 */
int WCC_RECOMBINE_G1(octet *R1,octet *R2,octet *R)
{
  ECP P,T;
  int res=0;
  if (!ECP_fromOctet(&P,R1)) res=WCC_INVALID_POINT;
  if (!ECP_fromOctet(&T,R2)) res=WCC_INVALID_POINT;
  if (res==0)
  {
    ECP_add(&P,&T);
    ECP_toOctet(R,&P);
  }
  return res;
}

/*! \brief Add two members from the group G2
 *
 *   @param  W1      member of G2 
 *   @param  W2      member of G2 
 *   @return W       member of G2 = W1+W2
 *   @return         Weturns 0 if successful or else an error code
 */
int WCC_RECOMBINE_G2(octet *W1,octet *W2,octet *W)
{
  ECP2 Q,T;
  int res=0;
  if (!ECP2_fromOctet(&Q,W1)) res=WCC_INVALID_POINT;
  if (!ECP2_fromOctet(&T,W2)) res=WCC_INVALID_POINT;
  if (res==0)
  {
    ECP2_add(&Q,&T);
    ECP2_toOctet(W,&Q);
  }
  return res;
}
