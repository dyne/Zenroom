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

/* AMCL Fp^8 functions */

/* FP8 elements are of the form a+ib, where i is sqrt(sqrt(-1+sqrt(-1))) */

#include "fp8_YYY.h"


/* test x==0 ? */
int FP8_YYY_iszilch(FP8_YYY *x)
{
    if (FP4_YYY_iszilch(&(x->a)) && FP4_YYY_iszilch(&(x->b))) return 1;
    return 0;
}

/* test x==1 ? */
int FP8_YYY_isunity(FP8_YYY *x)
{
    if (FP4_YYY_isunity(&(x->a)) && FP4_YYY_iszilch(&(x->b))) return 1;
    return 0;
}

/* test is w real? That is in a+ib test b is zero */
int FP8_YYY_isreal(FP8_YYY *w)
{
    return FP4_YYY_iszilch(&(w->b));
}

/* return 1 if x==y, else 0 */
int FP8_YYY_equals(FP8_YYY *x,FP8_YYY *y)
{
    if (FP4_YYY_equals(&(x->a),&(y->a)) && FP4_YYY_equals(&(x->b),&(y->b)))
        return 1;
    return 0;
}

/* set FP8 from two FP4s */
void FP8_YYY_from_FP4s(FP8_YYY *w,FP4_YYY * x,FP4_YYY* y)
{
    FP4_YYY_copy(&(w->a), x);
    FP4_YYY_copy(&(w->b), y);
}

/* set FP8 from FP4 */
void FP8_YYY_from_FP4(FP8_YYY *w,FP4_YYY *x)
{
    FP4_YYY_copy(&(w->a), x);
    FP4_YYY_zero(&(w->b));
}

/* set high part of FP8 from FP4 */
void FP8_YYY_from_FP4H(FP8_YYY *w,FP4_YYY *x)
{
    FP4_YYY_copy(&(w->b), x);
    FP4_YYY_zero(&(w->a));
}

/* FP8 copy w=x */
void FP8_YYY_copy(FP8_YYY *w,FP8_YYY *x)
{
    if (w==x) return;
    FP4_YYY_copy(&(w->a), &(x->a));
    FP4_YYY_copy(&(w->b), &(x->b));
}

/* FP8 w=0 */
void FP8_YYY_zero(FP8_YYY *w)
{
    FP4_YYY_zero(&(w->a));
    FP4_YYY_zero(&(w->b));
}

/* FP8 w=1 */
void FP8_YYY_one(FP8_YYY *w)
{
    FP4_YYY_one(&(w->a));
    FP4_YYY_zero(&(w->b));
}

/* Set w=-x */
void FP8_YYY_neg(FP8_YYY *w,FP8_YYY *x)
{
    /* Just one field neg */
    FP4_YYY m,t;
    FP8_YYY_norm(x);
    FP4_YYY_add(&m,&(x->a),&(x->b));
    FP4_YYY_norm(&m);
    FP4_YYY_neg(&m,&m);
    FP4_YYY_add(&t,&m,&(x->b));
    FP4_YYY_add(&(w->b),&m,&(x->a));
    FP4_YYY_copy(&(w->a),&t);
    FP8_YYY_norm(w);
}

/* Set w=conj(x) */
void FP8_YYY_conj(FP8_YYY *w,FP8_YYY *x)
{
    FP4_YYY_copy(&(w->a), &(x->a));
    FP4_YYY_neg(&(w->b), &(x->b));
    FP8_YYY_norm(w);
}

/* Set w=-conj(x) */
void FP8_YYY_nconj(FP8_YYY *w,FP8_YYY *x)
{
    FP4_YYY_copy(&(w->b),&(x->b));
    FP4_YYY_neg(&(w->a), &(x->a));
    FP8_YYY_norm(w);
}

/* Set w=x+y */
void FP8_YYY_add(FP8_YYY *w,FP8_YYY *x,FP8_YYY *y)
{
    FP4_YYY_add(&(w->a), &(x->a), &(y->a));
    FP4_YYY_add(&(w->b), &(x->b), &(y->b));
}

