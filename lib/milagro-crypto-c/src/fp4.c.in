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

/* AMCL Fp^4 functions */
/* SU=m, m is Stack Usage (no lazy )*/

/* FP4 elements are of the form a+ib, where i is sqrt(-1+sqrt(-1)) */

#include "fp4_YYY.h"

/* test x==0 ? */
/* SU= 8 */
int FP4_YYY_iszilch(FP4_YYY *x)
{
    if (FP2_YYY_iszilch(&(x->a)) && FP2_YYY_iszilch(&(x->b))) return 1;
    return 0;
}

/* test x==1 ? */
/* SU= 8 */
int FP4_YYY_isunity(FP4_YYY *x)
{
    if (FP2_YYY_isunity(&(x->a)) && FP2_YYY_iszilch(&(x->b))) return 1;
    return 0;
}

/* test is w real? That is in a+ib test b is zero */
int FP4_YYY_isreal(FP4_YYY *w)
{
    return FP2_YYY_iszilch(&(w->b));
}

/* return 1 if x==y, else 0 */
/* SU= 16 */
int FP4_YYY_equals(FP4_YYY *x,FP4_YYY *y)
{
    if (FP2_YYY_equals(&(x->a),&(y->a)) && FP2_YYY_equals(&(x->b),&(y->b)))
        return 1;
    return 0;
}

/* set FP4 from two FP2s */
/* SU= 16 */
void FP4_YYY_from_FP2s(FP4_YYY *w,FP2_YYY * x,FP2_YYY* y)
{
    FP2_YYY_copy(&(w->a), x);
    FP2_YYY_copy(&(w->b), y);
}

/* set FP4 from FP2 */
/* SU= 8 */
void FP4_YYY_from_FP2(FP4_YYY *w,FP2_YYY *x)
{
    FP2_YYY_copy(&(w->a), x);
    FP2_YYY_zero(&(w->b));
}

/* set high part of FP4 from FP2 */
/* SU= 8 */
void FP4_YYY_from_FP2H(FP4_YYY *w,FP2_YYY *x)
{
    FP2_YYY_copy(&(w->b), x);
    FP2_YYY_zero(&(w->a));
}

/* FP4 copy w=x */
/* SU= 16 */
void FP4_YYY_copy(FP4_YYY *w,FP4_YYY *x)
{
    if (w==x) return;
    FP2_YYY_copy(&(w->a), &(x->a));
    FP2_YYY_copy(&(w->b), &(x->b));
}

/* FP4 w=0 */
/* SU= 8 */
void FP4_YYY_zero(FP4_YYY *w)
{
    FP2_YYY_zero(&(w->a));
    FP2_YYY_zero(&(w->b));
}

/* FP4 w=1 */
/* SU= 8 */
void FP4_YYY_one(FP4_YYY *w)
{
    FP2_YYY_one(&(w->a));
    FP2_YYY_zero(&(w->b));
}

/* Set w=-x */
/* SU= 160 */
void FP4_YYY_neg(FP4_YYY *w,FP4_YYY *x)
{
    /* Just one field neg */
    FP2_YYY m,t;
    FP4_YYY_norm(x);
    FP2_YYY_add(&m,&(x->a),&(x->b));
    FP2_YYY_neg(&m,&m);
    FP2_YYY_add(&t,&m,&(x->b));
    FP2_YYY_add(&(w->b),&m,&(x->a));
    FP2_YYY_copy(&(w->a),&t);
    FP4_YYY_norm(w);
}

/* Set w=conj(x) */
/* SU= 16 */
void FP4_YYY_conj(FP4_YYY *w,FP4_YYY *x)
{
    FP2_YYY_copy(&(w->a), &(x->a));
    FP2_YYY_neg(&(w->b), &(x->b));
    FP4_YYY_norm(w);
}

