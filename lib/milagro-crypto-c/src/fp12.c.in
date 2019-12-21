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

/* AMCL Fp^12 functions */
/* SU=m, m is Stack Usage (no lazy )*/
/* FP12 elements are of the form a+i.b+i^2.c */

#include "fp12_YYY.h"
#include "config_curve_ZZZ.h"

/* return 1 if b==c, no branching */
static int teq(sign32 b,sign32 c)
{
    sign32 x=b^c;
    x-=1;  // if x=0, x now -1
    return (int)((x>>31)&1);
}


/* Constant time select from pre-computed table */
static void FP12_YYY_select(FP12_YYY *f,FP12_YYY g[],sign32 b)
{
    FP12_YYY invf;
    sign32 m=b>>31;
    sign32 babs=(b^m)-m;

    babs=(babs-1)/2;

    FP12_YYY_cmove(f,&g[0],teq(babs,0));  // conditional move
    FP12_YYY_cmove(f,&g[1],teq(babs,1));
    FP12_YYY_cmove(f,&g[2],teq(babs,2));
    FP12_YYY_cmove(f,&g[3],teq(babs,3));
    FP12_YYY_cmove(f,&g[4],teq(babs,4));
    FP12_YYY_cmove(f,&g[5],teq(babs,5));
    FP12_YYY_cmove(f,&g[6],teq(babs,6));
    FP12_YYY_cmove(f,&g[7],teq(babs,7));

    FP12_YYY_copy(&invf,f);
    FP12_YYY_conj(&invf,&invf);  // 1/f
    FP12_YYY_cmove(f,&invf,(int)(m&1));
}



/* test x==0 ? */
/* SU= 8 */
int FP12_YYY_iszilch(FP12_YYY *x)
{
    if (FP4_YYY_iszilch(&(x->a)) && FP4_YYY_iszilch(&(x->b)) && FP4_YYY_iszilch(&(x->c))) return 1;
    return 0;
}

/* test x==1 ? */
/* SU= 8 */
int FP12_YYY_isunity(FP12_YYY *x)
{
    if (FP4_YYY_isunity(&(x->a)) && FP4_YYY_iszilch(&(x->b)) && FP4_YYY_iszilch(&(x->c))) return 1;
    return 0;
}

/* FP12 copy w=x */
/* SU= 16 */
void FP12_YYY_copy(FP12_YYY *w,FP12_YYY *x)
{
    if (x==w) return;
    FP4_YYY_copy(&(w->a),&(x->a));
    FP4_YYY_copy(&(w->b),&(x->b));
    FP4_YYY_copy(&(w->c),&(x->c));
    w->type=x->type;
}

/* FP12 w=1 */
/* SU= 8 */
void FP12_YYY_one(FP12_YYY *w)
{
    FP4_YYY_one(&(w->a));
    FP4_YYY_zero(&(w->b));
    FP4_YYY_zero(&(w->c));
    w->type=AMCL_FP_UNITY;
}

void FP12_YYY_zero(FP12_YYY *w)
{
    FP4_YYY_zero(&(w->a));
    FP4_YYY_zero(&(w->b));
    FP4_YYY_zero(&(w->c));
    w->type=AMCL_FP_ZERO;
}

/* return 1 if x==y, else 0 */
/* SU= 16 */
int FP12_YYY_equals(FP12_YYY *x,FP12_YYY *y)
{
    if (FP4_YYY_equals(&(x->a),&(y->a)) && FP4_YYY_equals(&(x->b),&(y->b)) && FP4_YYY_equals(&(x->c),&(y->c)))
        return 1;
    return 0;
}

/* Set w=conj(x) */
/* SU= 8 */
void FP12_YYY_conj(FP12_YYY *w,FP12_YYY *x)
{
    FP12_YYY_copy(w,x);
    FP4_YYY_conj(&(w->a),&(w->a));
    FP4_YYY_nconj(&(w->b),&(w->b));
    FP4_YYY_conj(&(w->c),&(w->c));
}

/* Create FP12 from FP4 */
/* SU= 8 */
void FP12_YYY_from_FP4(FP12_YYY *w,FP4_YYY *a)
{
    FP4_YYY_copy(&(w->a),a);
    FP4_YYY_zero(&(w->b));
    FP4_YYY_zero(&(w->c));
    w->type=AMCL_FP_SPARSER;
}

/* Create FP12 from 3 FP4's */
/* SU= 16 */
void FP12_YYY_from_FP4s(FP12_YYY *w,FP4_YYY *a,FP4_YYY *b,FP4_YYY *c)
{
    FP4_YYY_copy(&(w->a),a);
    FP4_YYY_copy(&(w->b),b);
    FP4_YYY_copy(&(w->c),c);
    w->type=AMCL_FP_DENSE;
}