/* Set w=x-y */
/* Input y MUST be normed */
void FP8_YYY_sub(FP8_YYY *w,FP8_YYY *x,FP8_YYY *y)
{
    FP8_YYY my;

    FP8_YYY_neg(&my, y);
    FP8_YYY_add(w, x, &my);

}

/* reduce all components of w mod Modulus */
void FP8_YYY_reduce(FP8_YYY *w)
{
    FP4_YYY_reduce(&(w->a));
    FP4_YYY_reduce(&(w->b));
}

/* normalise all elements of w */
void FP8_YYY_norm(FP8_YYY *w)
{
    FP4_YYY_norm(&(w->a));
    FP4_YYY_norm(&(w->b));
}

/* Set w=s*x, where s is FP4 */
void FP8_YYY_pmul(FP8_YYY *w,FP8_YYY *x,FP4_YYY *s)
{
    FP4_YYY_mul(&(w->a),&(x->a),s);
    FP4_YYY_mul(&(w->b),&(x->b),s);
}

/* Set w=s*x, where s is FP2 */
void FP8_YYY_qmul(FP8_YYY *w,FP8_YYY *x,FP2_YYY *s)
{
    FP4_YYY_pmul(&(w->a),&(x->a),s);
    FP4_YYY_pmul(&(w->b),&(x->b),s);
}

/* Set w=s*x, where s is FP2 */
void FP8_YYY_tmul(FP8_YYY *w,FP8_YYY *x,FP_YYY *s)
{
    FP4_YYY_qmul(&(w->a),&(x->a),s);
    FP4_YYY_qmul(&(w->b),&(x->b),s);
}

/* Set w=s*x, where s is int */
void FP8_YYY_imul(FP8_YYY *w,FP8_YYY *x,int s)
{
    FP4_YYY_imul(&(w->a),&(x->a),s);
    FP4_YYY_imul(&(w->b),&(x->b),s);
}

/* Set w=x^2 */
/* Input MUST be normed  */
void FP8_YYY_sqr(FP8_YYY *w,FP8_YYY *x)
{
    FP4_YYY t1,t2,t3;

    FP4_YYY_mul(&t3,&(x->a),&(x->b)); /* norms x */
    FP4_YYY_copy(&t2,&(x->b));
    FP4_YYY_add(&t1,&(x->a),&(x->b));
    FP4_YYY_times_i(&t2);

    FP4_YYY_add(&t2,&(x->a),&t2);

    FP4_YYY_norm(&t1);  // 2
    FP4_YYY_norm(&t2);  // 2

    FP4_YYY_mul(&(w->a),&t1,&t2);

    FP4_YYY_copy(&t2,&t3);
    FP4_YYY_times_i(&t2);

    FP4_YYY_add(&t2,&t2,&t3);

    FP4_YYY_norm(&t2);  // 2
    FP4_YYY_neg(&t2,&t2);
    FP4_YYY_add(&(w->a),&(w->a),&t2);  /* a=(a+b)(a+i^2.b)-i^2.ab-ab = a*a+ib*ib */
    FP4_YYY_add(&(w->b),&t3,&t3);  /* b=2ab */

    FP8_YYY_norm(w);
}

/* Set w=x*y */
/* Inputs MUST be normed  */
void FP8_YYY_mul(FP8_YYY *w,FP8_YYY *x,FP8_YYY *y)
{

    FP4_YYY t1,t2,t3,t4;
    FP4_YYY_mul(&t1,&(x->a),&(y->a));
    FP4_YYY_mul(&t2,&(x->b),&(y->b));

    FP4_YYY_add(&t3,&(y->b),&(y->a));
    FP4_YYY_add(&t4,&(x->b),&(x->a));

    FP4_YYY_norm(&t4); // 2
    FP4_YYY_norm(&t3); // 2

    FP4_YYY_mul(&t4,&t4,&t3); /* (xa+xb)(ya+yb) */

    FP4_YYY_neg(&t3,&t1);  // 1
    FP4_YYY_add(&t4,&t4,&t3);  //t4E=3
    FP4_YYY_norm(&t4);

    FP4_YYY_neg(&t3,&t2);  // 1
    FP4_YYY_add(&(w->b),&t4,&t3); //wbE=3

    FP4_YYY_times_i(&t2);
    FP4_YYY_add(&(w->a),&t2,&t1);

    FP8_YYY_norm(w);
}

