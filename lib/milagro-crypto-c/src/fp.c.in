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

/* AMCL mod p functions */
/* Small Finite Field arithmetic */
/* SU=m, SU is Stack Usage (NOT_SPECIAL Modulus) */

#include "fp_YYY.h"

/* Fast Modular Reduction Methods */

/* r=d mod m */
/* d MUST be normalised */
/* Products must be less than pR in all cases !!! */
/* So when multiplying two numbers, their product *must* be less than MODBITS+BASEBITS*NLEN */
/* Results *may* be one bit bigger than MODBITS */

#if MODTYPE_YYY == PSEUDO_MERSENNE
/* r=d mod m */

/* Converts from BIG integer to residue form mod Modulus */
void FP_YYY_nres(FP_YYY *y,BIG_XXX x)
{
    BIG_XXX_copy(y->g,x);
    y->XES=1;
}

/* Converts from residue form back to BIG integer form */
void FP_YYY_redc(BIG_XXX x,FP_YYY *y)
{
    BIG_XXX_copy(x,y->g);
}

/* reduce a DBIG to a BIG exploiting the special form of the modulus */
void FP_YYY_mod(BIG_XXX r,DBIG_XXX d)
{
    BIG_XXX t,b;
    chunk v,tw;
    BIG_XXX_split(t,b,d,MODBITS_YYY);

    /* Note that all of the excess gets pushed into t. So if squaring a value with a 4-bit excess, this results in
       t getting all 8 bits of the excess product! So products must be less than pR which is Montgomery compatible */

    if (MConst_YYY < NEXCESS_XXX)
    {
        BIG_XXX_imul(t,t,MConst_YYY);
        BIG_XXX_norm(t);
        BIG_XXX_add(r,t,b);
        BIG_XXX_norm(r);
        tw=r[NLEN_XXX-1];
        r[NLEN_XXX-1]&=TMASK_YYY;
        r[0]+=MConst_YYY*((tw>>TBITS_YYY));
    }
    else
    {
        v=BIG_XXX_pmul(t,t,MConst_YYY);
        BIG_XXX_add(r,t,b);
        BIG_XXX_norm(r);
        tw=r[NLEN_XXX-1];
        r[NLEN_XXX-1]&=TMASK_YYY;
#if CHUNK == 16
        r[1]+=muladd_XXX(MConst_YYY,((tw>>TBITS_YYY)+(v<<(BASEBITS_XXX-TBITS_YYY))),0,&r[0]);
#else
        r[0]+=MConst_YYY*((tw>>TBITS_YYY)+(v<<(BASEBITS_XXX-TBITS_YYY)));
#endif
    }
    BIG_XXX_norm(r);
}
#endif

/* This only applies to Curve C448, so specialised (for now) */
#if MODTYPE_YYY == GENERALISED_MERSENNE

void FP_YYY_nres(FP_YYY *y,BIG_XXX x)
{
    BIG_XXX_copy(y->g,x);
    y->XES=1;
}

/* Converts from residue form back to BIG integer form */
void FP_YYY_redc(BIG_XXX x,FP_YYY *y)
{
    BIG_XXX_copy(x,y->g);
}

/* reduce a DBIG to a BIG exploiting the special form of the modulus */
void FP_YYY_mod(BIG_XXX r,DBIG_XXX d)
{
    BIG_XXX t,b;
    chunk carry;
    BIG_XXX_split(t,b,d,MBITS_YYY);

    BIG_XXX_add(r,t,b);

    BIG_XXX_dscopy(d,t);
    BIG_XXX_dshl(d,MBITS_YYY/2);

    BIG_XXX_split(t,b,d,MBITS_YYY);

    BIG_XXX_add(r,r,t);
    BIG_XXX_add(r,r,b);
    BIG_XXX_norm(r);
    BIG_XXX_shl(t,MBITS_YYY/2);

    BIG_XXX_add(r,r,t);

    carry=r[NLEN_XXX-1]>>TBITS_YYY;

    r[NLEN_XXX-1]&=TMASK_YYY;
    r[0]+=carry;

    r[224/BASEBITS_XXX]+=carry<<(224%BASEBITS_XXX); /* need to check that this falls mid-word */
    BIG_XXX_norm(r);
}