/* Granger-Scott Unitary Squaring. This does not benefit from lazy reduction */
/* SU= 600 */
void FP12_YYY_usqr(FP12_YYY *w,FP12_YYY *x)
{
    FP4_YYY A,B,C,D;

    FP4_YYY_copy(&A,&(x->a));

    FP4_YYY_sqr(&(w->a),&(x->a));
    FP4_YYY_add(&D,&(w->a),&(w->a));
    FP4_YYY_add(&(w->a),&D,&(w->a));

    FP4_YYY_norm(&(w->a));
    FP4_YYY_nconj(&A,&A);

    FP4_YYY_add(&A,&A,&A);
    FP4_YYY_add(&(w->a),&(w->a),&A);
    FP4_YYY_sqr(&B,&(x->c));
    FP4_YYY_times_i(&B);

    FP4_YYY_add(&D,&B,&B);
    FP4_YYY_add(&B,&B,&D);
    FP4_YYY_norm(&B);

    FP4_YYY_sqr(&C,&(x->b));

    FP4_YYY_add(&D,&C,&C);
    FP4_YYY_add(&C,&C,&D);

    FP4_YYY_norm(&C);
    FP4_YYY_conj(&(w->b),&(x->b));
    FP4_YYY_add(&(w->b),&(w->b),&(w->b));
    FP4_YYY_nconj(&(w->c),&(x->c));

    FP4_YYY_add(&(w->c),&(w->c),&(w->c));
    FP4_YYY_add(&(w->b),&B,&(w->b));
    FP4_YYY_add(&(w->c),&C,&(w->c));

    w->type=AMCL_FP_DENSE;
    FP12_YYY_reduce(w);	    /* reduce here as in pow function repeated squarings would trigger multiple reductions */
}

/* FP12 squaring w=x^2 */
/* SU= 600 */
void FP12_YYY_sqr(FP12_YYY *w,FP12_YYY *x)
{
    /* Use Chung-Hasan SQR2 method from http://cacr.uwaterloo.ca/techreports/2006/cacr2006-24.pdf */

    FP4_YYY A,B,C,D;

    if (x->type<=AMCL_FP_UNITY)
    {
        FP12_YYY_copy(w,x);
        return;
    }

    FP4_YYY_sqr(&A,&(x->a));
    FP4_YYY_mul(&B,&(x->b),&(x->c));
    FP4_YYY_add(&B,&B,&B);
    FP4_YYY_norm(&B);
    FP4_YYY_sqr(&C,&(x->c));

    FP4_YYY_mul(&D,&(x->a),&(x->b));
    FP4_YYY_add(&D,&D,&D);
    FP4_YYY_add(&(w->c),&(x->a),&(x->c));
    FP4_YYY_add(&(w->c),&(x->b),&(w->c));
    FP4_YYY_norm(&(w->c));

    FP4_YYY_sqr(&(w->c),&(w->c));

    FP4_YYY_copy(&(w->a),&A);
    FP4_YYY_add(&A,&A,&B);

    FP4_YYY_norm(&A);

    FP4_YYY_add(&A,&A,&C);
    FP4_YYY_add(&A,&A,&D);

    FP4_YYY_norm(&A);
    FP4_YYY_neg(&A,&A);
    FP4_YYY_times_i(&B);
    FP4_YYY_times_i(&C);

    FP4_YYY_add(&(w->a),&(w->a),&B);
    FP4_YYY_add(&(w->b),&C,&D);
    FP4_YYY_add(&(w->c),&(w->c),&A);

    if (x->type==AMCL_FP_SPARSER)
        w->type=AMCL_FP_SPARSE;
    else
        w->type=AMCL_FP_DENSE;

    FP12_YYY_norm(w);
}

/* FP12 full multiplication w=w*y */


/* SU= 896 */
/* FP12 full multiplication w=w*y */
void FP12_YYY_mul(FP12_YYY *w,FP12_YYY *y)
{
    FP4_YYY z0,z1,z2,z3,t0,t1;

    FP4_YYY_mul(&z0,&(w->a),&(y->a));
    FP4_YYY_mul(&z2,&(w->b),&(y->b));  //

    FP4_YYY_add(&t0,&(w->a),&(w->b));
    FP4_YYY_add(&t1,&(y->a),&(y->b));  //

    FP4_YYY_norm(&t0);
    FP4_YYY_norm(&t1);

    FP4_YYY_mul(&z1,&t0,&t1);
    FP4_YYY_add(&t0,&(w->b),&(w->c));
    FP4_YYY_add(&t1,&(y->b),&(y->c));  //

    FP4_YYY_norm(&t0);
    FP4_YYY_norm(&t1);

    FP4_YYY_mul(&z3,&t0,&t1);

    FP4_YYY_neg(&t0,&z0);
    FP4_YYY_neg(&t1,&z2);

    FP4_YYY_add(&z1,&z1,&t0);   // z1=z1-z0
    FP4_YYY_add(&(w->b),&z1,&t1); // z1=z1-z2
    FP4_YYY_add(&z3,&z3,&t1);        // z3=z3-z2
    FP4_YYY_add(&z2,&z2,&t0);        // z2=z2-z0

    FP4_YYY_add(&t0,&(w->a),&(w->c));
    FP4_YYY_add(&t1,&(y->a),&(y->c));

    FP4_YYY_norm(&t0);
    FP4_YYY_norm(&t1);

    FP4_YYY_mul(&t0,&t1,&t0);
    FP4_YYY_add(&z2,&z2,&t0);

    FP4_YYY_mul(&t0,&(w->c),&(y->c));
    FP4_YYY_neg(&t1,&t0);

    FP4_YYY_add(&(w->c),&z2,&t1);
    FP4_YYY_add(&z3,&z3,&t1);
    FP4_YYY_times_i(&t0);
    FP4_YYY_add(&(w->b),&(w->b),&t0);
    FP4_YYY_norm(&z3);
    FP4_YYY_times_i(&z3);
    FP4_YYY_add(&(w->a),&z0,&z3);

    w->type=AMCL_FP_DENSE;
    FP12_YYY_norm(w);
}

