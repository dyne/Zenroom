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

/* FP16 elements are of the form a+ib, where i is sqrt(sqrt(-1+sqrt(-1))) */

#include "fp16_YYY.h"


/* test x==0 ? */
int FP16_YYY_iszilch(FP16_YYY *x)
{
    if (FP8_YYY_iszilch(&(x->a)) && FP8_YYY_iszilch(&(x->b))) return 1;
    return 0;
}

/* test x==1 ? */
int FP16_YYY_isunity(FP16_YYY *x)
{
    if (FP8_YYY_isunity(&(x->a)) && FP8_YYY_iszilch(&(x->b))) return 1;
    return 0;
}

/* test is w real? That is in a+ib test b is zero */
int FP16_YYY_isreal(FP16_YYY *w)
{
    return FP8_YYY_iszilch(&(w->b));
}

/* return 1 if x==y, else 0 */
int FP16_YYY_equals(FP16_YYY *x,FP16_YYY *y)
{
    if (FP8_YYY_equals(&(x->a),&(y->a)) && FP8_YYY_equals(&(x->b),&(y->b)))
        return 1;
    return 0;
}

/* set FP16 from two FP8s */
void FP16_YYY_from_FP8s(FP16_YYY *w,FP8_YYY * x,FP8_YYY* y)
{
    FP8_YYY_copy(&(w->a), x);
    FP8_YYY_copy(&(w->b), y);
}

/* set FP16 from FP8 */
void FP16_YYY_from_FP8(FP16_YYY *w,FP8_YYY *x)
{
    FP8_YYY_copy(&(w->a), x);
    FP8_YYY_zero(&(w->b));
}

/* set high part of FP16 from FP8 */
void FP16_YYY_from_FP8H(FP16_YYY *w,FP8_YYY *x)
{
    FP8_YYY_copy(&(w->b), x);
    FP8_YYY_zero(&(w->a));
}

/* FP16 copy w=x */
void FP16_YYY_copy(FP16_YYY *w,FP16_YYY *x)
{
    if (w==x) return;
    FP8_YYY_copy(&(w->a), &(x->a));
    FP8_YYY_copy(&(w->b), &(x->b));
}

/* FP16 w=0 */
void FP16_YYY_zero(FP16_YYY *w)
{
    FP8_YYY_zero(&(w->a));
    FP8_YYY_zero(&(w->b));
}

/* FP16 w=1 */
void FP16_YYY_one(FP16_YYY *w)
{
    FP8_YYY_one(&(w->a));
    FP8_YYY_zero(&(w->b));
}

/* Set w=-x */
void FP16_YYY_neg(FP16_YYY *w,FP16_YYY *x)
{
    /* Just one field neg */
    FP8_YYY m,t;
    FP16_YYY_norm(x);
    FP8_YYY_add(&m,&(x->a),&(x->b));
    FP8_YYY_norm(&m);
    FP8_YYY_neg(&m,&m);
    FP8_YYY_add(&t,&m,&(x->b));
    FP8_YYY_add(&(w->b),&m,&(x->a));
    FP8_YYY_copy(&(w->a),&t);
    FP16_YYY_norm(w);
}

/* Set w=conj(x) */
void FP16_YYY_conj(FP16_YYY *w,FP16_YYY *x)
{
    FP8_YYY_copy(&(w->a), &(x->a));
    FP8_YYY_neg(&(w->b), &(x->b));
    FP16_YYY_norm(w);
}

/* Set w=-conj(x) */
void FP16_YYY_nconj(FP16_YYY *w,FP16_YYY *x)
{
    FP8_YYY_copy(&(w->b),&(x->b));
    FP8_YYY_neg(&(w->a), &(x->a));
    FP16_YYY_norm(w);
}

/* Set w=x+y */
void FP16_YYY_add(FP16_YYY *w,FP16_YYY *x,FP16_YYY *y)
{
    FP8_YYY_add(&(w->a), &(x->a), &(y->a));
    FP8_YYY_add(&(w->b), &(x->b), &(y->b));
}

