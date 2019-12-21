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

/* AMCL Weierstrass elliptic curve functions over FP2 */
/* SU=m, m is Stack Usage */

#include "ecp2_ZZZ.h"

int ECP2_ZZZ_isinf(ECP2_ZZZ *P)
{
    return (FP2_YYY_iszilch(&(P->x)) & FP2_YYY_iszilch(&(P->z)));
}

/* Set P=Q */
/* SU= 16 */
void ECP2_ZZZ_copy(ECP2_ZZZ *P,ECP2_ZZZ *Q)
{
    FP2_YYY_copy(&(P->x),&(Q->x));
    FP2_YYY_copy(&(P->y),&(Q->y));
    FP2_YYY_copy(&(P->z),&(Q->z));
}

/* set P to Infinity */
/* SU= 8 */
void ECP2_ZZZ_inf(ECP2_ZZZ *P)
{
    FP2_YYY_zero(&(P->x));
    FP2_YYY_one(&(P->y));
    FP2_YYY_zero(&(P->z));
}

/* Conditional move Q to P dependant on d */
static void ECP2_ZZZ_cmove(ECP2_ZZZ *P,ECP2_ZZZ *Q,int d)
{
    FP2_YYY_cmove(&(P->x),&(Q->x),d);
    FP2_YYY_cmove(&(P->y),&(Q->y),d);
    FP2_YYY_cmove(&(P->z),&(Q->z),d);
}

/* return 1 if b==c, no branching */
static int teq(sign32 b,sign32 c)
{
    sign32 x=b^c;
    x-=1;  // if x=0, x now -1
    return (int)((x>>31)&1);
}

/* Constant time select from pre-computed table */
static void ECP2_ZZZ_select(ECP2_ZZZ *P,ECP2_ZZZ W[],sign32 b)
{
    ECP2_ZZZ MP;
    sign32 m=b>>31;
    sign32 babs=(b^m)-m;

    babs=(babs-1)/2;

    ECP2_ZZZ_cmove(P,&W[0],teq(babs,0));  // conditional move
    ECP2_ZZZ_cmove(P,&W[1],teq(babs,1));
    ECP2_ZZZ_cmove(P,&W[2],teq(babs,2));
    ECP2_ZZZ_cmove(P,&W[3],teq(babs,3));
    ECP2_ZZZ_cmove(P,&W[4],teq(babs,4));
    ECP2_ZZZ_cmove(P,&W[5],teq(babs,5));
    ECP2_ZZZ_cmove(P,&W[6],teq(babs,6));
    ECP2_ZZZ_cmove(P,&W[7],teq(babs,7));

    ECP2_ZZZ_copy(&MP,P);
    ECP2_ZZZ_neg(&MP);  // minus P
    ECP2_ZZZ_cmove(P,&MP,(int)(m&1));
}

/* return 1 if P==Q, else 0 */
/* SU= 312 */
int ECP2_ZZZ_equals(ECP2_ZZZ *P,ECP2_ZZZ *Q)
{
    FP2_YYY a,b;

    FP2_YYY_mul(&a,&(P->x),&(Q->z));
    FP2_YYY_mul(&b,&(Q->x),&(P->z));
    if (!FP2_YYY_equals(&a,&b)) return 0;

    FP2_YYY_mul(&a,&(P->y),&(Q->z));
    FP2_YYY_mul(&b,&(Q->y),&(P->z));
    if (!FP2_YYY_equals(&a,&b)) return 0;
    return 1;
}

/* Make P affine (so z=1) */
/* SU= 232 */
void ECP2_ZZZ_affine(ECP2_ZZZ *P)
{
    FP2_YYY one,iz;
    if (ECP2_ZZZ_isinf(P)) return;

    FP2_YYY_one(&one);
    if (FP2_YYY_isunity(&(P->z)))
    {
        FP2_YYY_reduce(&(P->x));
        FP2_YYY_reduce(&(P->y));
        return;
    }

    FP2_YYY_inv(&iz,&(P->z));
    FP2_YYY_mul(&(P->x),&(P->x),&iz);
    FP2_YYY_mul(&(P->y),&(P->y),&iz);

    FP2_YYY_reduce(&(P->x));
    FP2_YYY_reduce(&(P->y));
    FP2_YYY_copy(&(P->z),&one);
}