/* output FP8 in format [a,b] */
void FP8_YYY_output(FP8_YYY *w)
{
    printf("[");
    FP4_YYY_output(&(w->a));
    printf(",");
    FP4_YYY_output(&(w->b));
    printf("]");
}

void FP8_YYY_rawoutput(FP8_YYY *w)
{
    printf("[");
    FP4_YYY_rawoutput(&(w->a));
    printf(",");
    FP4_YYY_rawoutput(&(w->b));
    printf("]");
}

/* Set w=1/x */
void FP8_YYY_inv(FP8_YYY *w,FP8_YYY *x)
{
    FP4_YYY t1,t2;
    FP4_YYY_sqr(&t1,&(x->a));
    FP4_YYY_sqr(&t2,&(x->b));
    FP4_YYY_times_i(&t2);
    FP4_YYY_norm(&t2);

    FP4_YYY_sub(&t1,&t1,&t2);
    FP4_YYY_norm(&t1);
    FP4_YYY_inv(&t1,&t1);

    FP4_YYY_mul(&(w->a),&t1,&(x->a));
    FP4_YYY_neg(&t1,&t1);
    FP4_YYY_norm(&t1);
    FP4_YYY_mul(&(w->b),&t1,&(x->b));
}

/* w*=i where i = sqrt(sqrt(-1+sqrt(-1))) */
void FP8_YYY_times_i(FP8_YYY *w)
{
    FP4_YYY s,t;
    FP4_YYY_copy(&s,&(w->b));
    FP4_YYY_copy(&t,&(w->a));
    FP4_YYY_times_i(&s);
    FP4_YYY_copy(&(w->a),&s);
    FP4_YYY_copy(&(w->b),&t);
    FP8_YYY_norm(w);
}

void FP8_YYY_times_i2(FP8_YYY *w)
{
    FP4_YYY_times_i(&(w->a));
    FP4_YYY_times_i(&(w->b));
}

/* Set w=w^p using Frobenius */
void FP8_YYY_frob(FP8_YYY *w,FP2_YYY *f)
{
    // f=(i+1)^(p-3)/4
    FP2_YYY ff;
    FP2_YYY_sqr(&ff,f);  // (i+1)^(p-3)/2
    FP2_YYY_mul_ip(&ff); // (i+1)^(p-1)/2
    FP2_YYY_norm(&ff);
    FP4_YYY_frob(&(w->a),&ff);
    FP4_YYY_frob(&(w->b),&ff);
    FP4_YYY_pmul(&(w->b),&(w->b),f);  // times (1+i)^(p-3)/4
    FP4_YYY_times_i(&(w->b));		// (i+1)^(p-1)/4
}

/* Set r=a^b mod m */
void FP8_YYY_pow(FP8_YYY *r,FP8_YYY* a,BIG_XXX b)
{
    FP8_YYY w;
    BIG_XXX z,zilch;
    int bt;

    BIG_XXX_zero(zilch);

    BIG_XXX_copy(z,b);
    FP8_YYY_copy(&w,a);
    FP8_YYY_norm(&w);
    FP8_YYY_one(r);
    BIG_XXX_norm(z);
    while(1)
    {
        bt=BIG_XXX_parity(z);
        BIG_XXX_shr(z,1);
        if (bt) FP8_YYY_mul(r,r,&w);
        if (BIG_XXX_comp(z,zilch)==0) break;
        FP8_YYY_sqr(&w,&w);
    }
    FP8_YYY_reduce(r);
}

#if CURVE_SECURITY_ZZZ == 192

/* XTR xtr_a function */
void FP8_YYY_xtr_A(FP8_YYY *r,FP8_YYY *w,FP8_YYY *x,FP8_YYY *y,FP8_YYY *z)
{
    FP8_YYY t1,t2;

    FP8_YYY_copy(r,x);
    FP8_YYY_sub(&t1,w,y);
    FP8_YYY_norm(&t1);
    FP8_YYY_pmul(&t1,&t1,&(r->a));
    FP8_YYY_add(&t2,w,y);
    FP8_YYY_norm(&t2);
    FP8_YYY_pmul(&t2,&t2,&(r->b));
    FP8_YYY_times_i(&t2);

    FP8_YYY_add(r,&t1,&t2);
    FP8_YYY_add(r,r,z);

    FP8_YYY_reduce(r);
}