#endif

#if MODTYPE_YYY == MONTGOMERY_FRIENDLY

/* convert to Montgomery n-residue form */
void FP_YYY_nres(FP_YYY *y,BIG_XXX x)
{
    DBIG_XXX d;
    BIG_XXX r;
    BIG_XXX_rcopy(r,R2modp_YYY);
    BIG_XXX_mul(d,x,r);
    FP_YYY_mod(y->g,d);
    y->XES=2;
}

/* convert back to regular form */
void FP_YYY_redc(BIG_XXX x,FP_YYY *y)
{
    DBIG_XXX d;
    BIG_XXX_dzero(d);
    BIG_XXX_dscopy(d,y->g);
    FP_YYY_mod(x,d);
}

/* fast modular reduction from DBIG to BIG exploiting special form of the modulus */
void FP_YYY_mod(BIG_XXX a,DBIG_XXX d)
{
    int i;

    for (i=0; i<NLEN_XXX; i++)
        d[NLEN_XXX+i]+=muladd_XXX(d[i],MConst_YYY-1,d[i],&d[NLEN_XXX+i-1]);

    BIG_XXX_sducopy(a,d);
    BIG_XXX_norm(a);
}

#endif

#if MODTYPE_YYY == NOT_SPECIAL

/* convert to Montgomery n-residue form */
void FP_YYY_nres(FP_YYY *y,BIG_XXX x)
{
    DBIG_XXX d;
    BIG_XXX r;
    BIG_XXX_rcopy(r,R2modp_YYY);
    BIG_XXX_mul(d,x,r);
    FP_YYY_mod(y->g,d);
    y->XES=2;
}

/* convert back to regular form */
void FP_YYY_redc(BIG_XXX x,FP_YYY *y)
{
    DBIG_XXX d;
    BIG_XXX_dzero(d);
    BIG_XXX_dscopy(d,y->g);
    FP_YYY_mod(x,d);
}


/* reduce a DBIG to a BIG using Montgomery's no trial division method */
/* d is expected to be dnormed before entry */
/* SU= 112 */
void FP_YYY_mod(BIG_XXX a,DBIG_XXX d)
{
    BIG_XXX mdls;
    BIG_XXX_rcopy(mdls,Modulus_YYY);
    BIG_XXX_monty(a,mdls,MConst_YYY,d);
}

#endif

/* test x==0 ? */
/* SU= 48 */
int FP_YYY_iszilch(FP_YYY *x)
{
    BIG_XXX m;
    BIG_XXX_rcopy(m,Modulus_YYY);
    BIG_XXX_mod(x->g,m);
    return BIG_XXX_iszilch(x->g);
}

void FP_YYY_copy(FP_YYY *y,FP_YYY *x)
{
    BIG_XXX_copy(y->g,x->g);
    y->XES=x->XES;
}

void FP_YYY_rcopy(FP_YYY *y, const BIG_XXX c)
{
    BIG_XXX b;
    BIG_XXX_rcopy(b,c);
    FP_YYY_nres(y,b);
}

/* Swap a and b if d=1 */
void FP_YYY_cswap(FP_YYY *a,FP_YYY *b,int d)
{
    sign32 t,c=d;
    BIG_XXX_cswap(a->g,b->g,d);

    c=~(c-1);
    t=c&((a->XES)^(b->XES));
    a->XES^=t;
    b->XES^=t;

}

/* Move b to a if d=1 */
void FP_YYY_cmove(FP_YYY *a,FP_YYY *b,int d)
{
    sign32 c=-d;

    BIG_XXX_cmove(a->g,b->g,d);
    a->XES^=(a->XES^b->XES)&c;
}

void FP_YYY_zero(FP_YYY *x)
{
    BIG_XXX_zero(x->g);
    x->XES=1;
}