/* Set w=-conj(x) */
/* SU= 16 */
void FP4_YYY_nconj(FP4_YYY *w,FP4_YYY *x)
{
    FP2_YYY_copy(&(w->b),&(x->b));
    FP2_YYY_neg(&(w->a), &(x->a));
    FP4_YYY_norm(w);
}

/* Set w=x+y */
/* SU= 16 */
void FP4_YYY_add(FP4_YYY *w,FP4_YYY *x,FP4_YYY *y)
{
    FP2_YYY_add(&(w->a), &(x->a), &(y->a));
    FP2_YYY_add(&(w->b), &(x->b), &(y->b));
}

/* Set w=x-y */
/* Input y MUST be normed */
void FP4_YYY_sub(FP4_YYY *w,FP4_YYY *x,FP4_YYY *y)
{
    FP4_YYY my;
    FP4_YYY_neg(&my, y);
    FP4_YYY_add(w, x, &my);
}
/* SU= 8 */
/* reduce all components of w mod Modulus */
void FP4_YYY_reduce(FP4_YYY *w)
{
    FP2_YYY_reduce(&(w->a));
    FP2_YYY_reduce(&(w->b));
}

/* SU= 8 */
/* normalise all elements of w */
void FP4_YYY_norm(FP4_YYY *w)
{
    FP2_YYY_norm(&(w->a));
    FP2_YYY_norm(&(w->b));
}

/* Set w=s*x, where s is FP2 */
/* SU= 16 */
void FP4_YYY_pmul(FP4_YYY *w,FP4_YYY *x,FP2_YYY *s)
{
    FP2_YYY_mul(&(w->a),&(x->a),s);
    FP2_YYY_mul(&(w->b),&(x->b),s);
}

/* Set w=s*x, where s is FP */
void FP4_YYY_qmul(FP4_YYY *w,FP4_YYY *x,FP_YYY *s)
{
    FP2_YYY_pmul(&(w->a),&(x->a),s);
    FP2_YYY_pmul(&(w->b),&(x->b),s);
}

/* SU= 16 */
/* Set w=s*x, where s is int */
void FP4_YYY_imul(FP4_YYY *w,FP4_YYY *x,int s)
{
    FP2_YYY_imul(&(w->a),&(x->a),s);
    FP2_YYY_imul(&(w->b),&(x->b),s);
}

/* Set w=x^2 */
/* Input MUST be normed  */
void FP4_YYY_sqr(FP4_YYY *w,FP4_YYY *x)
{
    FP2_YYY t1,t2,t3;

    FP2_YYY_mul(&t3,&(x->a),&(x->b)); /* norms x */
    FP2_YYY_copy(&t2,&(x->b));
    FP2_YYY_add(&t1,&(x->a),&(x->b));
    FP2_YYY_mul_ip(&t2);

    FP2_YYY_add(&t2,&(x->a),&t2);

    FP2_YYY_norm(&t1);  // 2
    FP2_YYY_norm(&t2);  // 2

    FP2_YYY_mul(&(w->a),&t1,&t2);

    FP2_YYY_copy(&t2,&t3);
    FP2_YYY_mul_ip(&t2);

    FP2_YYY_add(&t2,&t2,&t3);

    FP2_YYY_norm(&t2);  // 2
    FP2_YYY_neg(&t2,&t2);
    FP2_YYY_add(&(w->a),&(w->a),&t2);  /* a=(a+b)(a+i^2.b)-i^2.ab-ab = a*a+ib*ib */
    FP2_YYY_add(&(w->b),&t3,&t3);  /* b=2ab */

    FP4_YYY_norm(w);
}