/* FP12 full multiplication w=w*y */
/* Supports sparse multiplicands */
/* Usually w is denser than y */
void FP12_YYY_ssmul(FP12_YYY *w,FP12_YYY *y)
{
    FP4_YYY z0,z1,z2,z3,t0,t1;
    if (w->type==AMCL_FP_UNITY)
    {
        FP12_YYY_copy(w,y);
        return;
    }
    if (y->type==AMCL_FP_UNITY)
        return;

    if (y->type >= AMCL_FP_SPARSE)
    {
        FP4_YYY_mul(&z0,&(w->a),&(y->a));  // xa.ya   always 11x11

#if SEXTIC_TWIST_ZZZ == M_TYPE
        if (y->type==AMCL_FP_SPARSE || w->type==AMCL_FP_SPARSE)
        {
            FP2_YYY_mul(&z2.b,&(w->b).b,&(y->b).b);
            FP2_YYY_zero(&z2.a);
            if (y->type!=AMCL_FP_SPARSE)
                FP2_YYY_mul(&z2.a,&(w->b).b,&(y->b).a);
            if (w->type!=AMCL_FP_SPARSE)
                FP2_YYY_mul(&z2.a,&(w->b).a,&(y->b).b);
            FP4_YYY_times_i(&z2);
        }
        else
#endif
            FP4_YYY_mul(&z2,&(w->b),&(y->b));  // xb.yb  could be 00x00 or 01x01 or or 10x10 or 11x00 or 11x10 or 11x01 or 11x11

        FP4_YYY_add(&t0,&(w->a),&(w->b));  // (xa+xb)
        FP4_YYY_add(&t1,&(y->a),&(y->b));  // (ya+yb)

        FP4_YYY_norm(&t0);
        FP4_YYY_norm(&t1);

        FP4_YYY_mul(&z1,&t0,&t1); // (xa+xb)(ya+yb)  always 11x11
        FP4_YYY_add(&t0,&(w->b),&(w->c));  // (xb+xc)
        FP4_YYY_add(&t1,&(y->b),&(y->c));  // (yb+yc)

        FP4_YYY_norm(&t0);
        FP4_YYY_norm(&t1);

        FP4_YYY_mul(&z3,&t0,&t1);	// (xb+xc)(yb+yc)   could be anything...
        FP4_YYY_neg(&t0,&z0);		// -(xa.ya)
        FP4_YYY_neg(&t1,&z2);		// -(xb.yb)

        FP4_YYY_add(&z1,&z1,&t0);
        FP4_YYY_add(&(w->b),&z1,&t1); // /wb = (xa+xb)(ya+yb) -(xa.ya) -(xb.yb)						= xa.yb + xb.ya

        FP4_YYY_add(&z3,&z3,&t1);        // (xb+xc)(yb+yc) -(xb.yb)
        FP4_YYY_add(&z2,&z2,&t0);        // (xb.yb) - (xa.ya)

        FP4_YYY_add(&t0,&(w->a),&(w->c));  // (xa+xc)
        FP4_YYY_add(&t1,&(y->a),&(y->c));  // (ya+yc)

        FP4_YYY_norm(&t0);
        FP4_YYY_norm(&t1);

        FP4_YYY_mul(&t0,&t1,&t0);	// (xa+xc)(ya+yc)    always 11x11
        FP4_YYY_add(&z2,&z2,&t0);	// (xb.yb) - (xa.ya) + (xa+xc)(ya+yc)

#if SEXTIC_TWIST_ZZZ == D_TYPE
        if (y->type==AMCL_FP_SPARSE || w->type==AMCL_FP_SPARSE)
        {
            FP2_YYY_mul(&t0.a,&(w->c).a,&(y->c).a);
            FP2_YYY_zero(&t0.b);
            if (y->type!=AMCL_FP_SPARSE)
                FP2_YYY_mul(&t0.b,&(w->c).a,&(y->c).b);
            if (w->type!=AMCL_FP_SPARSE)
                FP2_YYY_mul(&t0.b,&(w->c).b,&(y->c).a);
        }
        else
#endif
            FP4_YYY_mul(&t0,&(w->c),&(y->c)); // (xc.yc)  could be anything

        FP4_YYY_neg(&t1,&t0);			  // -(xc.yc)

        FP4_YYY_add(&(w->c),&z2,&t1);		// wc = (xb.yb) - (xa.ya) + (xa+xc)(ya+yc) - (xc.yc)	=  xb.yb + xc.ya + xa.yc
        FP4_YYY_add(&z3,&z3,&t1);			// (xb+xc)(yb+yc) -(xb.yb) - (xc.yc)					=  xb.yc + xc.yb
        FP4_YYY_times_i(&t0);				// i.(xc.yc)
        FP4_YYY_add(&(w->b),&(w->b),&t0);   // wb = (xa+xb)(ya+yb) -(xa.ya) -(xb.yb) +i(xc.yc)
        FP4_YYY_norm(&z3);
        FP4_YYY_times_i(&z3);				// i[(xb+xc)(yb+yc) -(xb.yb) - (xc.yc)]					= i(xb.yc + xc.yb)
        FP4_YYY_add(&(w->a),&z0,&z3);		// wa = xa.ya + i(xb.yc + xc.yb)
    }
    else
    {
        if (w->type==AMCL_FP_SPARSER)
        {
            FP12_YYY_smul(w,y);
            return;
        }
// dense by sparser - 13m
#if SEXTIC_TWIST_ZZZ == D_TYPE
        FP4_YYY_copy(&z3,&(w->b));
        FP4_YYY_mul(&z0,&(w->a),&(y->a));

        FP4_YYY_pmul(&z2,&(w->b),&(y->b).a);
        FP4_YYY_add(&(w->b),&(w->a),&(w->b));
        FP4_YYY_copy(&t1,&(y->a));
        FP2_YYY_add(&t1.a,&t1.a,&(y->b).a);

        FP4_YYY_norm(&t1);
        FP4_YYY_norm(&(w->b));

        FP4_YYY_mul(&(w->b),&(w->b),&t1);
        FP4_YYY_add(&z3,&z3,&(w->c));
        FP4_YYY_norm(&z3);
        FP4_YYY_pmul(&z3,&z3,&(y->b).a);
        FP4_YYY_neg(&t0,&z0);
        FP4_YYY_neg(&t1,&z2);

        FP4_YYY_add(&(w->b),&(w->b),&t0);   // z1=z1-z0
        FP4_YYY_add(&(w->b),&(w->b),&t1);   // z1=z1-z2

        FP4_YYY_add(&z3,&z3,&t1);        // z3=z3-z2
        FP4_YYY_add(&z2,&z2,&t0);        // z2=z2-z0

        FP4_YYY_add(&t0,&(w->a),&(w->c));
        FP4_YYY_norm(&t0);
        FP4_YYY_norm(&z3);

        FP4_YYY_mul(&t0,&(y->a),&t0);
        FP4_YYY_add(&(w->c),&z2,&t0);

        FP4_YYY_times_i(&z3);
        FP4_YYY_add(&(w->a),&z0,&z3);
#endif
#if SEXTIC_TWIST_ZZZ == M_TYPE
        FP4_YYY_mul(&z0,&(w->a),&(y->a));
        FP4_YYY_add(&t0,&(w->a),&(w->b));
        FP4_YYY_norm(&t0);

        FP4_YYY_mul(&z1,&t0,&(y->a));
        FP4_YYY_add(&t0,&(w->b),&(w->c));
        FP4_YYY_norm(&t0);

        FP4_YYY_pmul(&z3,&t0,&(y->c).b);
        FP4_YYY_times_i(&z3);

        FP4_YYY_neg(&t0,&z0);
        FP4_YYY_add(&z1,&z1,&t0);   // z1=z1-z0

        FP4_YYY_copy(&(w->b),&z1);
        FP4_YYY_copy(&z2,&t0);

        FP4_YYY_add(&t0,&(w->a),&(w->c));
        FP4_YYY_add(&t1,&(y->a),&(y->c));

        FP4_YYY_norm(&t0);
        FP4_YYY_norm(&t1);

        FP4_YYY_mul(&t0,&t1,&t0);
        FP4_YYY_add(&z2,&z2,&t0);

        FP4_YYY_pmul(&t0,&(w->c),&(y->c).b);
        FP4_YYY_times_i(&t0);
        FP4_YYY_neg(&t1,&t0);
        FP4_YYY_times_i(&t0);

        FP4_YYY_add(&(w->c),&z2,&t1);
        FP4_YYY_add(&z3,&z3,&t1);

        FP4_YYY_add(&(w->b),&(w->b),&t0);
        FP4_YYY_norm(&z3);
        FP4_YYY_times_i(&z3);
        FP4_YYY_add(&(w->a),&z0,&z3);

#endif
    }
    w->type=AMCL_FP_DENSE;
    FP12_YYY_norm(w);
}