/* XTR xtr_d function */
void FP8_YYY_xtr_D(FP8_YYY *r,FP8_YYY *x)
{
    FP8_YYY w;
    FP8_YYY_copy(r,x);
    FP8_YYY_conj(&w,r);
    FP8_YYY_add(&w,&w,&w);
    FP8_YYY_sqr(r,r);
    FP8_YYY_norm(&w);
    FP8_YYY_sub(r,r,&w);
    FP8_YYY_reduce(r);    /* reduce here as multiple calls trigger automatic reductions */
}

/* r=x^n using XTR method on traces of FP12s */
void FP8_YYY_xtr_pow(FP8_YYY *r,FP8_YYY *x,BIG_XXX n)
{
    int i,par,nb;
    BIG_XXX v;
    FP2_YYY w2;
    FP4_YYY w4;
    FP8_YYY t,a,b,c,sf;

    BIG_XXX_zero(v);
    BIG_XXX_inc(v,3);
    BIG_XXX_norm(v);
    FP2_YYY_from_BIG(&w2,v);
    FP4_YYY_from_FP2(&w4,&w2);
    FP8_YYY_from_FP4(&a,&w4);
    FP8_YYY_copy(&sf,x);
    FP8_YYY_norm(&sf);
    FP8_YYY_copy(&b,&sf);
    FP8_YYY_xtr_D(&c,&sf);

    par=BIG_XXX_parity(n);
    BIG_XXX_copy(v,n);
    BIG_XXX_norm(v);
    BIG_XXX_shr(v,1);
    if (par==0)
    {
        BIG_XXX_dec(v,1);
        BIG_XXX_norm(v);
    }

    nb=BIG_XXX_nbits(v);
    for (i=nb-1; i>=0; i--)
    {
        if (!BIG_XXX_bit(v,i))
        {
            FP8_YYY_copy(&t,&b);
            FP8_YYY_conj(&sf,&sf);
            FP8_YYY_conj(&c,&c);
            FP8_YYY_xtr_A(&b,&a,&b,&sf,&c);
            FP8_YYY_conj(&sf,&sf);
            FP8_YYY_xtr_D(&c,&t);
            FP8_YYY_xtr_D(&a,&a);
        }
        else
        {
            FP8_YYY_conj(&t,&a);
            FP8_YYY_xtr_D(&a,&b);
            FP8_YYY_xtr_A(&b,&c,&b,&sf,&t);
            FP8_YYY_xtr_D(&c,&c);
        }
    }

    if (par==0) FP8_YYY_copy(r,&c);
    else FP8_YYY_copy(r,&b);
    FP8_YYY_reduce(r);
}