/* Set w=x*y */
/* Inputs MUST be normed  */
void FP4_YYY_mul(FP4_YYY *w,FP4_YYY *x,FP4_YYY *y)
{

    FP2_YYY t1,t2,t3,t4;
    FP2_YYY_mul(&t1,&(x->a),&(y->a));
    FP2_YYY_mul(&t2,&(x->b),&(y->b));

    FP2_YYY_add(&t3,&(y->b),&(y->a));
    FP2_YYY_add(&t4,&(x->b),&(x->a));

    FP2_YYY_norm(&t4); // 2
    FP2_YYY_norm(&t3); // 2

    FP2_YYY_mul(&t4,&t4,&t3); /* (xa+xb)(ya+yb) */

    FP2_YYY_neg(&t3,&t1);  // 1
    FP2_YYY_add(&t4,&t4,&t3);  //t4E=3
    FP2_YYY_norm(&t4);

    FP2_YYY_neg(&t3,&t2);  // 1
    FP2_YYY_add(&(w->b),&t4,&t3); //wbE=3

    FP2_YYY_mul_ip(&t2);
    FP2_YYY_add(&(w->a),&t2,&t1);

    FP4_YYY_norm(w);
}

/* output FP4 in format [a,b] */
/* SU= 8 */
void FP4_YYY_output(FP4_YYY *w)
{
    printf("[");
    FP2_YYY_output(&(w->a));
    printf(",");
    FP2_YYY_output(&(w->b));
    printf("]");
}

/* SU= 8 */
void FP4_YYY_rawoutput(FP4_YYY *w)
{
    printf("[");
    FP2_YYY_rawoutput(&(w->a));
    printf(",");
    FP2_YYY_rawoutput(&(w->b));
    printf("]");
}

/* Set w=1/x */
/* SU= 160 */
void FP4_YYY_inv(FP4_YYY *w,FP4_YYY *x)
{
    FP2_YYY t1,t2;
    FP2_YYY_sqr(&t1,&(x->a));
    FP2_YYY_sqr(&t2,&(x->b));
    FP2_YYY_mul_ip(&t2);
    FP2_YYY_norm(&t2);
    FP2_YYY_sub(&t1,&t1,&t2);
    FP2_YYY_inv(&t1,&t1);
    FP2_YYY_mul(&(w->a),&t1,&(x->a));
    FP2_YYY_neg(&t1,&t1);
    FP2_YYY_norm(&t1);
    FP2_YYY_mul(&(w->b),&t1,&(x->b));
}

/* w*=i where i = sqrt(-1+sqrt(-1)) */
/* SU= 200 */
void FP4_YYY_times_i(FP4_YYY *w)
{
    FP_YYY z;
    FP2_YYY s,t;
    FP2_YYY_copy(&t,&(w->b));

    FP2_YYY_copy(&s,&t);

    FP_YYY_copy(&z,&(s.a));
    FP_YYY_neg(&(s.a),&(s.b));
    FP_YYY_copy(&(s.b),&z);

    FP2_YYY_add(&t,&t,&s);

    FP2_YYY_copy(&(w->b),&(w->a));
    FP2_YYY_copy(&(w->a),&t);
    FP4_YYY_norm(w);
}

/* Set w=w^p using Frobenius */
/* SU= 16 */
void FP4_YYY_frob(FP4_YYY *w,FP2_YYY *f)
{
    FP2_YYY_conj(&(w->a),&(w->a));
    FP2_YYY_conj(&(w->b),&(w->b));
    FP2_YYY_mul( &(w->b),f,&(w->b));
}

/* Set r=a^b mod m */
/* SU= 240 */
void FP4_YYY_pow(FP4_YYY *r,FP4_YYY* a,BIG_XXX b)
{
    FP4_YYY w;
    BIG_XXX z,zilch;
    int bt;

    BIG_XXX_zero(zilch);

    BIG_XXX_copy(z,b);
    BIG_XXX_norm(z);
    FP4_YYY_copy(&w,a);
    FP4_YYY_norm(&w);
    FP4_YYY_one(r);

    while(1)
    {
        bt=BIG_XXX_parity(z);
        BIG_XXX_shr(z,1);
        if (bt) FP4_YYY_mul(r,r,&w);
        if (BIG_XXX_comp(z,zilch)==0) break;
        FP4_YYY_sqr(&w,&w);
    }
    FP4_YYY_reduce(r);
}

