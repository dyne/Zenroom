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

/* Boneh-Lynn-Shacham signature 192-bit API */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "bls192_ZZZ.h"

// Polynomial interpolation coefficients
static void recover_coefficients(int k, octet* X, BIG_XXX* coefs)
{
    BIG_XXX r;
    BIG_XXX_rcopy(r,CURVE_Order_ZZZ);

    BIG_XXX x2[k];

    for(int i=0; i<k; i++)
    {
        BIG_XXX_fromBytes(x2[i],X[i].val);
    }

    // Compute numerators in place using partial products
    // to achieve it in O(n)
    // c_i = x_0 * ... * x_(i-1) * x_(i+1) * ... * x_(k-1)

    // Compute partial left products
    // leave c_0 alone since it only has a right partial product
    BIG_XXX_copy(coefs[1], x2[0]);

    for(int i=2; i < k; i++)
    {
        // lp_i = x_0 * ... * x_(i-1) = lp_(i-1) * x_(i-1)
        BIG_XXX_modmul(coefs[i], coefs[i-1], x2[i-1], r);
    }

    // Compute partial right products and combine

    // Store partial right products in c_0 so at the end
    // of the procedure c_0 = x_1 * ... x_(k-1)
    BIG_XXX_copy(coefs[0], x2[k-1]);

    for(int i=k-2; i > 0; i--)
    {
        // c_i = lp_i * rp_i
        BIG_XXX_modmul(coefs[i], coefs[i], coefs[0], r);

        // rp_(i-1) = x_i * ... * x_k = x_i * rp_i
        BIG_XXX_modmul(coefs[0], coefs[0], x2[i], r);
    }

    BIG_XXX cneg;
    BIG_XXX denominator;
    BIG_XXX s;

    for(int i=0; i<k; i++)
    {
        BIG_XXX_one(denominator);

        // cneg = -x_i mod r
        BIG_XXX_sub(cneg, r, x2[i]);

        for(int j=0; j<k; j++)
        {
            if (i != j)
            {
                // denominator = denominator * (x_j - x_i)
                BIG_XXX_add(s,x2[j],cneg);
                BIG_XXX_modmul(denominator,denominator,s,r);
            }
        }

        BIG_XXX_moddiv(coefs[i], coefs[i], denominator, r);
    }
}

/* hash a message, M, to an ECP point, using SHA3 */
static void BLS_HASHIT(ECP_ZZZ *P,octet *M)
{
    int i;
    int j;
    sha3 hs;
    char h[MODBYTES_XXX];
    octet HM= {0,sizeof(h),h};
    SHA3_init(&hs,SHAKE256);
    for (i=0; i<M->len; i++)
    {
        j = (unsigned char) M->val[i];
        SHA3_process(&hs,j);
    }
    SHA3_shake(&hs,HM.val,MODBYTES_XXX);
    HM.len=MODBYTES_XXX;
    ECP_ZZZ_mapit(P,&HM);
}

/* generate key pair, private key S, public key W */
int BLS_ZZZ_KEY_PAIR_GENERATE(csprng *RNG,octet* S,octet *W)
{
    ECP4_ZZZ G;
    BIG_XXX s,q;
    BIG_XXX_rcopy(q,CURVE_Order_ZZZ);
    ECP4_ZZZ_generator(&G);

    if (RNG!=NULL)
    {
        BIG_XXX_randomnum(s,q,RNG);
        BIG_XXX_toBytes(S->val,s);
        S->len=MODBYTES_XXX;
    }
    else
    {
        S->len=MODBYTES_XXX;
        BIG_XXX_fromBytes(s,S->val);
    }

    PAIR_ZZZ_G2mul(&G,s);
    ECP4_ZZZ_toOctet(W,&G);

    return BLS_OK;
}

/* Sign message M using private key S to produce signature SIG */
int BLS_ZZZ_SIGN(octet *SIG,octet *M,octet *S)
{
    BIG_XXX s;
    ECP_ZZZ D;
    BLS_HASHIT(&D,M);
    BIG_XXX_fromBytes(s,S->val);
    PAIR_ZZZ_G1mul(&D,s);
    ECP_ZZZ_toOctet(SIG,&D,true); /* compress output */

    return BLS_OK;
}

/* Verify signature given message M, the signature SIG, and the public key W */
int BLS_ZZZ_VERIFY(octet *SIG,octet *M,octet *W)
{
    FP24_YYY v;
    ECP4_ZZZ G,PK;
    ECP_ZZZ D,HM;
    BLS_HASHIT(&HM,M);

    if (!ECP_ZZZ_fromOctet(&D,SIG))
    {
        return BLS_INVALID_G1;
    }

    ECP4_ZZZ_generator(&G);

    if (!ECP4_ZZZ_fromOctet(&PK,W))
    {
        return BLS_INVALID_G2;
    }
    ECP_ZZZ_neg(&D);

    PAIR_ZZZ_double_ate(&v,&G,&D,&PK,&HM);
    PAIR_ZZZ_fexp(&v);

    if (!FP24_YYY_isunity(&v))
    {
        return BLS_FAIL;
    }

    return BLS_OK;
}