/* FP12 multiplication w=w*y */
/* catering for special case that arises from special form of ATE pairing line function */
/* w and y are both sparser line functions - cost = 6m */
void FP12_YYY_smul(FP12_YYY *w,FP12_YYY *y)
{
    FP2_YYY w1,w2,w3,ta,tb,tc,td,te,t;

//	if (type==D_TYPE)
//	{
#if SEXTIC_TWIST_ZZZ == D_TYPE
    FP2_YYY_mul(&w1,&(w->a).a,&(y->a).a); // A1.A2
    FP2_YYY_mul(&w2,&(w->a).b,&(y->a).b); // B1.B2
    FP2_YYY_mul(&w3,&(w->b).a,&(y->b).a); // C1.C2

    FP2_YYY_add(&ta,&(w->a).a,&(w->a).b); // A1+B1
    FP2_YYY_add(&tb,&(y->a).a,&(y->a).b); // A2+B2
    FP2_YYY_norm(&ta);
    FP2_YYY_norm(&tb);
    FP2_YYY_mul(&tc,&ta,&tb);			// (A1+B1)(A2+B2)
    FP2_YYY_add(&t,&w1,&w2);
    FP2_YYY_neg(&t,&t);
    FP2_YYY_add(&tc,&tc,&t);			// (A1+B1)(A2+B2)-A1.A2-B1*B2 =  (A1.B2+A2.B1)

    FP2_YYY_add(&ta,&(w->a).a,&(w->b).a); // A1+C1
    FP2_YYY_add(&tb,&(y->a).a,&(y->b).a); // A2+C2
    FP2_YYY_norm(&ta);
    FP2_YYY_norm(&tb);
    FP2_YYY_mul(&td,&ta,&tb);			// (A1+C1)(A2+C2)
    FP2_YYY_add(&t,&w1,&w3);
    FP2_YYY_neg(&t,&t);
    FP2_YYY_add(&td,&td,&t);			// (A1+C1)(A2+C2)-A1.A2-C1*C2 =  (A1.C2+A2.C1)

    FP2_YYY_add(&ta,&(w->a).b,&(w->b).a); // B1+C1
    FP2_YYY_add(&tb,&(y->a).b,&(y->b).a); // B2+C2
    FP2_YYY_norm(&ta);
    FP2_YYY_norm(&tb);
    FP2_YYY_mul(&te,&ta,&tb);			// (B1+C1)(B2+C2)
    FP2_YYY_add(&t,&w2,&w3);
    FP2_YYY_neg(&t,&t);
    FP2_YYY_add(&te,&te,&t);			// (B1+C1)(B2+C2)-B1.B2-C1*C2 =  (B1.C2+B2.C1)

    FP2_YYY_mul_ip(&w2);
    FP2_YYY_add(&w1,&w1,&w2);
    FP4_YYY_from_FP2s(&(w->a),&w1,&tc);
    FP4_YYY_from_FP2s(&(w->b),&td,&te); // only norm these 2
    FP4_YYY_from_FP2(&(w->c),&w3);

    FP4_YYY_norm(&(w->a));
    FP4_YYY_norm(&(w->b));
#endif
//	} else {
#if SEXTIC_TWIST_ZZZ == M_TYPE
    FP2_YYY_mul(&w1,&(w->a).a,&(y->a).a); // A1.A2
    FP2_YYY_mul(&w2,&(w->a).b,&(y->a).b); // B1.B2
    FP2_YYY_mul(&w3,&(w->c).b,&(y->c).b); // F1.F2

    FP2_YYY_add(&ta,&(w->a).a,&(w->a).b); // A1+B1
    FP2_YYY_add(&tb,&(y->a).a,&(y->a).b); // A2+B2
    FP2_YYY_norm(&ta);
    FP2_YYY_norm(&tb);
    FP2_YYY_mul(&tc,&ta,&tb);			// (A1+B1)(A2+B2)
    FP2_YYY_add(&t,&w1,&w2);
    FP2_YYY_neg(&t,&t);
    FP2_YYY_add(&tc,&tc,&t);			// (A1+B1)(A2+B2)-A1.A2-B1*B2 =  (A1.B2+A2.B1)

    FP2_YYY_add(&ta,&(w->a).a,&(w->c).b); // A1+F1
    FP2_YYY_add(&tb,&(y->a).a,&(y->c).b); // A2+F2
    FP2_YYY_norm(&ta);
    FP2_YYY_norm(&tb);
    FP2_YYY_mul(&td,&ta,&tb);			// (A1+F1)(A2+F2)
    FP2_YYY_add(&t,&w1,&w3);
    FP2_YYY_neg(&t,&t);
    FP2_YYY_add(&td,&td,&t);			// (A1+F1)(A2+F2)-A1.A2-F1*F2 =  (A1.F2+A2.F1)

    FP2_YYY_add(&ta,&(w->a).b,&(w->c).b); // B1+F1
    FP2_YYY_add(&tb,&(y->a).b,&(y->c).b); // B2+F2
    FP2_YYY_norm(&ta);
    FP2_YYY_norm(&tb);
    FP2_YYY_mul(&te,&ta,&tb);			// (B1+F1)(B2+F2)
    FP2_YYY_add(&t,&w2,&w3);
    FP2_YYY_neg(&t,&t);
    FP2_YYY_add(&te,&te,&t);			// (B1+F1)(B2+F2)-B1.B2-F1*F2 =  (B1.F2+B2.F1)

    FP2_YYY_mul_ip(&w2);
    FP2_YYY_add(&w1,&w1,&w2);
    FP4_YYY_from_FP2s(&(w->a),&w1,&tc);

    FP2_YYY_mul_ip(&w3);
    FP2_YYY_norm(&w3);
    FP4_YYY_from_FP2H(&(w->b),&w3);

    FP2_YYY_norm(&te);
    FP2_YYY_mul_ip(&te);
    FP4_YYY_from_FP2s(&(w->c),&te,&td);

    FP4_YYY_norm(&(w->a));
    FP4_YYY_norm(&(w->c));
#endif

//	}
    w->type=AMCL_FP_SPARSE;
}