/* SU= 304 */
/* XTR xtr_a function */
void FP4_YYY_xtr_A(FP4_YYY *r,FP4_YYY *w,FP4_YYY *x,FP4_YYY *y,FP4_YYY *z)
{
    FP4_YYY t1,t2;
    FP4_YYY_copy(r,x);
    FP4_YYY_sub(&t1,w,y);
    FP4_YYY_norm(&t1);
    FP4_YYY_pmul(&t1,&t1,&(r->a));
    FP4_YYY_add(&t2,w,y);
    FP4_YYY_norm(&t2);
    FP4_YYY_pmul(&t2,&t2,&(r->b));
    FP4_YYY_times_i(&t2);

    FP4_YYY_add(r,&t1,&t2);
    FP4_YYY_add(r,r,z);

    FP4_YYY_reduce(r);
}

/* SU= 152 */
/* XTR xtr_d function */
void FP4_YYY_xtr_D(FP4_YYY *r,FP4_YYY *x)
{
    FP4_YYY w;
    FP4_YYY_copy(r,x);
    FP4_YYY_conj(&w,r);
    FP4_YYY_add(&w,&w,&w);
    FP4_YYY_sqr(r,r);
    FP4_YYY_norm(&w);
    FP4_YYY_sub(r,r,&w);
    FP4_YYY_reduce(r);    /* reduce here as multiple calls trigger automatic reductions */
}

/* SU= 728 */
/* r=x^n using XTR method on traces of FP12s */
void FP4_YYY_xtr_pow(FP4_YYY *r,FP4_YYY *x,BIG_XXX n)
{
    int i,par,nb;
    BIG_XXX v;
    FP2_YYY w;
    FP4_YYY t,a,b,c,sf;

    BIG_XXX_zero(v);
    BIG_XXX_inc(v,3);
    BIG_XXX_norm(v);
    FP2_YYY_from_BIG(&w,v);
    FP4_YYY_from_FP2(&a,&w);

    FP4_YYY_copy(&sf,x);
    FP4_YYY_norm(&sf);
    FP4_YYY_copy(&b,&sf);
    FP4_YYY_xtr_D(&c,&sf);

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
            FP4_YYY_copy(&t,&b);
            FP4_YYY_conj(&sf,&sf);
            FP4_YYY_conj(&c,&c);
            FP4_YYY_xtr_A(&b,&a,&b,&sf,&c);
            FP4_YYY_conj(&sf,&sf);
            FP4_YYY_xtr_D(&c,&t);
            FP4_YYY_xtr_D(&a,&a);
        }
        else
        {
            FP4_YYY_conj(&t,&a);
            FP4_YYY_xtr_D(&a,&b);
            FP4_YYY_xtr_A(&b,&c,&b,&sf,&t);
            FP4_YYY_xtr_D(&c,&c);
        }
    }

    if (par==0) FP4_YYY_copy(r,&c);
    else FP4_YYY_copy(r,&b);
    FP4_YYY_reduce(r);
}