/* extract x, y from point P */
/* SU= 16 */
int ECP2_ZZZ_get(FP2_YYY *x,FP2_YYY *y,ECP2_ZZZ *P)
{
    ECP2_ZZZ W;
    ECP2_ZZZ_copy(&W,P);
    ECP2_ZZZ_affine(&W);
    if (ECP2_ZZZ_isinf(&W)) return -1;
    FP2_YYY_copy(y,&(W.y));
    FP2_YYY_copy(x,&(W.x));
    return 0;
}

/* SU= 152 */
/* Output point P */
void ECP2_ZZZ_output(ECP2_ZZZ *P)
{
    FP2_YYY x,y;
    if (ECP2_ZZZ_isinf(P))
    {
        printf("Infinity\n");
        return;
    }
    ECP2_ZZZ_get(&x,&y,P);
    printf("(");
    FP2_YYY_output(&x);
    printf(",");
    FP2_YYY_output(&y);
    printf(")\n");
}

/* SU= 232 */
void ECP2_ZZZ_outputxyz(ECP2_ZZZ *P)
{
    ECP2_ZZZ Q;
    if (ECP2_ZZZ_isinf(P))
    {
        printf("Infinity\n");
        return;
    }
    ECP2_ZZZ_copy(&Q,P);
    printf("(");
    FP2_YYY_output(&(Q.x));
    printf(",");
    FP2_YYY_output(&(Q.y));
    printf(",");
    FP2_YYY_output(&(Q.z));
    printf(")\n");
}

/* SU= 168 */
/* Convert Q to octet string */
void ECP2_ZZZ_toOctet(octet *W,ECP2_ZZZ *Q)
{
    BIG_XXX b;
    FP2_YYY qx,qy;
    ECP2_ZZZ_get(&qx,&qy,Q);

    FP_YYY_redc(b,&(qx.a));
    BIG_XXX_toBytes(&(W->val[0]),b);
    FP_YYY_redc(b,&(qx.b));
    BIG_XXX_toBytes(&(W->val[MODBYTES_XXX]),b);
    FP_YYY_redc(b,&(qy.a));
    BIG_XXX_toBytes(&(W->val[2*MODBYTES_XXX]),b);
    FP_YYY_redc(b,&(qy.b));
    BIG_XXX_toBytes(&(W->val[3*MODBYTES_XXX]),b);

    W->len=4*MODBYTES_XXX;

}

/* SU= 176 */
/* restore Q from octet string */
int ECP2_ZZZ_fromOctet(ECP2_ZZZ *Q,octet *W)
{
    BIG_XXX b;
    FP2_YYY qx,qy;
    BIG_XXX_fromBytes(b,&(W->val[0]));
    FP_YYY_nres(&(qx.a),b);
    BIG_XXX_fromBytes(b,&(W->val[MODBYTES_XXX]));
    FP_YYY_nres(&(qx.b),b);
    BIG_XXX_fromBytes(b,&(W->val[2*MODBYTES_XXX]));
    FP_YYY_nres(&(qy.a),b);
    BIG_XXX_fromBytes(b,&(W->val[3*MODBYTES_XXX]));
    FP_YYY_nres(&(qy.b),b);

    if (ECP2_ZZZ_set(Q,&qx,&qy)) return 1;
    return 0;
}

/* SU= 128 */
/* Calculate RHS of twisted curve equation x^3+B/i or x^3+Bi*/
void ECP2_ZZZ_rhs(FP2_YYY *rhs,FP2_YYY *x)
{
    /* calculate RHS of elliptic curve equation */
    FP2_YYY t;
    BIG_XXX b;
    FP2_YYY_sqr(&t,x);

    FP2_YYY_mul(rhs,&t,x);

    /* Assuming CURVE_A=0 */

    BIG_XXX_rcopy(b,CURVE_B_ZZZ);

    FP2_YYY_from_BIG(&t,b);

#if SEXTIC_TWIST_ZZZ == D_TYPE
    FP2_YYY_div_ip(&t);   /* IMPORTANT - here we use the correct SEXTIC twist of the curve */
#endif

#if SEXTIC_TWIST_ZZZ == M_TYPE
    FP2_YYY_norm(&t);
    FP2_YYY_mul_ip(&t);   /* IMPORTANT - here we use the correct SEXTIC twist of the curve */
    FP2_YYY_norm(&t);

#endif


    FP2_YYY_add(rhs,&t,rhs);
    FP2_YYY_reduce(rhs);
}