/* Set w=1/x */
/* SU= 600 */
void FP12_YYY_inv(FP12_YYY *w,FP12_YYY *x)
{
    FP4_YYY f0,f1,f2,f3;

    FP4_YYY_sqr(&f0,&(x->a));
    FP4_YYY_mul(&f1,&(x->b),&(x->c));
    FP4_YYY_times_i(&f1);
    FP4_YYY_sub(&f0,&f0,&f1);  /* y.a */
    FP4_YYY_norm(&f0);

    FP4_YYY_sqr(&f1,&(x->c));
    FP4_YYY_times_i(&f1);
    FP4_YYY_mul(&f2,&(x->a),&(x->b));
    FP4_YYY_sub(&f1,&f1,&f2);  /* y.b */
    FP4_YYY_norm(&f1);

    FP4_YYY_sqr(&f2,&(x->b));
    FP4_YYY_mul(&f3,&(x->a),&(x->c));
    FP4_YYY_sub(&f2,&f2,&f3);  /* y.c */
    FP4_YYY_norm(&f2);

    FP4_YYY_mul(&f3,&(x->b),&f2);
    FP4_YYY_times_i(&f3);
    FP4_YYY_mul(&(w->a),&f0,&(x->a));
    FP4_YYY_add(&f3,&(w->a),&f3);
    FP4_YYY_mul(&(w->c),&f1,&(x->c));
    FP4_YYY_times_i(&(w->c));

    FP4_YYY_add(&f3,&(w->c),&f3);
    FP4_YYY_norm(&f3);

    FP4_YYY_inv(&f3,&f3);

    FP4_YYY_mul(&(w->a),&f0,&f3);
    FP4_YYY_mul(&(w->b),&f1,&f3);
    FP4_YYY_mul(&(w->c),&f2,&f3);
    w->type=AMCL_FP_DENSE;
}