/* r=ck^a.cl^n using XTR double exponentiation method on traces of FP12s. See Stam thesis. */
void FP8_YYY_xtr_pow2(FP8_YYY *r,FP8_YYY *ck,FP8_YYY *cl,FP8_YYY *ckml,FP8_YYY *ckm2l,BIG_XXX a,BIG_XXX b)
{
    int i,f2;
    BIG_XXX d,e,w;
    FP8_YYY t,cu,cv,cumv,cum2v;


    BIG_XXX_copy(e,a);
    BIG_XXX_copy(d,b);
    BIG_XXX_norm(e);
    BIG_XXX_norm(d);
    FP8_YYY_copy(&cu,ck);
    FP8_YYY_copy(&cv,cl);
    FP8_YYY_copy(&cumv,ckml);
    FP8_YYY_copy(&cum2v,ckm2l);

    f2=0;
    while (BIG_XXX_parity(d)==0 && BIG_XXX_parity(e)==0)
    {
        BIG_XXX_shr(d,1);
        BIG_XXX_shr(e,1);
        f2++;
    }
    while (BIG_XXX_comp(d,e)!=0)
    {
        if (BIG_XXX_comp(d,e)>0)
        {
            BIG_XXX_imul(w,e,4);
            BIG_XXX_norm(w);
            if (BIG_XXX_comp(d,w)<=0)
            {
                BIG_XXX_copy(w,d);
                BIG_XXX_copy(d,e);
                BIG_XXX_sub(e,w,e);
                BIG_XXX_norm(e);
                FP8_YYY_xtr_A(&t,&cu,&cv,&cumv,&cum2v);
                FP8_YYY_conj(&cum2v,&cumv);
                FP8_YYY_copy(&cumv,&cv);
                FP8_YYY_copy(&cv,&cu);
                FP8_YYY_copy(&cu,&t);
            }
            else if (BIG_XXX_parity(d)==0)
            {
                BIG_XXX_shr(d,1);
                FP8_YYY_conj(r,&cum2v);
                FP8_YYY_xtr_A(&t,&cu,&cumv,&cv,r);
                FP8_YYY_xtr_D(&cum2v,&cumv);
                FP8_YYY_copy(&cumv,&t);
                FP8_YYY_xtr_D(&cu,&cu);
            }
            else if (BIG_XXX_parity(e)==1)
            {
                BIG_XXX_sub(d,d,e);
                BIG_XXX_norm(d);
                BIG_XXX_shr(d,1);
                FP8_YYY_xtr_A(&t,&cu,&cv,&cumv,&cum2v);
                FP8_YYY_xtr_D(&cu,&cu);
                FP8_YYY_xtr_D(&cum2v,&cv);
                FP8_YYY_conj(&cum2v,&cum2v);
                FP8_YYY_copy(&cv,&t);
            }
            else
            {
                BIG_XXX_copy(w,d);
                BIG_XXX_copy(d,e);
                BIG_XXX_shr(d,1);
                BIG_XXX_copy(e,w);
                FP8_YYY_xtr_D(&t,&cumv);
                FP8_YYY_conj(&cumv,&cum2v);
                FP8_YYY_conj(&cum2v,&t);
                FP8_YYY_xtr_D(&t,&cv);
                FP8_YYY_copy(&cv,&cu);
                FP8_YYY_copy(&cu,&t);
            }
        }
        if (BIG_XXX_comp(d,e)<0)
        {
            BIG_XXX_imul(w,d,4);
            BIG_XXX_norm(w);
            if (BIG_XXX_comp(e,w)<=0)
            {
                BIG_XXX_sub(e,e,d);
                BIG_XXX_norm(e);
                FP8_YYY_xtr_A(&t,&cu,&cv,&cumv,&cum2v);
                FP8_YYY_copy(&cum2v,&cumv);
                FP8_YYY_copy(&cumv,&cu);
                FP8_YYY_copy(&cu,&t);
            }
            else if (BIG_XXX_parity(e)==0)
            {
                BIG_XXX_copy(w,d);
                BIG_XXX_copy(d,e);
                BIG_XXX_shr(d,1);
                BIG_XXX_copy(e,w);
                FP8_YYY_xtr_D(&t,&cumv);
                FP8_YYY_conj(&cumv,&cum2v);
                FP8_YYY_conj(&cum2v,&t);
                FP8_YYY_xtr_D(&t,&cv);
                FP8_YYY_copy(&cv,&cu);
                FP8_YYY_copy(&cu,&t);
            }
            else if (BIG_XXX_parity(d)==1)
            {
                BIG_XXX_copy(w,e);
                BIG_XXX_copy(e,d);
                BIG_XXX_sub(w,w,d);
                BIG_XXX_norm(w);
                BIG_XXX_copy(d,w);
                BIG_XXX_shr(d,1);
                FP8_YYY_xtr_A(&t,&cu,&cv,&cumv,&cum2v);
                FP8_YYY_conj(&cumv,&cumv);
                FP8_YYY_xtr_D(&cum2v,&cu);
                FP8_YYY_conj(&cum2v,&cum2v);
                FP8_YYY_xtr_D(&cu,&cv);
                FP8_YYY_copy(&cv,&t);
            }
            else
            {
                BIG_XXX_shr(d,1);
                FP8_YYY_conj(r,&cum2v);
                FP8_YYY_xtr_A(&t,&cu,&cumv,&cv,r);
                FP8_YYY_xtr_D(&cum2v,&cumv);
                FP8_YYY_copy(&cumv,&t);
                FP8_YYY_xtr_D(&cu,&cu);
            }
        }
    }
    FP8_YYY_xtr_A(r,&cu,&cv,&cumv,&cum2v);
    for (i=0; i<f2; i++)	FP8_YYY_xtr_D(r,r);
    FP8_YYY_xtr_pow(r,r,d);
}