/* Set P=(x,y). Return 1 if (x,y) is on the curve, else return 0*/
/* SU= 232 */
int ECP2_ZZZ_set(ECP2_ZZZ *P,FP2_YYY *x,FP2_YYY *y)
{
    FP2_YYY rhs,y2;

    FP2_YYY_sqr(&y2,y);
    ECP2_ZZZ_rhs(&rhs,x);

    if (!FP2_YYY_equals(&y2,&rhs))
    {
        ECP2_ZZZ_inf(P);
        return 0;
    }

    FP2_YYY_copy(&(P->x),x);
    FP2_YYY_copy(&(P->y),y);

    FP2_YYY_one(&(P->z));
    return 1;
}

/* Set P=(x,y). Return 1 if (x,.) is on the curve, else return 0 */
/* SU= 232 */
int ECP2_ZZZ_setx(ECP2_ZZZ *P,FP2_YYY *x)
{
    FP2_YYY y;
    ECP2_ZZZ_rhs(&y,x);

    if (!FP2_YYY_sqrt(&y,&y))
    {
        ECP2_ZZZ_inf(P);
        return 0;
    }

    FP2_YYY_copy(&(P->x),x);
    FP2_YYY_copy(&(P->y),&y);
    FP2_YYY_one(&(P->z));
    return 1;
}

/* Set P=-P */
/* SU= 8 */
void ECP2_ZZZ_neg(ECP2_ZZZ *P)
{
    FP2_YYY_norm(&(P->y));
    FP2_YYY_neg(&(P->y),&(P->y));
    FP2_YYY_norm(&(P->y));
}

/* R+=R */
/* return -1 for Infinity, 0 for addition, 1 for doubling */
/* SU= 448 */
int ECP2_ZZZ_dbl(ECP2_ZZZ *P)
{
    FP2_YYY t0,t1,t2,iy,x3,y3;

    FP2_YYY_copy(&iy,&(P->y));		//FP2 iy=new FP2(y);
#if SEXTIC_TWIST_ZZZ==D_TYPE
    FP2_YYY_mul_ip(&iy);			//iy.mul_ip();
    FP2_YYY_norm(&iy);				//iy.norm();
#endif
    FP2_YYY_sqr(&t0,&(P->y));			//t0.sqr();
#if SEXTIC_TWIST_ZZZ==D_TYPE
    FP2_YYY_mul_ip(&t0);			//t0.mul_ip();
#endif
    FP2_YYY_mul(&t1,&iy,&(P->z));	//t1.mul(z);
    FP2_YYY_sqr(&t2,&(P->z));				//t2.sqr();

    FP2_YYY_add(&(P->z),&t0,&t0);	//z.add(t0);
    FP2_YYY_norm(&(P->z));				//z.norm();
    FP2_YYY_add(&(P->z),&(P->z),&(P->z));	//z.add(z);
    FP2_YYY_add(&(P->z),&(P->z),&(P->z));	//z.add(z);
    FP2_YYY_norm(&(P->z));			//z.norm();

    FP2_YYY_imul(&t2,&t2,3*CURVE_B_I_ZZZ);	//t2.imul(3*ROM.CURVE_B_I);
#if SEXTIC_TWIST_ZZZ==M_TYPE
    FP2_YYY_mul_ip(&t2);
    FP2_YYY_norm(&t2);
#endif

    FP2_YYY_mul(&x3,&t2,&(P->z));	//x3.mul(z);

    FP2_YYY_add(&y3,&t0,&t2);		//y3.add(t2);
    FP2_YYY_norm(&y3);				//y3.norm();
    FP2_YYY_mul(&(P->z),&(P->z),&t1);	//z.mul(t1);

    FP2_YYY_add(&t1,&t2,&t2);		//t1.add(t2);
    FP2_YYY_add(&t2,&t2,&t1);		//t2.add(t1);
    FP2_YYY_norm(&t2);				//t2.norm();
    FP2_YYY_sub(&t0,&t0,&t2);		//t0.sub(t2);
    FP2_YYY_norm(&t0);				//t0.norm();                           //y^2-9bz^2
    FP2_YYY_mul(&y3,&y3,&t0);		//y3.mul(t0);
    FP2_YYY_add(&(P->y),&y3,&x3);		//y3.add(x3);                          //(y^2+3z*2)(y^2-9z^2)+3b.z^2.8y^2
    FP2_YYY_mul(&t1,&(P->x),&iy);		//t1.mul(iy);						//
    FP2_YYY_norm(&t0);			//x.norm();
    FP2_YYY_mul(&(P->x),&t0,&t1);	//x.mul(t1);
    FP2_YYY_add(&(P->x),&(P->x),&(P->x));	//x.add(x);       //(y^2-9bz^2)xy2

    FP2_YYY_norm(&(P->x));			//x.norm();
    FP2_YYY_norm(&(P->y));			//y.norm();

    return 1;
}