/* R=R1+R2 in group G1 */
int BLS_ZZZ_ADD_G1(octet *R1,octet *R2,octet *R)
{
    ECP_ZZZ P;
    ECP_ZZZ T;

    if (!ECP_ZZZ_fromOctet(&P,R1))
    {
        return BLS_INVALID_G1;
    }

    if (!ECP_ZZZ_fromOctet(&T,R2))
    {
        return BLS_INVALID_G1;
    }

    ECP_ZZZ_add(&P,&T);
    ECP_ZZZ_toOctet(R,&P,true);

    return BLS_OK;
}

/* W=W1+W2 in group G2 */
int BLS_ZZZ_ADD_G2(octet *W1,octet *W2,octet *W)
{
    ECP4_ZZZ Q;
    ECP4_ZZZ T;

    if (!ECP4_ZZZ_fromOctet(&Q,W1))
    {
        return BLS_INVALID_G2;
    }

    if (!ECP4_ZZZ_fromOctet(&T,W2))
    {
        return BLS_INVALID_G2;
    }

    ECP4_ZZZ_add(&Q,&T);
    ECP4_ZZZ_toOctet(W,&Q);

    return BLS_OK;
}

int BLS_ZZZ_MAKE_SHARES(int k, int n, csprng *RNG, octet* X, octet* Y, octet* SKI, octet* SKO)
{
    BIG_XXX r;
    BIG_XXX_rcopy(r,CURVE_Order_ZZZ);

    // Generate polynomial: f(x) = a_0 + a_1x + a_2x^2 ... a_{k-1}x^{k-1}
    BIG_XXX poly[k];
    for(int i=0; i<k; i++)
    {
        BIG_XXX_randomnum(poly[i],r,RNG);
    }

    // Use predefined secret
    if (SKI != NULL)
    {
        BIG_XXX_fromBytes(poly[0],SKI->val);
    }

    /* Calculate f(x) = a_0 + a_1x + a_2x^2 ... a_{k-1}x^{k-1}
       a0 is the secret */
    BIG_XXX x;
    BIG_XXX_zero(x);

    BIG_XXX y;

    for(int j=0; j<n; j++)
    {
        BIG_XXX_inc(x,1);

        // Output X shares
        BIG_XXX_toBytes(X[j].val,x);
        X[j].len = MODBYTES_XXX;

        // y is the accumulator
        BIG_XXX_zero(y);

        for(int i=k-1; i>=0; i--)
        {
            BIG_XXX_modmul(y,y,x,r);
            BIG_XXX_add(y,y,poly[i]);
        }

        // Normalise input for comp
        BIG_XXX_norm(y);
        if(BIG_XXX_comp(y,r) == 1)
        {
            BIG_XXX_sub(y,y,r);
        }

        // Output Y shares
        BIG_XXX_toBytes(Y[j].val,y);
        Y[j].len = MODBYTES_XXX;
    }

    // Output secret
    BIG_XXX_toBytes(SKO->val,poly[0]);
    SKO->len = MODBYTES_XXX;

    return BLS_OK;
}

int BLS_ZZZ_RECOVER_SECRET(int k, octet* X, octet* Y, octet* SK)
{
    BIG_XXX r;
    BIG_XXX_rcopy(r,CURVE_Order_ZZZ);

    BIG_XXX y;
    BIG_XXX coefs[k];

    BIG_XXX secret;
    BIG_XXX prod;
    BIG_XXX_zero(secret);

    recover_coefficients(k, X, coefs);

    for(int i=0; i<k; i++)
    {
        BIG_XXX_fromBytes(y,Y[i].val);

        BIG_XXX_modmul(prod,y,coefs[i],r);
        BIG_XXX_add(secret, secret, prod);

        // Normalise input for comp
        BIG_XXX_norm(secret);
        if (BIG_XXX_comp(secret,r) == 1)
        {
            BIG_XXX_sub(secret,secret,r);
        }
    }

    // Output secret
    BIG_XXX_toBytes(SK->val,secret);
    SK->len = MODBYTES_XXX;

    return BLS_OK;
}

int BLS_ZZZ_RECOVER_SIGNATURE(int k, octet* X, octet* Y, octet* SIG)
{
    BIG_XXX coefs[k];
    ECP_ZZZ y;

    ECP_ZZZ sig;
    ECP_ZZZ_inf(&sig);

    recover_coefficients(k, X, coefs);

    for(int i=0; i<k; i++)
    {
        if (!ECP_ZZZ_fromOctet(&y,&Y[i]))
        {
            return BLS_INVALID_G1;
        }

        PAIR_ZZZ_G1mul(&y,coefs[i]);
        ECP_ZZZ_add(&sig,&y);
    }

    ECP_ZZZ_toOctet(SIG, &sig, true);

    return BLS_OK;
}