/* constant time powering by small integer of max length bts */

void FP12_YYY_pinpow(FP12_YYY *r,int e,int bts)
{
    int i,b;
    FP12_YYY R[2];

    FP12_YYY_one(&R[0]);
    FP12_YYY_copy(&R[1],r);

    for (i=bts-1; i>=0; i--)
    {
        b=(e>>i)&1;
        FP12_YYY_mul(&R[1-b],&R[b]);
        FP12_YYY_usqr(&R[b],&R[b]);
    }
    FP12_YYY_copy(r,&R[0]);
}

/* Compressed powering of unitary elements y=x^(e mod r) */

void FP12_YYY_compow(FP4_YYY *c,FP12_YYY *x,BIG_XXX e,BIG_XXX r)
{
    FP12_YYY g1,g2;
    FP4_YYY cp,cpm1,cpm2;
    FP2_YYY f;
    BIG_XXX q,a,b,m;

    BIG_XXX_rcopy(a,Fra_YYY);
    BIG_XXX_rcopy(b,Frb_YYY);
    FP2_YYY_from_BIGs(&f,a,b);

    BIG_XXX_rcopy(q,Modulus_YYY);

    FP12_YYY_copy(&g1,x);
    FP12_YYY_copy(&g2,x);

    BIG_XXX_copy(m,q);
    BIG_XXX_mod(m,r);

    BIG_XXX_copy(a,e);
    BIG_XXX_mod(a,m);

    BIG_XXX_copy(b,e);
    BIG_XXX_sdiv(b,m);

    FP12_YYY_trace(c,&g1);

    if (BIG_XXX_iszilch(b))
    {
        FP4_YYY_xtr_pow(c,c,e);
        return;
    }

    FP12_YYY_frob(&g2,&f);
    FP12_YYY_trace(&cp,&g2);

    FP12_YYY_conj(&g1,&g1);
    FP12_YYY_mul(&g2,&g1);
    FP12_YYY_trace(&cpm1,&g2);
    FP12_YYY_mul(&g2,&g1);
    FP12_YYY_trace(&cpm2,&g2);

    FP4_YYY_xtr_pow2(c,&cp,c,&cpm1,&cpm2,a,b);
}


/* SU= 528 */
/* set r=a^b */
/* Note this is simple square and multiply, so not side-channel safe */

void FP12_YYY_pow(FP12_YYY *r,FP12_YYY *a,BIG_XXX b)
{
    FP12_YYY w,sf;
    BIG_XXX b1,b3;
    int i,nb,bt;
    BIG_XXX_copy(b1,b);
    BIG_XXX_norm(b1);
    BIG_XXX_pmul(b3,b1,3);
    BIG_XXX_norm(b3);

    FP12_YYY_copy(&sf,a);
    FP12_YYY_norm(&sf);
    FP12_YYY_copy(&w,&sf);


    nb=BIG_XXX_nbits(b3);
    for (i=nb-2; i>=1; i--)
    {
        FP12_YYY_usqr(&w,&w);
        bt=BIG_XXX_bit(b3,i)-BIG_XXX_bit(b1,i);
        if (bt==1)
            FP12_YYY_mul(&w,&sf);
        if (bt==-1)
        {
            FP12_YYY_conj(&sf,&sf);
            FP12_YYY_mul(&w,&sf);
            FP12_YYY_conj(&sf,&sf);
        }
    }

    FP12_YYY_copy(r,&w);
    FP12_YYY_reduce(r);
}