/* Set P+=Q */
/* SU= 400 */
int ECP2_ZZZ_add(ECP2_ZZZ *P,ECP2_ZZZ *Q)
{
    FP2_YYY t0,t1,t2,t3,t4,x3,y3,z3;
    int b3=3*CURVE_B_I_ZZZ;

    FP2_YYY_mul(&t0,&(P->x),&(Q->x));	//t0.mul(Q.x);         // x.Q.x
    FP2_YYY_mul(&t1,&(P->y),&(Q->y));	//t1.mul(Q.y);		 // y.Q.y

    FP2_YYY_mul(&t2,&(P->z),&(Q->z));	//t2.mul(Q.z);
    FP2_YYY_add(&t3,&(P->x),&(P->y));	//t3.add(y);
    FP2_YYY_norm(&t3);				//t3.norm();          //t3=X1+Y1

    FP2_YYY_add(&t4,&(Q->x),&(Q->y));	//t4.add(Q.y);
    FP2_YYY_norm(&t4);				//t4.norm();			//t4=X2+Y2
    FP2_YYY_mul(&t3,&t3,&t4);		//t3.mul(t4);						//t3=(X1+Y1)(X2+Y2)
    FP2_YYY_add(&t4,&t0,&t1);		//t4.add(t1);		//t4=X1.X2+Y1.Y2

    FP2_YYY_sub(&t3,&t3,&t4);		//t3.sub(t4);
    FP2_YYY_norm(&t3);				//t3.norm();
#if SEXTIC_TWIST_ZZZ==D_TYPE
    FP2_YYY_mul_ip(&t3);			//t3.mul_ip();
    FP2_YYY_norm(&t3);				//t3.norm();         //t3=(X1+Y1)(X2+Y2)-(X1.X2+Y1.Y2) = X1.Y2+X2.Y1
#endif
    FP2_YYY_add(&t4,&(P->y),&(P->z));	//t4.add(z);
    FP2_YYY_norm(&t4);				//t4.norm();			//t4=Y1+Z1
    FP2_YYY_add(&x3,&(Q->y),&(Q->z));	//x3.add(Q.z);
    FP2_YYY_norm(&x3);				//x3.norm();			//x3=Y2+Z2

    FP2_YYY_mul(&t4,&t4,&x3);		//t4.mul(x3);						//t4=(Y1+Z1)(Y2+Z2)
    FP2_YYY_add(&x3,&t1,&t2);		//x3.add(t2);						//X3=Y1.Y2+Z1.Z2

    FP2_YYY_sub(&t4,&t4,&x3);		//t4.sub(x3);
    FP2_YYY_norm(&t4);				//t4.norm();
#if SEXTIC_TWIST_ZZZ==D_TYPE
    FP2_YYY_mul_ip(&t4);			//t4.mul_ip();
    FP2_YYY_norm(&t4);				//t4.norm();          //t4=(Y1+Z1)(Y2+Z2) - (Y1.Y2+Z1.Z2) = Y1.Z2+Y2.Z1
#endif
    FP2_YYY_add(&x3,&(P->x),&(P->z));	//x3.add(z);
    FP2_YYY_norm(&x3);				//x3.norm();	// x3=X1+Z1
    FP2_YYY_add(&y3,&(Q->x),&(Q->z));	//y3.add(Q.z);
    FP2_YYY_norm(&y3);				//y3.norm();				// y3=X2+Z2
    FP2_YYY_mul(&x3,&x3,&y3);		//x3.mul(y3);							// x3=(X1+Z1)(X2+Z2)
    FP2_YYY_add(&y3,&t0,&t2);		//y3.add(t2);							// y3=X1.X2+Z1+Z2
    FP2_YYY_sub(&y3,&x3,&y3);		//y3.rsub(x3);
    FP2_YYY_norm(&y3);				//y3.norm();				// y3=(X1+Z1)(X2+Z2) - (X1.X2+Z1.Z2) = X1.Z2+X2.Z1
#if SEXTIC_TWIST_ZZZ==D_TYPE
    FP2_YYY_mul_ip(&t0);			//t0.mul_ip();
    FP2_YYY_norm(&t0);				//t0.norm(); // x.Q.x
    FP2_YYY_mul_ip(&t1);			//t1.mul_ip();
    FP2_YYY_norm(&t1);				//t1.norm(); // y.Q.y
#endif
    FP2_YYY_add(&x3,&t0,&t0);		//x3.add(t0);
    FP2_YYY_add(&t0,&t0,&x3);		//t0.add(x3);
    FP2_YYY_norm(&t0);				//t0.norm();
    FP2_YYY_imul(&t2,&t2,b3);		//t2.imul(b);
#if SEXTIC_TWIST_ZZZ==M_TYPE
    FP2_YYY_mul_ip(&t2);
    FP2_YYY_norm(&t2);
#endif
    FP2_YYY_add(&z3,&t1,&t2);		//z3.add(t2);
    FP2_YYY_norm(&z3);				//z3.norm();
    FP2_YYY_sub(&t1,&t1,&t2);		//t1.sub(t2);
    FP2_YYY_norm(&t1);				//t1.norm();
    FP2_YYY_imul(&y3,&y3,b3);		//y3.imul(b);
#if SEXTIC_TWIST_ZZZ==M_TYPE
    FP2_YYY_mul_ip(&y3);
    FP2_YYY_norm(&y3);
#endif
    FP2_YYY_mul(&x3,&y3,&t4);		//x3.mul(t4);
    FP2_YYY_mul(&t2,&t3,&t1);		//t2.mul(t1);
    FP2_YYY_sub(&(P->x),&t2,&x3);		//x3.rsub(t2);
    FP2_YYY_mul(&y3,&y3,&t0);		//y3.mul(t0);
    FP2_YYY_mul(&t1,&t1,&z3);		//t1.mul(z3);
    FP2_YYY_add(&(P->y),&y3,&t1);		//y3.add(t1);
    FP2_YYY_mul(&t0,&t0,&t3);		//t0.mul(t3);
    FP2_YYY_mul(&z3,&z3,&t4);		//z3.mul(t4);
    FP2_YYY_add(&(P->z),&z3,&t0);		//z3.add(t0);

    FP2_YYY_norm(&(P->x));			//x.norm();
    FP2_YYY_norm(&(P->y));			//y.norm();
    FP2_YYY_norm(&(P->z));			//z.norm();

    return 0;
}