/* Set w=x-y */
/* Input y MUST be normed */
void FP16_YYY_sub(FP16_YYY *w,FP16_YYY *x,FP16_YYY *y)
{
    FP16_YYY my;

    FP16_YYY_neg(&my, y);
    FP16_YYY_add(w, x, &my);

}

/* reduce all components of w mod Modulus */
void FP16_YYY_reduce(FP16_YYY *w)
{
    FP8_YYY_reduce(&(w->a));
    FP8_YYY_reduce(&(w->b));
}

/* normalise all elements of w */
void FP16_YYY_norm(FP16_YYY *w)
{
    FP8_YYY_norm(&(w->a));
    FP8_YYY_norm(&(w->b));
}

/* Set w=s*x, where s is FP8 */
void FP16_YYY_pmul(FP16_YYY *w,FP16_YYY *x,FP8_YYY *s)
{
    FP8_YYY_mul(&(w->a),&(x->a),s);
    FP8_YYY_mul(&(w->b),&(x->b),s);
}

/* Set w=s*x, where s is FP2 */
void FP16_YYY_qmul(FP16_YYY *w,FP16_YYY *x,FP2_YYY *s)
{
    FP8_YYY_qmul(&(w->a),&(x->a),s);
    FP8_YYY_qmul(&(w->b),&(x->b),s);
}

/* Set w=s*x, where s is int */
void FP16_YYY_imul(FP16_YYY *w,FP16_YYY *x,int s)
{
    FP8_YYY_imul(&(w->a),&(x->a),s);
    FP8_YYY_imul(&(w->b),&(x->b),s);
}

/* Set w=x^2 */
/* Input MUST be normed  */
void FP16_YYY_sqr(FP16_YYY *w,FP16_YYY *x)
{
    FP8_YYY t1,t2,t3;

    FP8_YYY_mul(&t3,&(x->a),&(x->b)); /* norms x */
    FP8_YYY_copy(&t2,&(x->b));
    FP8_YYY_add(&t1,&(x->a),&(x->b));
    FP8_YYY_times_i(&t2);

    FP8_YYY_add(&t2,&(x->a),&t2);

    FP8_YYY_norm(&t1);  // 2
    FP8_YYY_norm(&t2);  // 2

    FP8_YYY_mul(&(w->a),&t1,&t2);

    FP8_YYY_copy(&t2,&t3);
    FP8_YYY_times_i(&t2);

    FP8_YYY_add(&t2,&t2,&t3);

    FP8_YYY_norm(&t2);  // 2
    FP8_YYY_neg(&t2,&t2);
    FP8_YYY_add(&(w->a),&(w->a),&t2);  /* a=(a+b)(a+i^2.b)-i^2.ab-ab = a*a+ib*ib */
    FP8_YYY_add(&(w->b),&t3,&t3);  /* b=2ab */

    FP16_YYY_norm(w);
}

/* Set w=x*y */
/* Inputs MUST be normed  */
void FP16_YYY_mul(FP16_YYY *w,FP16_YYY *x,FP16_YYY *y)
{

    FP8_YYY t1,t2,t3,t4;
    FP8_YYY_mul(&t1,&(x->a),&(y->a));
    FP8_YYY_mul(&t2,&(x->b),&(y->b));

    FP8_YYY_add(&t3,&(y->b),&(y->a));
    FP8_YYY_add(&t4,&(x->b),&(x->a));

    FP8_YYY_norm(&t4); // 2
    FP8_YYY_norm(&t3); // 2

    FP8_YYY_mul(&t4,&t4,&t3); /* (xa+xb)(ya+yb) */

    FP8_YYY_neg(&t3,&t1);  // 1
    FP8_YYY_add(&t4,&t4,&t3);  //t4E=3
    FP8_YYY_norm(&t4);

    FP8_YYY_neg(&t3,&t2);  // 1
    FP8_YYY_add(&(w->b),&t4,&t3); //wbE=3

    FP8_YYY_times_i(&t2);
    FP8_YYY_add(&(w->a),&t2,&t1);

    FP16_YYY_norm(w);
}