int FP_YYY_equals(FP_YYY *x,FP_YYY *y)
{
    FP_YYY_reduce(x);
    FP_YYY_reduce(y);
    if (BIG_XXX_comp(x->g,y->g)==0) return 1;
    return 0;
}

/* output FP */
/* SU= 48 */
void FP_YYY_output(FP_YYY *r)
{
    BIG_XXX c;
    FP_YYY_redc(c,r);
    BIG_XXX_output(c);
}

void FP_YYY_rawoutput(FP_YYY *r)
{
    BIG_XXX_rawoutput(r->g);
}

#ifdef GET_STATS
int tsqr=0,rsqr=0,tmul=0,rmul=0;
int tadd=0,radd=0,tneg=0,rneg=0;
int tdadd=0,rdadd=0,tdneg=0,rdneg=0;
#endif

#ifdef FUSED_MODMUL

/* Insert fastest code here */

#endif

/* r=a*b mod Modulus */
/* product must be less that p.R - and we need to know this in advance! */
/* SU= 88 */
void FP_YYY_mul(FP_YYY *r,FP_YYY *a,FP_YYY *b)
{
    DBIG_XXX d;

    if ((sign64)a->XES*b->XES>(sign64)FEXCESS_YYY)
    {
#ifdef DEBUG_REDUCE
        printf("Product too large - reducing it\n");
#endif
        FP_YYY_reduce(a);  /* it is sufficient to fully reduce just one of them < p */
    }

#ifdef FUSED_MODMUL
    FP_YYY_modmul(r->g,a->g,b->g);
#else
    BIG_XXX_mul(d,a->g,b->g);
    FP_YYY_mod(r->g,d);
#endif
    r->XES=2;
}


/* multiplication by an integer, r=a*c */
/* SU= 136 */
void FP_YYY_imul(FP_YYY *r,FP_YYY *a,int c)
{
    int s=0;

    if (c<0)
    {
        c=-c;
        s=1;
    }

#if MODTYPE_YYY==PSEUDO_MERSENNE || MODTYPE_YYY==GENERALISED_MERSENNE
    DBIG_XXX d;
    BIG_XXX_pxmul(d,a->g,c);
    FP_YYY_mod(r->g,d);
    r->XES=2;

#else
    //Montgomery
    BIG_XXX k;
    FP_YYY f;
    if (a->XES*c<=FEXCESS_YYY)
    {
        BIG_XXX_pmul(r->g,a->g,c);
        r->XES=a->XES*c;    // careful here - XES jumps!
    }
    else
    {
        // don't want to do this - only a problem for Montgomery modulus and larger constants
        BIG_XXX_zero(k);
        BIG_XXX_inc(k,c);
        BIG_XXX_norm(k);
        FP_YYY_nres(&f,k);
        FP_YYY_mul(r,a,&f);
    }
#endif
    if (s)
    {
        FP_YYY_neg(r,r);
        FP_YYY_norm(r);
    }
}

/* Set r=a^2 mod m */
/* SU= 88 */
void FP_YYY_sqr(FP_YYY *r,FP_YYY *a)
{
    DBIG_XXX d;

    if ((sign64)a->XES*a->XES>(sign64)FEXCESS_YYY)
    {
#ifdef DEBUG_REDUCE
        printf("Product too large - reducing it\n");
#endif
        FP_YYY_reduce(a);
    }

    BIG_XXX_sqr(d,a->g);
    FP_YYY_mod(r->g,d);
    r->XES=2;
}

/* SU= 16 */
/* Set r=a+b */
void FP_YYY_add(FP_YYY *r,FP_YYY *a,FP_YYY *b)
{
    BIG_XXX_add(r->g,a->g,b->g);
    r->XES=a->XES+b->XES;
    if (r->XES>FEXCESS_YYY)
    {
#ifdef DEBUG_REDUCE
        printf("Sum too large - reducing it \n");
#endif
        FP_YYY_reduce(r);
    }
}

/* Set r=a-b mod m */
/* SU= 56 */
void FP_YYY_sub(FP_YYY *r,FP_YYY *a,FP_YYY *b)
{
    FP_YYY n;
    FP_YYY_neg(&n,b);
    FP_YYY_add(r,a,&n);
}