/* p=q0^u0.q1^u1.q2^u2.q3^u3 */
/* Side channel attack secure */
// Bos & Costello https://eprint.iacr.org/2013/458.pdf
// Faz-Hernandez & Longa & Sanchez  https://eprint.iacr.org/2013/158.pdf

void FP12_YYY_pow4(FP12_YYY *p,FP12_YYY *q,BIG_XXX u[4])
{
    int i,j,k,nb,pb,bt;
    FP12_YYY g[8],r;
    BIG_XXX t[4],mt;
    sign8 w[NLEN_XXX*BASEBITS_XXX+1];
    sign8 s[NLEN_XXX*BASEBITS_XXX+1];

    for (i=0; i<4; i++)
        BIG_XXX_copy(t[i],u[i]);


// Precomputed table
    FP12_YYY_copy(&g[0],&q[0]); // q[0]
    FP12_YYY_copy(&g[1],&g[0]);
    FP12_YYY_mul(&g[1],&q[1]);	// q[0].q[1]
    FP12_YYY_copy(&g[2],&g[0]);
    FP12_YYY_mul(&g[2],&q[2]);	// q[0].q[2]
    FP12_YYY_copy(&g[3],&g[1]);
    FP12_YYY_mul(&g[3],&q[2]);	// q[0].q[1].q[2]
    FP12_YYY_copy(&g[4],&g[0]);
    FP12_YYY_mul(&g[4],&q[3]);  // q[0].q[3]
    FP12_YYY_copy(&g[5],&g[1]);
    FP12_YYY_mul(&g[5],&q[3]);	// q[0].q[1].q[3]
    FP12_YYY_copy(&g[6],&g[2]);
    FP12_YYY_mul(&g[6],&q[3]);	// q[0].q[2].q[3]
    FP12_YYY_copy(&g[7],&g[3]);
    FP12_YYY_mul(&g[7],&q[3]);	// q[0].q[1].q[2].q[3]

// Make it odd
    pb=1-BIG_XXX_parity(t[0]);
    BIG_XXX_inc(t[0],pb);
    BIG_XXX_norm(t[0]);

// Number of bits
    BIG_XXX_zero(mt);
    for (i=0; i<4; i++)
    {
        BIG_XXX_or(mt,mt,t[i]);
    }
    nb=1+BIG_XXX_nbits(mt);

// Sign pivot
    s[nb-1]=1;
    for (i=0; i<nb-1; i++)
    {
        BIG_XXX_fshr(t[0],1);
        s[i]=2*BIG_XXX_parity(t[0])-1;
    }

// Recoded exponent
    for (i=0; i<nb; i++)
    {
        w[i]=0;
        k=1;
        for (j=1; j<4; j++)
        {
            bt=s[i]*BIG_XXX_parity(t[j]);
            BIG_XXX_fshr(t[j],1);

            BIG_XXX_dec(t[j],(bt>>1));
            BIG_XXX_norm(t[j]);
            w[i]+=bt*k;
            k*=2;
        }
    }

// Main loop
    FP12_YYY_select(p,g,2*w[nb-1]+1);
    for (i=nb-2; i>=0; i--)
    {
        FP12_YYY_select(&r,g,2*w[i]+s[i]);
        FP12_YYY_usqr(p,p);
        FP12_YYY_mul(p,&r);
    }
// apply correction
    FP12_YYY_conj(&r,&q[0]);
    FP12_YYY_mul(&r,p);
    FP12_YYY_cmove(p,&r,pb);

    FP12_YYY_reduce(p);
}

/* Set w=w^p using Frobenius */
/* SU= 160 */
void FP12_YYY_frob(FP12_YYY *w,FP2_YYY *f)
{
    FP2_YYY f2,f3;
    FP2_YYY_sqr(&f2,f);     /* f2=f^2 */
    FP2_YYY_mul(&f3,&f2,f); /* f3=f^3 */

    FP4_YYY_frob(&(w->a),&f3);
    FP4_YYY_frob(&(w->b),&f3);
    FP4_YYY_frob(&(w->c),&f3);

    FP4_YYY_pmul(&(w->b),&(w->b),f);
    FP4_YYY_pmul(&(w->c),&(w->c),&f2);
    w->type=AMCL_FP_DENSE;
}

/* SU= 8 */
/* normalise all components of w */
void FP12_YYY_norm(FP12_YYY *w)
{
    FP4_YYY_norm(&(w->a));
    FP4_YYY_norm(&(w->b));
    FP4_YYY_norm(&(w->c));
}

/* SU= 8 */
/* reduce all components of w */
void FP12_YYY_reduce(FP12_YYY *w)
{
    FP4_YYY_reduce(&(w->a));
    FP4_YYY_reduce(&(w->b));
    FP4_YYY_reduce(&(w->c));
}