/* output FP16 in format [a,b] */
void FP16_YYY_output(FP16_YYY *w)
{
    printf("[");
    FP8_YYY_output(&(w->a));
    printf(",");
    FP8_YYY_output(&(w->b));
    printf("]");
}

void FP16_YYY_rawoutput(FP16_YYY *w)
{
    printf("[");
    FP8_YYY_rawoutput(&(w->a));
    printf(",");
    FP8_YYY_rawoutput(&(w->b));
    printf("]");
}

/* Set w=1/x */
void FP16_YYY_inv(FP16_YYY *w,FP16_YYY *x)
{
    FP8_YYY t1,t2;
    FP8_YYY_sqr(&t1,&(x->a));
    FP8_YYY_sqr(&t2,&(x->b));
    FP8_YYY_times_i(&t2);
    FP8_YYY_norm(&t2);

    FP8_YYY_sub(&t1,&t1,&t2);
    FP8_YYY_norm(&t1);

    FP8_YYY_inv(&t1,&t1);

    FP8_YYY_mul(&(w->a),&t1,&(x->a));
    FP8_YYY_neg(&t1,&t1);
    FP8_YYY_norm(&t1);
    FP8_YYY_mul(&(w->b),&t1,&(x->b));
}

/* w*=i where i = sqrt(sqrt(-1+sqrt(-1))) */
void FP16_YYY_times_i(FP16_YYY *w)
{
    FP8_YYY s,t;
    FP8_YYY_copy(&s,&(w->b));
    FP8_YYY_copy(&t,&(w->a));
    FP8_YYY_times_i(&s);
    FP8_YYY_copy(&(w->a),&s);
    FP8_YYY_copy(&(w->b),&t);
    FP16_YYY_norm(w);
}

void FP16_YYY_times_i2(FP16_YYY *w)
{
    FP8_YYY_times_i(&(w->a));
    FP8_YYY_times_i(&(w->b));
}

void FP16_YYY_times_i4(FP16_YYY *w)
{
    FP8_YYY_times_i2(&(w->a));
    FP8_YYY_times_i2(&(w->b));
}

/* Set w=w^p using Frobenius */
void FP16_YYY_frob(FP16_YYY *w,FP2_YYY *f)
{
    // f=(i+1)^(p-3)/8
    FP2_YYY ff;

    FP2_YYY_sqr(&ff,f);  // (i+1)^(p-3)/4
    FP2_YYY_norm(&ff);

    FP8_YYY_frob(&(w->a),&ff);
    FP8_YYY_frob(&(w->b),&ff);

    FP8_YYY_qmul(&(w->b),&(w->b),f);  // times (1+i)^(p-3)/8
    FP8_YYY_times_i(&(w->b));		// (i+1)^(p-1)/8
}

/* Set r=a^b mod m */
void FP16_YYY_pow(FP16_YYY *r,FP16_YYY * a,BIG_XXX b)
{
    FP16_YYY w;
    BIG_XXX z,zilch;
    int bt;

    BIG_XXX_zero(zilch);

    BIG_XXX_copy(z,b);
    FP16_YYY_copy(&w,a);
    FP16_YYY_one(r);
    BIG_XXX_norm(z);
    while(1)
    {
        bt=BIG_XXX_parity(z);
        BIG_XXX_shr(z,1);
        if (bt) FP16_YYY_mul(r,r,&w);
        if (BIG_XXX_comp(z,zilch)==0) break;
        FP16_YYY_sqr(&w,&w);
    }
    FP16_YYY_reduce(r);
}

/* Move b to a if d=1 */
void FP16_YYY_cmove(FP16_YYY *f,FP16_YYY *g,int d)
{
    FP8_YYY_cmove(&(f->a),&(g->a),d);
    FP8_YYY_cmove(&(f->b),&(g->b),d);
}

#if CURVE_SECURITY_ZZZ == 256