/* Set P-=Q */
/* SU= 16 */
void ECP2_ZZZ_sub(ECP2_ZZZ *P,ECP2_ZZZ *Q)
{
    ECP2_ZZZ NQ;
    ECP2_ZZZ_copy(&NQ,Q);
    ECP2_ZZZ_neg(&NQ);
    ECP2_ZZZ_add(P,&NQ);
}

/* P*=e */
/* SU= 280 */
void ECP2_ZZZ_mul(ECP2_ZZZ *P,BIG_XXX e)
{
    /* fixed size windows */
    int i,nb,s,ns;
    BIG_XXX mt,t;
    ECP2_ZZZ Q,W[8],C;
    sign8 w[1+(NLEN_XXX*BASEBITS_XXX+3)/4];

    if (ECP2_ZZZ_isinf(P)) return;

    /* precompute table */

    ECP2_ZZZ_copy(&Q,P);
    ECP2_ZZZ_dbl(&Q);
    ECP2_ZZZ_copy(&W[0],P);

    for (i=1; i<8; i++)
    {
        ECP2_ZZZ_copy(&W[i],&W[i-1]);
        ECP2_ZZZ_add(&W[i],&Q);
    }

    /* make exponent odd - add 2P if even, P if odd */
    BIG_XXX_copy(t,e);
    s=BIG_XXX_parity(t);
    BIG_XXX_inc(t,1);
    BIG_XXX_norm(t);
    ns=BIG_XXX_parity(t);
    BIG_XXX_copy(mt,t);
    BIG_XXX_inc(mt,1);
    BIG_XXX_norm(mt);
    BIG_XXX_cmove(t,mt,s);
    ECP2_ZZZ_cmove(&Q,P,ns);
    ECP2_ZZZ_copy(&C,&Q);

    nb=1+(BIG_XXX_nbits(t)+3)/4;

    /* convert exponent to signed 4-bit window */
    for (i=0; i<nb; i++)
    {
        w[i]=BIG_XXX_lastbits(t,5)-16;
        BIG_XXX_dec(t,w[i]);
        BIG_XXX_norm(t);
        BIG_XXX_fshr(t,4);
    }
    w[nb]=BIG_XXX_lastbits(t,5);

    ECP2_ZZZ_copy(P,&W[(w[nb]-1)/2]);
    for (i=nb-1; i>=0; i--)
    {
        ECP2_ZZZ_select(&Q,W,w[i]);
        ECP2_ZZZ_dbl(P);
        ECP2_ZZZ_dbl(P);
        ECP2_ZZZ_dbl(P);
        ECP2_ZZZ_dbl(P);
        ECP2_ZZZ_add(P,&Q);
    }
    ECP2_ZZZ_sub(P,&C); /* apply correction */
    ECP2_ZZZ_affine(P);
}