/* SU= 48 */
/* Fully reduce a mod Modulus */
void FP_YYY_reduce(FP_YYY *a)
{
    BIG_XXX m;
    BIG_XXX_rcopy(m,Modulus_YYY);
    BIG_XXX_mod(a->g,m);
    a->XES=1;
}

void FP_YYY_norm(FP_YYY *x)
{
    BIG_XXX_norm(x->g);
}

// https://graphics.stanford.edu/~seander/bithacks.html
// constant time log to base 2 (or number of bits in)

static int logb2(unsign32 v)
{
    int r;
    v |= v >> 1;
    v |= v >> 2;
    v |= v >> 4;
    v |= v >> 8;
    v |= v >> 16;

    v = v - ((v >> 1) & 0x55555555);
    v = (v & 0x33333333) + ((v >> 2) & 0x33333333);
    r = (((v + (v >> 4)) & 0xF0F0F0F) * 0x1010101) >> 24;
    return r;
}

/* Set r=-a mod Modulus */
/* SU= 64 */
void FP_YYY_neg(FP_YYY *r,FP_YYY *a)
{
    int sb;
    BIG_XXX m;

    BIG_XXX_rcopy(m,Modulus_YYY);

    sb=logb2(a->XES-1);
    BIG_XXX_fshl(m,sb);
    BIG_XXX_sub(r->g,m,a->g);
    r->XES=((sign32)1<<sb);

    if (r->XES>FEXCESS_YYY)
    {
#ifdef DEBUG_REDUCE
        printf("Negation too large -  reducing it \n");
#endif
        FP_YYY_reduce(r);
    }

}

/* Set r=a/2. */
/* SU= 56 */
void FP_YYY_div2(FP_YYY *r,FP_YYY *a)
{
    BIG_XXX m;
    BIG_XXX_rcopy(m,Modulus_YYY);
    FP_YYY_copy(r,a);
    if (BIG_XXX_parity(a->g)==0)
    {

        BIG_XXX_fshr(r->g,1);
    }
    else
    {
        BIG_XXX_add(r->g,r->g,m);
        BIG_XXX_norm(r->g);
        BIG_XXX_fshr(r->g,1);
    }
}

/* set w=1/x */
void FP_YYY_inv(FP_YYY *w,FP_YYY *x)
{
    BIG_XXX m2;
    BIG_XXX_rcopy(m2,Modulus_YYY);
    BIG_XXX_dec(m2,2);
    BIG_XXX_norm(m2);
    FP_YYY_pow(w,x,m2);
}

/* SU=8 */
/* set n=1 */
void FP_YYY_one(FP_YYY *n)
{
    BIG_XXX b;
    BIG_XXX_one(b);
    FP_YYY_nres(n,b);
}

/* Set r=a^b mod Modulus */
/* SU= 136 */
void FP_YYY_pow(FP_YYY *r,FP_YYY *a,BIG_XXX b)
{
    sign8 w[1+(NLEN_XXX*BASEBITS_XXX+3)/4];
    FP_YYY tb[16];
    BIG_XXX t;
    int i,nb;

    FP_YYY_norm(a);
    BIG_XXX_norm(b);
    BIG_XXX_copy(t,b);
    nb=1+(BIG_XXX_nbits(t)+3)/4;
    /* convert exponent to 4-bit window */
    for (i=0; i<nb; i++)
    {
        w[i]=BIG_XXX_lastbits(t,4);
        BIG_XXX_dec(t,w[i]);
        BIG_XXX_norm(t);
        BIG_XXX_fshr(t,4);
    }

    FP_YYY_one(&tb[0]);
    FP_YYY_copy(&tb[1],a);
    for (i=2; i<16; i++)
        FP_YYY_mul(&tb[i],&tb[i-1],a);

    FP_YYY_copy(r,&tb[w[nb-1]]);
    for (i=nb-2; i>=0; i--)
    {
        FP_YYY_sqr(r,r);
        FP_YYY_sqr(r,r);
        FP_YYY_sqr(r,r);
        FP_YYY_sqr(r,r);
        FP_YYY_mul(r,r,&tb[w[i]]);
    }
    FP_YYY_reduce(r);
}