/* XTR xtr_a function */
void FP16_YYY_xtr_A(FP16_YYY *r,FP16_YYY *w,FP16_YYY *x,FP16_YYY *y,FP16_YYY *z)
{
    FP16_YYY t1,t2;

    FP16_YYY_copy(r,x);
    FP16_YYY_sub(&t1,w,y);
    FP16_YYY_norm(&t1);
    FP16_YYY_pmul(&t1,&t1,&(r->a));
    FP16_YYY_add(&t2,w,y);
    FP16_YYY_norm(&t2);
    FP16_YYY_pmul(&t2,&t2,&(r->b));
    FP16_YYY_times_i(&t2);

    FP16_YYY_add(r,&t1,&t2);
    FP16_YYY_add(r,r,z);

    FP16_YYY_reduce(r);
}

/* XTR xtr_d function */
void FP16_YYY_xtr_D(FP16_YYY *r,FP16_YYY *x)
{
    FP16_YYY w;
    FP16_YYY_copy(r,x);
    FP16_YYY_conj(&w,r);
    FP16_YYY_add(&w,&w,&w);
    FP16_YYY_sqr(r,r);
    FP16_YYY_norm(&w);
    FP16_YYY_sub(r,r,&w);
    FP16_YYY_reduce(r);    /* reduce here as multiple calls trigger automatic reductions */
}

/* r=x^n using XTR method on traces of FP12s */
void FP16_YYY_xtr_pow(FP16_YYY *r,FP16_YYY *x,BIG_XXX n)
{
    int i,par,nb;
    BIG_XXX v;
    FP2_YYY w2;
    FP4_YYY w4;
    FP8_YYY w8;
    FP16_YYY t,a,b,c,sf;

    BIG_XXX_zero(v);
    BIG_XXX_inc(v,3);
    BIG_XXX_norm(v);
    FP2_YYY_from_BIG(&w2,v);
    FP4_YYY_from_FP2(&w4,&w2);
    FP8_YYY_from_FP4(&w8,&w4);
    FP16_YYY_from_FP8(&a,&w8);
    FP16_YYY_copy(&sf,x);
    FP16_YYY_norm(&sf);
    FP16_YYY_copy(&b,&sf);
    FP16_YYY_xtr_D(&c,&sf);


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
            FP16_YYY_copy(&t,&b);
            FP16_YYY_conj(&sf,&sf);
            FP16_YYY_conj(&c,&c);
            FP16_YYY_xtr_A(&b,&a,&b,&sf,&c);
            FP16_YYY_conj(&sf,&sf);
            FP16_YYY_xtr_D(&c,&t);
            FP16_YYY_xtr_D(&a,&a);
        }
        else
        {
            FP16_YYY_conj(&t,&a);
            FP16_YYY_xtr_D(&a,&b);
            FP16_YYY_xtr_A(&b,&c,&b,&sf,&t);
            FP16_YYY_xtr_D(&c,&c);
        }
    }

    if (par==0) FP16_YYY_copy(r,&c);
    else FP16_YYY_copy(r,&b);
    FP16_YYY_reduce(r);
}