/* Calculates q.P using Frobenius constant X */
/* SU= 96 */
void ECP2_ZZZ_frob(ECP2_ZZZ *P,FP2_YYY *X)
{
    FP2_YYY X2;

    FP2_YYY_sqr(&X2,X);
    FP2_YYY_conj(&(P->x),&(P->x));
    FP2_YYY_conj(&(P->y),&(P->y));
    FP2_YYY_conj(&(P->z),&(P->z));
    FP2_YYY_reduce(&(P->z));

    FP2_YYY_mul(&(P->x),&X2,&(P->x));
    FP2_YYY_mul(&(P->y),&X2,&(P->y));
    FP2_YYY_mul(&(P->y),X,&(P->y));

}


// Bos & Costello https://eprint.iacr.org/2013/458.pdf
// Faz-Hernandez & Longa & Sanchez  https://eprint.iacr.org/2013/158.pdf
// Side channel attack secure

void ECP2_ZZZ_mul4(ECP2_ZZZ *P,ECP2_ZZZ Q[4],BIG_XXX u[4])
{
    int i,j,k,nb,pb,bt;
    ECP2_ZZZ T[8],W;
    BIG_XXX t[4],mt;
    sign8 w[NLEN_XXX*BASEBITS_XXX+1];
    sign8 s[NLEN_XXX*BASEBITS_XXX+1];

    for (i=0; i<4; i++)
    {
        BIG_XXX_copy(t[i],u[i]);
    }

// Precomputed table
    ECP2_ZZZ_copy(&T[0],&Q[0]); // Q[0]
    ECP2_ZZZ_copy(&T[1],&T[0]);
    ECP2_ZZZ_add(&T[1],&Q[1]);	// Q[0]+Q[1]
    ECP2_ZZZ_copy(&T[2],&T[0]);
    ECP2_ZZZ_add(&T[2],&Q[2]);	// Q[0]+Q[2]
    ECP2_ZZZ_copy(&T[3],&T[1]);
    ECP2_ZZZ_add(&T[3],&Q[2]);	// Q[0]+Q[1]+Q[2]
    ECP2_ZZZ_copy(&T[4],&T[0]);
    ECP2_ZZZ_add(&T[4],&Q[3]);  // Q[0]+Q[3]
    ECP2_ZZZ_copy(&T[5],&T[1]);
    ECP2_ZZZ_add(&T[5],&Q[3]);	// Q[0]+Q[1]+Q[3]
    ECP2_ZZZ_copy(&T[6],&T[2]);
    ECP2_ZZZ_add(&T[6],&Q[3]);	// Q[0]+Q[2]+Q[3]
    ECP2_ZZZ_copy(&T[7],&T[3]);
    ECP2_ZZZ_add(&T[7],&Q[3]);	// Q[0]+Q[1]+Q[2]+Q[3]

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
    ECP2_ZZZ_select(P,T,2*w[nb-1]+1);
    for (i=nb-2; i>=0; i--)
    {
        ECP2_ZZZ_select(&W,T,2*w[i]+s[i]);
        ECP2_ZZZ_dbl(P);
        ECP2_ZZZ_add(P,&W);
    }

// apply correction
    ECP2_ZZZ_copy(&W,P);
    ECP2_ZZZ_sub(&W,&Q[0]);
    ECP2_ZZZ_cmove(P,&W,pb);

    ECP2_ZZZ_affine(P);
}