#endif


/* New stuff for ECp8 support */

/* Move b to a if d=1 */
void FP8_YYY_cmove(FP8_YYY *f,FP8_YYY *g,int d)
{
    FP4_YYY_cmove(&(f->a),&(g->a),d);
    FP4_YYY_cmove(&(f->b),&(g->b),d);
}

#if CURVE_SECURITY_ZZZ == 256

/* sqrt(a+xb) = sqrt((a+sqrt(a*a-n*b*b))/2)+x.b/(2*sqrt((a+sqrt(a*a-n*b*b))/2)) */
/* returns true if x is QR */
int FP8_YYY_sqrt(FP8_YYY *r,FP8_YYY* x)
{
    FP4_YYY a,s,t;

    FP8_YYY_copy(r,x);
    if (FP8_YYY_iszilch(x))
        return 1;

    FP4_YYY_copy(&a,&(x->a));
    FP4_YYY_copy(&s,&(x->b));

    if (FP4_YYY_iszilch(&s))
    {
        if (FP4_YYY_sqrt(&t,&a))
        {
            FP8_YYY_from_FP4(r,&t);
        }
        else
        {
            FP4_YYY_div_i(&a);
            FP4_YYY_sqrt(&t,&a);
            FP8_YYY_from_FP4H(r,&t);
        }
        return 1;
    }

    FP4_YYY_sqr(&s,&s);  // s*=s
    FP4_YYY_sqr(&a,&a);  // a*=a
    FP4_YYY_times_i(&s);
    FP4_YYY_norm(&s);
    FP4_YYY_sub(&a,&a,&s); // a-=txx(s)

    if (!FP4_YYY_sqrt(&s,&a)) return 0;

    FP4_YYY_sqr(&t,&s);


    FP4_YYY_copy(&t,&(x->a));
    FP4_YYY_add(&a,&t,&s);
    FP4_YYY_norm(&a);
    FP4_YYY_div2(&a,&a);

    if (!FP4_YYY_sqrt(&a,&a))
    {
        FP4_YYY_sub(&a,&t,&s);
        FP4_YYY_norm(&a);
        FP4_YYY_div2(&a,&a);
        if (!FP4_YYY_sqrt(&a,&a)) return 0;
    }

    FP4_YYY_copy(&t,&(x->b));
    FP4_YYY_add(&s,&a,&a);
    FP4_YYY_inv(&s,&s);

    FP4_YYY_mul(&t,&t,&s);
    FP8_YYY_from_FP4s(r,&a,&t);

    return 1;

}


void FP8_YYY_div_i(FP8_YYY *f)
{
    FP4_YYY u,v;
    FP4_YYY_copy(&u,&(f->a));
    FP4_YYY_copy(&v,&(f->b));
    FP4_YYY_div_i(&u);
    FP4_YYY_copy(&(f->a),&v);
    FP4_YYY_copy(&(f->b),&u);
}

void FP8_YYY_div_i2(FP8_YYY *f)
{
    FP4_YYY_div_i(&(f->a));
    FP4_YYY_div_i(&(f->b));
}


void FP8_YYY_div_2i(FP8_YYY *f)
{
    FP4_YYY u,v;
    FP4_YYY_copy(&u,&(f->a));
    FP4_YYY_copy(&v,&(f->b));
    FP4_YYY_div_2i(&u);
    FP4_YYY_add(&v,&v,&v);
    FP4_YYY_norm(&v);
    FP4_YYY_copy(&(f->a),&v);
    FP4_YYY_copy(&(f->b),&u);
}

#endif