/* r=ck^a.cl^n using XTR double exponentiation method on traces of FP12s. See Stam thesis. */
void FP16_YYY_xtr_pow2(FP16_YYY *r,FP16_YYY *ck,FP16_YYY *cl,FP16_YYY *ckml,FP16_YYY *ckm2l,BIG_XXX a,BIG_XXX b)
{
    int i,f2;
    BIG_XXX d,e,w;
    FP16_YYY t,cu,cv,cumv,cum2v;


    BIG_XXX_copy(e,a);
    BIG_XXX_copy(d,b);
    BIG_XXX_norm(d);
    BIG_XXX_norm(e);
    FP16_YYY_copy(&cu,ck);
    FP16_YYY_copy(&cv,cl);
    FP16_YYY_copy(&cumv,ckml);
    FP16_YYY_copy(&cum2v,ckm2l);

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
                FP16_YYY_xtr_A(&t,&cu,&cv,&cumv,&cum2v);
                FP16_YYY_conj(&cum2v,&cumv);
                FP16_YYY_copy(&cumv,&cv);
                FP16_YYY_copy(&cv,&cu);
                FP16_YYY_copy(&cu,&t);
            }
            else if (BIG_XXX_parity(d)==0)
            {
                BIG_XXX_shr(d,1);
                FP16_YYY_conj(r,&cum2v);
                FP16_YYY_xtr_A(&t,&cu,&cumv,&cv,r);
                FP16_YYY_xtr_D(&cum2v,&cumv);
                FP16_YYY_copy(&cumv,&t);
                FP16_YYY_xtr_D(&cu,&cu);
            }
            else if (BIG_XXX_parity(e)==1)
            {
                BIG_XXX_sub(d,d,e);
                BIG_XXX_norm(d);
                BIG_XXX_shr(d,1);
                FP16_YYY_xtr_A(&t,&cu,&cv,&cumv,&cum2v);
                FP16_YYY_xtr_D(&cu,&cu);
                FP16_YYY_xtr_D(&cum2v,&cv);
                FP16_YYY_conj(&cum2v,&cum2v);
                FP16_YYY_copy(&cv,&t);
            }
            else
            {
                BIG_XXX_copy(w,d);
                BIG_XXX_copy(d,e);
                BIG_XXX_shr(d,1);
                BIG_XXX_copy(e,w);
                FP16_YYY_xtr_D(&t,&cumv);
                FP16_YYY_conj(&cumv,&cum2v);
                FP16_YYY_conj(&cum2v,&t);
                FP16_YYY_xtr_D(&t,&cv);
                FP16_YYY_copy(&cv,&cu);
                FP16_YYY_copy(&cu,&t);
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
                FP16_YYY_xtr_A(&t,&cu,&cv,&cumv,&cum2v);
                FP16_YYY_copy(&cum2v,&cumv);
                FP16_YYY_copy(&cumv,&cu);
                FP16_YYY_copy(&cu,&t);
            }
            else if (BIG_XXX_parity(e)==0)
            {
                BIG_XXX_copy(w,d);
                BIG_XXX_copy(d,e);
                BIG_XXX_shr(d,1);
                BIG_XXX_copy(e,w);
                FP16_YYY_xtr_D(&t,&cumv);
                FP16_YYY_conj(&cumv,&cum2v);
                FP16_YYY_conj(&cum2v,&t);
                FP16_YYY_xtr_D(&t,&cv);
                FP16_YYY_copy(&cv,&cu);
                FP16_YYY_copy(&cu,&t);
            }
            else if (BIG_XXX_parity(d)==1)
            {
                BIG_XXX_copy(w,e);
                BIG_XXX_copy(e,d);
                BIG_XXX_sub(w,w,d);
                BIG_XXX_norm(w);
                BIG_XXX_copy(d,w);
                BIG_XXX_shr(d,1);
                FP16_YYY_xtr_A(&t,&cu,&cv,&cumv,&cum2v);
                FP16_YYY_conj(&cumv,&cumv);
                FP16_YYY_xtr_D(&cum2v,&cu);
                FP16_YYY_conj(&cum2v,&cum2v);
                FP16_YYY_xtr_D(&cu,&cv);
                FP16_YYY_copy(&cv,&t);
            }
            else
            {
                BIG_XXX_shr(d,1);
                FP16_YYY_conj(r,&cum2v);
                FP16_YYY_xtr_A(&t,&cu,&cumv,&cv,r);
                FP16_YYY_xtr_D(&cum2v,&cumv);
                FP16_YYY_copy(&cumv,&t);
                FP16_YYY_xtr_D(&cu,&cu);
            }
        }
    }
    FP16_YYY_xtr_A(r,&cu,&cv,&cumv,&cum2v);
    for (i=0; i<f2; i++)	FP16_YYY_xtr_D(r,r);
    FP16_YYY_xtr_pow(r,r,d);
}

#endif