/* Map to hash value to point on G2 from random BIG */
void ECP2_ZZZ_mapit(ECP2_ZZZ *Q,octet *W)
{
    BIG_XXX q,one,Fx,Fy,x,hv;
    FP2_YYY X;
#if (PAIRING_FRIENDLY_ZZZ == BN)
    ECP2_ZZZ T,K;
#elif (PAIRING_FRIENDLY_ZZZ == BLS)
    ECP2_ZZZ xQ, x2Q;
#endif
    BIG_XXX_fromBytes(hv,W->val);
    BIG_XXX_rcopy(q,Modulus_ZZZ);
    BIG_XXX_one(one);
    BIG_XXX_mod(hv,q);

    for (;;)
    {
        FP2_YYY_from_BIGs(&X,one,hv);
        if (ECP2_ZZZ_setx(Q,&X)) break;
        BIG_XXX_inc(hv,1);
    }

    BIG_XXX_rcopy(Fx,Fra_YYY);
    BIG_XXX_rcopy(Fy,Frb_YYY);
    FP2_YYY_from_BIGs(&X,Fx,Fy);

#if SEXTIC_TWIST_ZZZ==M_TYPE
    FP2_YYY_inv(&X,&X);
    FP2_YYY_norm(&X);
#endif

    BIG_XXX_rcopy(x,CURVE_Bnx_ZZZ);

#if (PAIRING_FRIENDLY_ZZZ == BN)

    /* Faster Hashing to G2 - Fuentes-Castaneda, Knapp and Rodriguez-Henriquez */
    /* Q -> xQ + F(3xQ) + F(F(xQ)) + F(F(F(Q))). */
    ECP2_ZZZ_copy(&T,Q);
    ECP2_ZZZ_mul(&T,x);
#if SIGN_OF_X_ZZZ==NEGATIVEX
    ECP2_ZZZ_neg(&T);   // our x is negative
#endif
    ECP2_ZZZ_copy(&K,&T);
    ECP2_ZZZ_dbl(&K);
    ECP2_ZZZ_add(&K,&T);

    ECP2_ZZZ_frob(&K,&X);
    ECP2_ZZZ_frob(Q,&X);
    ECP2_ZZZ_frob(Q,&X);
    ECP2_ZZZ_frob(Q,&X);
    ECP2_ZZZ_add(Q,&T);
    ECP2_ZZZ_add(Q,&K);
    ECP2_ZZZ_frob(&T,&X);
    ECP2_ZZZ_frob(&T,&X);
    ECP2_ZZZ_add(Q,&T);
    ECP2_ZZZ_affine(Q);

#elif (PAIRING_FRIENDLY_ZZZ == BLS)

    /* Efficient hash maps to G2 on BLS curves - Budroni, Pintore */
    /* Q -> x2Q -xQ -Q +F(xQ -Q) +F(F(2Q)) */

    ECP2_ZZZ_copy(&xQ,Q);
    ECP2_ZZZ_mul(&xQ,x);

    ECP2_ZZZ_copy(&x2Q,&xQ);
    ECP2_ZZZ_mul(&x2Q,x);

#if SIGN_OF_X_ZZZ==NEGATIVEX
    ECP2_ZZZ_neg(&xQ);
#endif

    ECP2_ZZZ_sub(&x2Q,&xQ);
    ECP2_ZZZ_sub(&x2Q,Q);

    ECP2_ZZZ_sub(&xQ,Q);
    ECP2_ZZZ_frob(&xQ,&X);

    ECP2_ZZZ_dbl(Q);
    ECP2_ZZZ_frob(Q,&X);
    ECP2_ZZZ_frob(Q,&X);

    ECP2_ZZZ_add(Q,&x2Q);
    ECP2_ZZZ_add(Q,&xQ);

    ECP2_ZZZ_affine(Q);

#endif
}

void ECP2_ZZZ_generator(ECP2_ZZZ *G)
{
    FP2_YYY wx,wy;

    FP_YYY_rcopy(&(wx.a),CURVE_Pxa_ZZZ);
    FP_YYY_rcopy(&(wx.b),CURVE_Pxb_ZZZ);
    FP_YYY_rcopy(&(wy.a),CURVE_Pya_ZZZ);
    FP_YYY_rcopy(&(wy.b),CURVE_Pyb_ZZZ);

    ECP2_ZZZ_set(G,&wx,&wy);
}