/* SU= 872 */
/* r=ck^a.cl^n using XTR double exponentiation method on traces of FP12s. See Stam thesis. */
void FP4_YYY_xtr_pow2(FP4_YYY *r,FP4_YYY *ck,FP4_YYY *cl,FP4_YYY *ckml,FP4_YYY *ckm2l,BIG_XXX a,BIG_XXX b)
{
    int i,f2;
    BIG_XXX d,e,w;
    FP4_YYY t,cu,cv,cumv,cum2v;


    BIG_XXX_copy(e,a);
    BIG_XXX_copy(d,b);
    BIG_XXX_norm(e);
    BIG_XXX_norm(d);
    FP4_YYY_copy(&cu,ck);
    FP4_YYY_copy(&cv,cl);
    FP4_YYY_copy(&cumv,ckml);
    FP4_YYY_copy(&cum2v,ckm2l);

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
                FP4_YYY_xtr_A(&t,&cu,&cv,&cumv,&cum2v);
                FP4_YYY_conj(&cum2v,&cumv);
                FP4_YYY_copy(&cumv,&cv);
                FP4_YYY_copy(&cv,&cu);
                FP4_YYY_copy(&cu,&t);
            }
            else if (BIG_XXX_parity(d)==0)
            {
                BIG_XXX_shr(d,1);
                FP4_YYY_conj(r,&cum2v);
                FP4_YYY_xtr_A(&t,&cu,&cumv,&cv,r);
                FP4_YYY_xtr_D(&cum2v,&cumv);
                FP4_YYY_copy(&cumv,&t);
                FP4_YYY_xtr_D(&cu,&cu);
            }
            else if (BIG_XXX_parity(e)==1)
            {
                BIG_XXX_sub(d,d,e);
                BIG_XXX_norm(d);
                BIG_XXX_shr(d,1);
                FP4_YYY_xtr_A(&t,&cu,&cv,&cumv,&cum2v);
                FP4_YYY_xtr_D(&cu,&cu);
                FP4_YYY_xtr_D(&cum2v,&cv);
                FP4_YYY_conj(&cum2v,&cum2v);
                FP4_YYY_copy(&cv,&t);
            }
            else
            {
                BIG_XXX_copy(w,d);
                BIG_XXX_copy(d,e);
                BIG_XXX_shr(d,1);
                BIG_XXX_copy(e,w);
                FP4_YYY_xtr_D(&t,&cumv);
                FP4_YYY_conj(&cumv,&cum2v);
                FP4_YYY_conj(&cum2v,&t);
                FP4_YYY_xtr_D(&t,&cv);
                FP4_YYY_copy(&cv,&cu);
                FP4_YYY_copy(&cu,&t);
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
                FP4_YYY_xtr_A(&t,&cu,&cv,&cumv,&cum2v);
                FP4_YYY_copy(&cum2v,&cumv);
                FP4_YYY_copy(&cumv,&cu);
                FP4_YYY_copy(&cu,&t);
            }
            else if (BIG_XXX_parity(e)==0)
            {
                BIG_XXX_copy(w,d);
                BIG_XXX_copy(d,e);
                BIG_XXX_shr(d,1);
                BIG_XXX_copy(e,w);
                FP4_YYY_xtr_D(&t,&cumv);
                FP4_YYY_conj(&cumv,&cum2v);
                FP4_YYY_conj(&cum2v,&t);
                FP4_YYY_xtr_D(&t,&cv);
                FP4_YYY_copy(&cv,&cu);
                FP4_YYY_copy(&cu,&t);
            }
            else if (BIG_XXX_parity(d)==1)
            {
                BIG_XXX_copy(w,e);
                BIG_XXX_copy(e,d);
                BIG_XXX_sub(w,w,d);
                BIG_XXX_norm(w);
                BIG_XXX_copy(d,w);
                BIG_XXX_shr(d,1);
                FP4_YYY_xtr_A(&t,&cu,&cv,&cumv,&cum2v);
                FP4_YYY_conj(&cumv,&cumv);
                FP4_YYY_xtr_D(&cum2v,&cu);
                FP4_YYY_conj(&cum2v,&cum2v);
                FP4_YYY_xtr_D(&cu,&cv);
                FP4_YYY_copy(&cv,&t);
            }
            else
            {
                BIG_XXX_shr(d,1);
                FP4_YYY_conj(r,&cum2v);
                FP4_YYY_xtr_A(&t,&cu,&cumv,&cv,r);
                FP4_YYY_xtr_D(&cum2v,&cumv);
                FP4_YYY_copy(&cumv,&t);
                FP4_YYY_xtr_D(&cu,&cu);
            }
        }
    }
    FP4_YYY_xtr_A(r,&cu,&cv,&cumv,&cum2v);
    for (i=0; i<f2; i++)	FP4_YYY_xtr_D(r,r);
    FP4_YYY_xtr_pow(r,r,d);
}