/* trace function w=trace(x) */
/* SU= 8 */
void FP12_YYY_trace(FP4_YYY *w,FP12_YYY *x)
{
    FP4_YYY_imul(w,&(x->a),3);
    FP4_YYY_reduce(w);
}

/* SU= 8 */
/* Output w in hex */
void FP12_YYY_output(FP12_YYY *w)
{
    printf("[");
    FP4_YYY_output(&(w->a));
    printf(",");
    FP4_YYY_output(&(w->b));
    printf(",");
    FP4_YYY_output(&(w->c));
    printf("]");
}

/* SU= 64 */
/* Convert g to octet string w */
void FP12_YYY_toOctet(octet *W,FP12_YYY *g)
{
    BIG_XXX a;
    W->len=12*MODBYTES_XXX;

    FP_YYY_redc(a,&(g->a.a.a));
    BIG_XXX_toBytes(&(W->val[0]),a);
    FP_YYY_redc(a,&(g->a.a.b));
    BIG_XXX_toBytes(&(W->val[MODBYTES_XXX]),a);
    FP_YYY_redc(a,&(g->a.b.a));
    BIG_XXX_toBytes(&(W->val[2*MODBYTES_XXX]),a);
    FP_YYY_redc(a,&(g->a.b.b));
    BIG_XXX_toBytes(&(W->val[3*MODBYTES_XXX]),a);
    FP_YYY_redc(a,&(g->b.a.a));
    BIG_XXX_toBytes(&(W->val[4*MODBYTES_XXX]),a);
    FP_YYY_redc(a,&(g->b.a.b));
    BIG_XXX_toBytes(&(W->val[5*MODBYTES_XXX]),a);
    FP_YYY_redc(a,&(g->b.b.a));
    BIG_XXX_toBytes(&(W->val[6*MODBYTES_XXX]),a);
    FP_YYY_redc(a,&(g->b.b.b));
    BIG_XXX_toBytes(&(W->val[7*MODBYTES_XXX]),a);
    FP_YYY_redc(a,&(g->c.a.a));
    BIG_XXX_toBytes(&(W->val[8*MODBYTES_XXX]),a);
    FP_YYY_redc(a,&(g->c.a.b));
    BIG_XXX_toBytes(&(W->val[9*MODBYTES_XXX]),a);
    FP_YYY_redc(a,&(g->c.b.a));
    BIG_XXX_toBytes(&(W->val[10*MODBYTES_XXX]),a);
    FP_YYY_redc(a,&(g->c.b.b));
    BIG_XXX_toBytes(&(W->val[11*MODBYTES_XXX]),a);
}

/* SU= 24 */
/* Restore g from octet string w */
void FP12_YYY_fromOctet(FP12_YYY *g,octet *W)
{
    BIG_XXX b;
    BIG_XXX_fromBytes(b,&W->val[0]);
    FP_YYY_nres(&(g->a.a.a),b);
    BIG_XXX_fromBytes(b,&W->val[MODBYTES_XXX]);
    FP_YYY_nres(&(g->a.a.b),b);
    BIG_XXX_fromBytes(b,&W->val[2*MODBYTES_XXX]);
    FP_YYY_nres(&(g->a.b.a),b);
    BIG_XXX_fromBytes(b,&W->val[3*MODBYTES_XXX]);
    FP_YYY_nres(&(g->a.b.b),b);
    BIG_XXX_fromBytes(b,&W->val[4*MODBYTES_XXX]);
    FP_YYY_nres(&(g->b.a.a),b);
    BIG_XXX_fromBytes(b,&W->val[5*MODBYTES_XXX]);
    FP_YYY_nres(&(g->b.a.b),b);
    BIG_XXX_fromBytes(b,&W->val[6*MODBYTES_XXX]);
    FP_YYY_nres(&(g->b.b.a),b);
    BIG_XXX_fromBytes(b,&W->val[7*MODBYTES_XXX]);
    FP_YYY_nres(&(g->b.b.b),b);
    BIG_XXX_fromBytes(b,&W->val[8*MODBYTES_XXX]);
    FP_YYY_nres(&(g->c.a.a),b);
    BIG_XXX_fromBytes(b,&W->val[9*MODBYTES_XXX]);
    FP_YYY_nres(&(g->c.a.b),b);
    BIG_XXX_fromBytes(b,&W->val[10*MODBYTES_XXX]);
    FP_YYY_nres(&(g->c.b.a),b);
    BIG_XXX_fromBytes(b,&W->val[11*MODBYTES_XXX]);
    FP_YYY_nres(&(g->c.b.b),b);
}

/* Move b to a if d=1 */
void FP12_YYY_cmove(FP12_YYY *f,FP12_YYY *g,int d)
{
    FP4_YYY_cmove(&(f->a),&(g->a),d);
    FP4_YYY_cmove(&(f->b),&(g->b),d);
    FP4_YYY_cmove(&(f->c),&(g->c),d);
    d=~(d-1);
    f->type^=(f->type^g->type)&d;
}