/* is r a QR? */
int FP_YYY_qr(FP_YYY *r)
{
    int j;
    BIG_XXX m;
    BIG_XXX b;
    BIG_XXX_rcopy(m,Modulus_YYY);
    FP_YYY_redc(b,r);
    j=BIG_XXX_jacobi(b,m);
    FP_YYY_nres(r,b);
    if (j==1) return 1;
    return 0;

}

/* Set a=sqrt(b) mod Modulus */
/* SU= 160 */
void FP_YYY_sqrt(FP_YYY *r,FP_YYY *a)
{
    FP_YYY v,i;
    BIG_XXX b;
    BIG_XXX m;
    BIG_XXX_rcopy(m,Modulus_YYY);
    BIG_XXX_mod(a->g,m);
    BIG_XXX_copy(b,m);
    if (MOD8_YYY==5)
    {
        BIG_XXX_dec(b,5);
        BIG_XXX_norm(b);
        BIG_XXX_fshr(b,3); /* (p-5)/8 */
        FP_YYY_copy(&i,a);
        BIG_XXX_fshl(i.g,1);
        FP_YYY_pow(&v,&i,b);
        FP_YYY_mul(&i,&i,&v);
        FP_YYY_mul(&i,&i,&v);
        BIG_XXX_dec(i.g,1);
        FP_YYY_mul(r,a,&v);
        FP_YYY_mul(r,r,&i);
        FP_YYY_reduce(r);
    }
    if (MOD8_YYY==3 || MOD8_YYY==7)
    {
        BIG_XXX_inc(b,1);
        BIG_XXX_norm(b);
        BIG_XXX_fshr(b,2); /* (p+1)/4 */
        FP_YYY_pow(r,a,b);
    }
}

/*
int main()
{

	BIG_XXX r;

	FP_YYY_one(r);
	FP_YYY_sqr(r,r);

	BIG_XXX_output(r);

	int i,carry;
	DBIG_XXX c={0,0,0,0,0,0,0,0};
	BIG_XXX a={1,2,3,4};
	BIG_XXX b={3,4,5,6};
	BIG_XXX r={11,12,13,14};
	BIG_XXX s={23,24,25,15};
	BIG_XXX w;

//	printf("NEXCESS_XXX= %d\n",NEXCESS_XXX);
//	printf("MConst_YYY= %d\n",MConst_YYY);

	BIG_XXX_copy(b,Modulus_YYY);
	BIG_XXX_dec(b,1);
	BIG_XXX_norm(b);

	BIG_XXX_randomnum(r); BIG_XXX_norm(r); BIG_XXX_mod(r,Modulus_YYY);
//	BIG_XXX_randomnum(s); norm(s); BIG_XXX_mod(s,Modulus_YYY);

//	BIG_XXX_output(r);
//	BIG_XXX_output(s);

	BIG_XXX_output(r);
	FP_YYY_nres(r);
	BIG_XXX_output(r);
	BIG_XXX_copy(a,r);
	FP_YYY_redc(r);
	BIG_XXX_output(r);
	BIG_XXX_dscopy(c,a);
	FP_YYY_mod(r,c);
	BIG_XXX_output(r);


//	exit(0);

//	copy(r,a);
	printf("r=   "); BIG_XXX_output(r);
	BIG_XXX_modsqr(r,r,Modulus_YYY);
	printf("r^2= "); BIG_XXX_output(r);

	FP_YYY_nres(r);
	FP_YYY_sqrt(r,r);
	FP_YYY_redc(r);
	printf("r=   "); BIG_XXX_output(r);
	BIG_XXX_modsqr(r,r,Modulus_YYY);
	printf("r^2= "); BIG_XXX_output(r);


//	for (i=0;i<100000;i++) FP_YYY_sqr(r,r);
//	for (i=0;i<100000;i++)
		FP_YYY_sqrt(r,r);

	BIG_XXX_output(r);
}
*/