/* Move b to a if d=1 */
void FP4_YYY_cmove(FP4_YYY *f,FP4_YYY *g,int d)
{
    FP2_YYY_cmove(&(f->a),&(g->a),d);
    FP2_YYY_cmove(&(f->b),&(g->b),d);
}

/* New stuff for ECp4 support */

/* Set w=x/2 */
void FP4_YYY_div2(FP4_YYY *w,FP4_YYY *x)
{
    FP2_YYY_div2(&(w->a),&(x->a));
    FP2_YYY_div2(&(w->b),&(x->b));
}

#if CURVE_SECURITY_ZZZ >= 192

/* sqrt(a+xb) = sqrt((a+sqrt(a*a-n*b*b))/2)+x.b/(2*sqrt((a+sqrt(a*a-n*b*b))/2)) */
/* returns true if x is QR */
int FP4_YYY_sqrt(FP4_YYY *r,FP4_YYY* x)
{
    FP2_YYY a,s,t;

    FP4_YYY_copy(r,x);
    if (FP4_YYY_iszilch(x))
        return 1;

    FP2_YYY_copy(&a,&(x->a));
    FP2_YYY_copy(&s,&(x->b));

    if (FP2_YYY_iszilch(&s))
    {
        if (FP2_YYY_sqrt(&t,&a))
        {
            FP4_YYY_from_FP2(r,&t);
        }
        else
        {
            FP2_YYY_div_ip(&a);
            FP2_YYY_sqrt(&t,&a);
            FP4_YYY_from_FP2H(r,&t);
        }
        return 1;
    }

    FP2_YYY_sqr(&s,&s);  // s*=s
    FP2_YYY_sqr(&a,&a);  // a*=a
    FP2_YYY_mul_ip(&s);
    FP2_YYY_norm(&s);
    FP2_YYY_sub(&a,&a,&s); // a-=txx(s)

    if (!FP2_YYY_sqrt(&s,&a)) return 0;

    FP2_YYY_copy(&t,&(x->a));
    FP2_YYY_add(&a,&t,&s);
    FP2_YYY_norm(&a);
    FP2_YYY_div2(&a,&a);

    if (!FP2_YYY_sqrt(&a,&a))
    {
        FP2_YYY_sub(&a,&t,&s);
        FP2_YYY_norm(&a);
        FP2_YYY_div2(&a,&a);
        if (!FP2_YYY_sqrt(&a,&a)) return 0;
    }

    FP2_YYY_copy(&t,&(x->b));
    FP2_YYY_add(&s,&a,&a);
    FP2_YYY_inv(&s,&s);

    FP2_YYY_mul(&t,&t,&s);
    FP4_YYY_from_FP2s(r,&a,&t);

    return 1;
}

void FP4_YYY_div_i(FP4_YYY *f)
{
    FP2_YYY u,v;
    FP2_YYY_copy(&u,&(f->a));
    FP2_YYY_copy(&v,&(f->b));
    FP2_YYY_div_ip(&u);
    FP2_YYY_copy(&(f->a),&v);
    FP2_YYY_copy(&(f->b),&u);
}

void FP4_YYY_div_2i(FP4_YYY *f)
{
    FP2_YYY u,v;
    FP2_YYY_copy(&u,&(f->a));
    FP2_YYY_copy(&v,&(f->b));
    FP2_YYY_div_ip2(&u);
    FP2_YYY_add(&v,&v,&v);
    FP2_YYY_norm(&v);
    FP2_YYY_copy(&(f->a),&v);
    FP2_YYY_copy(&(f->b),&u);
}

#endif
