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

#include "ecp4_ZZZ.h"

int ECP4_ZZZ_isinf(ECP4_ZZZ *P)
{
    return (FP4_YYY_iszilch(&(P->x)) & FP4_YYY_iszilch(&(P->z)));
}

/* Set P=Q */
void ECP4_ZZZ_copy(ECP4_ZZZ *P,ECP4_ZZZ *Q)
{
    FP4_YYY_copy(&(P->x),&(Q->x));
    FP4_YYY_copy(&(P->y),&(Q->y));
    FP4_YYY_copy(&(P->z),&(Q->z));
}

/* set P to Infinity */
void ECP4_ZZZ_inf(ECP4_ZZZ *P)
{
    FP4_YYY_zero(&(P->x));
    FP4_YYY_one(&(P->y));
    FP4_YYY_zero(&(P->z));
}

/* Conditional move Q to P dependant on d */
static void ECP4_ZZZ_cmove(ECP4_ZZZ *P,ECP4_ZZZ *Q,int d)
{
    FP4_YYY_cmove(&(P->x),&(Q->x),d);
    FP4_YYY_cmove(&(P->y),&(Q->y),d);
    FP4_YYY_cmove(&(P->z),&(Q->z),d);

}

/* return 1 if b==c, no branching */
static int teq(sign32 b,sign32 c)
{
    sign32 x=b^c;
    x-=1;  // if x=0, x now -1
    return (int)((x>>31)&1);
}

/* Constant time select from pre-computed table */
static void ECP4_ZZZ_select(ECP4_ZZZ *P,ECP4_ZZZ W[],sign32 b)
{
    ECP4_ZZZ MP;
    sign32 m=b>>31;
    sign32 babs=(b^m)-m;

    babs=(babs-1)/2;

    ECP4_ZZZ_cmove(P,&W[0],teq(babs,0));  // conditional move
    ECP4_ZZZ_cmove(P,&W[1],teq(babs,1));
    ECP4_ZZZ_cmove(P,&W[2],teq(babs,2));
    ECP4_ZZZ_cmove(P,&W[3],teq(babs,3));
    ECP4_ZZZ_cmove(P,&W[4],teq(babs,4));
    ECP4_ZZZ_cmove(P,&W[5],teq(babs,5));
    ECP4_ZZZ_cmove(P,&W[6],teq(babs,6));
    ECP4_ZZZ_cmove(P,&W[7],teq(babs,7));

    ECP4_ZZZ_copy(&MP,P);
    ECP4_ZZZ_neg(&MP);  // minus P
    ECP4_ZZZ_cmove(P,&MP,(int)(m&1));
}

/* Make P affine (so z=1) */
void ECP4_ZZZ_affine(ECP4_ZZZ *P)
{
    FP4_YYY one,iz;
    if (ECP4_ZZZ_isinf(P)) return;

    FP4_YYY_one(&one);
    if (FP4_YYY_isunity(&(P->z)))
    {
        FP4_YYY_reduce(&(P->x));
        FP4_YYY_reduce(&(P->y));
        return;
    }

    FP4_YYY_inv(&iz,&(P->z));
    FP4_YYY_mul(&(P->x),&(P->x),&iz);
    FP4_YYY_mul(&(P->y),&(P->y),&iz);

    FP4_YYY_reduce(&(P->x));
    FP4_YYY_reduce(&(P->y));
    FP4_YYY_copy(&(P->z),&one);
}

/* return 1 if P==Q, else 0 */
/* SU= 312 */
int ECP4_ZZZ_equals(ECP4_ZZZ *P,ECP4_ZZZ *Q)
{
    FP4_YYY a,b;

    FP4_YYY_mul(&a,&(P->x),&(Q->z));
    FP4_YYY_mul(&b,&(Q->x),&(P->z));
    if (!FP4_YYY_equals(&a,&b)) return 0;

    FP4_YYY_mul(&a,&(P->y),&(Q->z));
    FP4_YYY_mul(&b,&(Q->y),&(P->z));
    if (!FP4_YYY_equals(&a,&b)) return 0;
    return 1;

}

/* extract x, y from point P */
int ECP4_ZZZ_get(FP4_YYY *x,FP4_YYY *y,ECP4_ZZZ *P)
{
    ECP4_ZZZ W;
    ECP4_ZZZ_copy(&W,P);
    ECP4_ZZZ_affine(&W);
    if (ECP4_ZZZ_isinf(&W)) return -1;
    FP4_YYY_copy(y,&(W.y));
    FP4_YYY_copy(x,&(W.x));
    return 0;
}

/* Output point P */
void ECP4_ZZZ_output(ECP4_ZZZ *P)
{
    FP4_YYY x,y;
    if (ECP4_ZZZ_isinf(P))
    {
        printf("Infinity\n");
        return;
    }
    ECP4_ZZZ_get(&x,&y,P);
    printf("(");
    FP4_YYY_output(&x);
    printf(",");
    FP4_YYY_output(&y);
    printf(")\n");
}

/* Convert Q to octet string */
void ECP4_ZZZ_toOctet(octet *W,ECP4_ZZZ *Q)
{
    BIG_XXX b;
    FP4_YYY qx,qy;
    FP2_YYY pa,pb;

    ECP4_ZZZ_get(&qx,&qy,Q);

    FP2_YYY_copy(&pa,&(qx.a));
    FP2_YYY_copy(&pb,&(qx.b));

    FP_YYY_redc(b,&(pa.a));
    BIG_XXX_toBytes(&(W->val[0]),b);
    FP_YYY_redc(b,&(pa.b));
    BIG_XXX_toBytes(&(W->val[MODBYTES_XXX]),b);
    FP_YYY_redc(b,&(pb.a));
    BIG_XXX_toBytes(&(W->val[2*MODBYTES_XXX]),b);
    FP_YYY_redc(b,&(pb.b));
    BIG_XXX_toBytes(&(W->val[3*MODBYTES_XXX]),b);

    FP2_YYY_copy(&pa,&(qy.a));
    FP2_YYY_copy(&pb,&(qy.b));

    FP_YYY_redc(b,&(pa.a));
    BIG_XXX_toBytes(&(W->val[4*MODBYTES_XXX]),b);
    FP_YYY_redc(b,&(pa.b));
    BIG_XXX_toBytes(&(W->val[5*MODBYTES_XXX]),b);
    FP_YYY_redc(b,&(pb.a));
    BIG_XXX_toBytes(&(W->val[6*MODBYTES_XXX]),b);
    FP_YYY_redc(b,&(pb.b));
    BIG_XXX_toBytes(&(W->val[7*MODBYTES_XXX]),b);

    W->len=8*MODBYTES_XXX;
}

/* restore Q from octet string */
int ECP4_ZZZ_fromOctet(ECP4_ZZZ *Q,octet *W)
{
    BIG_XXX b;
    FP4_YYY qx,qy;
    FP2_YYY pa,pb;

    BIG_XXX_fromBytes(b,&(W->val[0]));
    FP_YYY_nres(&(pa.a),b);
    BIG_XXX_fromBytes(b,&(W->val[MODBYTES_XXX]));
    FP_YYY_nres(&(pa.b),b);
    BIG_XXX_fromBytes(b,&(W->val[2*MODBYTES_XXX]));
    FP_YYY_nres(&(pb.a),b);
    BIG_XXX_fromBytes(b,&(W->val[3*MODBYTES_XXX]));
    FP_YYY_nres(&(pb.b),b);

    FP2_YYY_copy(&(qx.a),&pa);
    FP2_YYY_copy(&(qx.b),&pb);

    BIG_XXX_fromBytes(b,&(W->val[4*MODBYTES_XXX]));
    FP_YYY_nres(&(pa.a),b);
    BIG_XXX_fromBytes(b,&(W->val[5*MODBYTES_XXX]));
    FP_YYY_nres(&(pa.b),b);
    BIG_XXX_fromBytes(b,&(W->val[6*MODBYTES_XXX]));
    FP_YYY_nres(&(pb.a),b);
    BIG_XXX_fromBytes(b,&(W->val[7*MODBYTES_XXX]));
    FP_YYY_nres(&(pb.b),b);

    FP2_YYY_copy(&(qy.a),&pa);
    FP2_YYY_copy(&(qy.b),&pb);


    if (ECP4_ZZZ_set(Q,&qx,&qy)) return 1;
    return 0;
}

/* Calculate RHS of twisted curve equation x^3+B/i or x^3+Bi*/
void ECP4_ZZZ_rhs(FP4_YYY *rhs,FP4_YYY *x)
{
    /* calculate RHS of elliptic curve equation */
    FP4_YYY t;
    FP2_YYY t2;
    BIG_XXX b;
    FP4_YYY_sqr(&t,x);

    FP4_YYY_mul(rhs,&t,x);

    /* Assuming CURVE_A=0 */

    BIG_XXX_rcopy(b,CURVE_B_ZZZ);

    FP2_YYY_from_BIG(&t2,b);
    FP4_YYY_from_FP2(&t,&t2);

#if SEXTIC_TWIST_ZZZ == D_TYPE
    FP4_YYY_div_i(&t);   /* IMPORTANT - here we use the correct SEXTIC twist of the curve */
#endif

#if SEXTIC_TWIST_ZZZ == M_TYPE
    FP4_YYY_times_i(&t);   /* IMPORTANT - here we use the correct SEXTIC twist of the curve */
#endif

    FP4_YYY_add(rhs,&t,rhs);
    FP4_YYY_reduce(rhs);
}

/* Set P=(x,y). Return 1 if (x,y) is on the curve, else return 0*/
/* SU= 232 */
int ECP4_ZZZ_set(ECP4_ZZZ *P,FP4_YYY *x,FP4_YYY *y)
{
    FP4_YYY rhs,y2;

    FP4_YYY_sqr(&y2,y);
    ECP4_ZZZ_rhs(&rhs,x);

    if (!FP4_YYY_equals(&y2,&rhs))
    {
        ECP4_ZZZ_inf(P);
        return 0;
    }

//   P->inf=0;
    FP4_YYY_copy(&(P->x),x);
    FP4_YYY_copy(&(P->y),y);

    FP4_YYY_one(&(P->z));
    return 1;
}

/* Set P=(x,y). Return 1 if (x,.) is on the curve, else return 0 */
/* SU= 232 */
int ECP4_ZZZ_setx(ECP4_ZZZ *P,FP4_YYY *x)
{
    FP4_YYY y;
    ECP4_ZZZ_rhs(&y,x);

    if (!FP4_YYY_sqrt(&y,&y))
    {
        ECP4_ZZZ_inf(P);
        return 0;
    }

    FP4_YYY_copy(&(P->x),x);
    FP4_YYY_copy(&(P->y),&y);

    FP4_YYY_one(&(P->z));
    return 1;
}

/* Set P=-P */
/* SU= 8 */
void ECP4_ZZZ_neg(ECP4_ZZZ *P)
{
    FP4_YYY_norm(&(P->y));
    FP4_YYY_neg(&(P->y),&(P->y));
    FP4_YYY_norm(&(P->y));
}


/* R+=R */
/* return -1 for Infinity, 0 for addition, 1 for doubling */
int ECP4_ZZZ_dbl(ECP4_ZZZ *P)
{
    FP4_YYY t0,t1,t2,iy,x3,y3;

    FP4_YYY_copy(&iy,&(P->y));		//FP4_YYY iy=new FP4_YYY(y);
#if SEXTIC_TWIST_ZZZ==D_TYPE
    FP4_YYY_times_i(&iy);			//iy.mul_ip();
#endif

    FP4_YYY_sqr(&t0,&(P->y));			//t0.sqr();
#if SEXTIC_TWIST_ZZZ==D_TYPE
    FP4_YYY_times_i(&t0);			//t0.mul_ip();
#endif

    FP4_YYY_mul(&t1,&iy,&(P->z));	//t1.mul(z);
    FP4_YYY_sqr(&t2,&(P->z));				//t2.sqr();

    FP4_YYY_add(&(P->z),&t0,&t0);	//z.add(t0);
    FP4_YYY_norm(&(P->z));				//z.norm();
    FP4_YYY_add(&(P->z),&(P->z),&(P->z));	//z.add(z);
    FP4_YYY_add(&(P->z),&(P->z),&(P->z));	//z.add(z);
    FP4_YYY_norm(&(P->z));			//z.norm();

    FP4_YYY_imul(&t2,&t2,3*CURVE_B_I_ZZZ);	//t2.imul(3*ROM.CURVE_B_I);
#if SEXTIC_TWIST_ZZZ==M_TYPE
    FP4_YYY_times_i(&t2);
#endif

    FP4_YYY_mul(&x3,&t2,&(P->z));	//x3.mul(z);

    FP4_YYY_add(&y3,&t0,&t2);		//y3.add(t2);
    FP4_YYY_norm(&y3);				//y3.norm();
    FP4_YYY_mul(&(P->z),&(P->z),&t1);	//z.mul(t1);

    FP4_YYY_add(&t1,&t2,&t2);		//t1.add(t2);
    FP4_YYY_add(&t2,&t2,&t1);		//t2.add(t1);
    FP4_YYY_norm(&t2);				//t2.norm();
    FP4_YYY_sub(&t0,&t0,&t2);		//t0.sub(t2);
    FP4_YYY_norm(&t0);				//t0.norm();                           //y^2-9bz^2
    FP4_YYY_mul(&y3,&y3,&t0);		//y3.mul(t0);
    FP4_YYY_add(&(P->y),&y3,&x3);		//y3.add(x3);                          //(y^2+3z*2)(y^2-9z^2)+3b.z^2.8y^2

    FP4_YYY_mul(&t1,&(P->x),&iy);		//t1.mul(iy);						//

    FP4_YYY_norm(&t0);				//x.norm();
    FP4_YYY_mul(&(P->x),&t0,&t1);	//x.mul(t1);
    FP4_YYY_add(&(P->x),&(P->x),&(P->x));	//x.add(x);       //(y^2-9bz^2)xy2

    FP4_YYY_norm(&(P->x));			//x.norm();

    FP4_YYY_norm(&(P->y));			//y.norm();

    return 1;
}

/* Set P+=Q */

int ECP4_ZZZ_add(ECP4_ZZZ *P,ECP4_ZZZ *Q)
{
    FP4_YYY t0,t1,t2,t3,t4,x3,y3,z3;
    int b3=3*CURVE_B_I_ZZZ;

    FP4_YYY_mul(&t0,&(P->x),&(Q->x));	//t0.mul(Q.x);         // x.Q.x
    FP4_YYY_mul(&t1,&(P->y),&(Q->y));	//t1.mul(Q.y);		 // y.Q.y

    FP4_YYY_mul(&t2,&(P->z),&(Q->z));	//t2.mul(Q.z);
    FP4_YYY_add(&t3,&(P->x),&(P->y));	//t3.add(y);
    FP4_YYY_norm(&t3);				//t3.norm();          //t3=X1+Y1
    FP4_YYY_add(&t4,&(Q->x),&(Q->y));	//t4.add(Q.y);
    FP4_YYY_norm(&t4);				//t4.norm();			//t4=X2+Y2
    FP4_YYY_mul(&t3,&t3,&t4);		//t3.mul(t4);						//t3=(X1+Y1)(X2+Y2)
    FP4_YYY_add(&t4,&t0,&t1);		//t4.add(t1);		//t4=X1.X2+Y1.Y2

    FP4_YYY_sub(&t3,&t3,&t4);		//t3.sub(t4);
    FP4_YYY_norm(&t3);				//t3.norm();
#if SEXTIC_TWIST_ZZZ==D_TYPE
    FP4_YYY_times_i(&t3);			//t3.mul_ip();  //t3=(X1+Y1)(X2+Y2)-(X1.X2+Y1.Y2) = X1.Y2+X2.Y1
#endif

    FP4_YYY_add(&t4,&(P->y),&(P->z));	//t4.add(z);
    FP4_YYY_norm(&t4);				//t4.norm();			//t4=Y1+Z1

    FP4_YYY_add(&x3,&(Q->y),&(Q->z));	//x3.add(Q.z);
    FP4_YYY_norm(&x3);				//x3.norm();			//x3=Y2+Z2

    FP4_YYY_mul(&t4,&t4,&x3);		//t4.mul(x3);						//t4=(Y1+Z1)(Y2+Z2)

    FP4_YYY_add(&x3,&t1,&t2);		//x3.add(t2);						//X3=Y1.Y2+Z1.Z2

    FP4_YYY_sub(&t4,&t4,&x3);		//t4.sub(x3);
    FP4_YYY_norm(&t4);				//t4.norm();
#if SEXTIC_TWIST_ZZZ==D_TYPE
    FP4_YYY_times_i(&t4);			//t4.mul_ip(); //t4=(Y1+Z1)(Y2+Z2) - (Y1.Y2+Z1.Z2) = Y1.Z2+Y2.Z1
#endif

    FP4_YYY_add(&x3,&(P->x),&(P->z));	//x3.add(z);
    FP4_YYY_norm(&x3);				//x3.norm();	// x3=X1+Z1

    FP4_YYY_add(&y3,&(Q->x),&(Q->z));	//y3.add(Q.z);
    FP4_YYY_norm(&y3);				//y3.norm();				// y3=X2+Z2
    FP4_YYY_mul(&x3,&x3,&y3);		//x3.mul(y3);							// x3=(X1+Z1)(X2+Z2)

    FP4_YYY_add(&y3,&t0,&t2);		//y3.add(t2);							// y3=X1.X2+Z1+Z2
    FP4_YYY_sub(&y3,&x3,&y3);		//y3.rsub(x3);
    FP4_YYY_norm(&y3);				//y3.norm();				// y3=(X1+Z1)(X2+Z2) - (X1.X2+Z1.Z2) = X1.Z2+X2.Z1
#if SEXTIC_TWIST_ZZZ==D_TYPE
    FP4_YYY_times_i(&t0);			//t0.mul_ip();
    FP4_YYY_times_i(&t1);			//t1.mul_ip();
#endif

    FP4_YYY_add(&x3,&t0,&t0);		//x3.add(t0);
    FP4_YYY_add(&t0,&t0,&x3);		//t0.add(x3);
    FP4_YYY_norm(&t0);				//t0.norm();
    FP4_YYY_imul(&t2,&t2,b3);		//t2.imul(b);
#if SEXTIC_TWIST_ZZZ==M_TYPE
    FP4_YYY_times_i(&t2);
#endif

    FP4_YYY_add(&z3,&t1,&t2);		//z3.add(t2);
    FP4_YYY_norm(&z3);				//z3.norm();
    FP4_YYY_sub(&t1,&t1,&t2);		//t1.sub(t2);
    FP4_YYY_norm(&t1);				//t1.norm();
    FP4_YYY_imul(&y3,&y3,b3);		//y3.imul(b);
#if SEXTIC_TWIST_ZZZ==M_TYPE
    FP4_YYY_times_i(&y3);
#endif

    FP4_YYY_mul(&x3,&y3,&t4);		//x3.mul(t4);

    FP4_YYY_mul(&t2,&t3,&t1);		//t2.mul(t1);
    FP4_YYY_sub(&(P->x),&t2,&x3);		//x3.rsub(t2);
    FP4_YYY_mul(&y3,&y3,&t0);		//y3.mul(t0);
    FP4_YYY_mul(&t1,&t1,&z3);		//t1.mul(z3);
    FP4_YYY_add(&(P->y),&y3,&t1);		//y3.add(t1);
    FP4_YYY_mul(&t0,&t0,&t3);		//t0.mul(t3);
    FP4_YYY_mul(&z3,&z3,&t4);		//z3.mul(t4);
    FP4_YYY_add(&(P->z),&z3,&t0);		//z3.add(t0);


    FP4_YYY_norm(&(P->x));			//x.norm();
    FP4_YYY_norm(&(P->y));			//y.norm();
    FP4_YYY_norm(&(P->z));			//z.norm();

    return 0;
}

/* Set P-=Q */
/* SU= 16 */
void ECP4_ZZZ_sub(ECP4_ZZZ *P,ECP4_ZZZ *Q)
{
    ECP4_ZZZ NQ;
    ECP4_ZZZ_copy(&NQ,Q);
    ECP4_ZZZ_neg(&NQ);
    ECP4_ZZZ_add(P,&NQ);
}


void ECP4_ZZZ_reduce(ECP4_ZZZ *P)
{
    FP4_YYY_reduce(&(P->x));
    FP4_YYY_reduce(&(P->y));
    FP4_YYY_reduce(&(P->z));
}

/* P*=e */
/* SU= 280 */
void ECP4_ZZZ_mul(ECP4_ZZZ *P,BIG_XXX e)
{
    /* fixed size windows */
    int i,nb,s,ns;
    BIG_XXX mt,t;
    ECP4_ZZZ Q,W[8],C;
    sign8 w[1+(NLEN_XXX*BASEBITS_XXX+3)/4];

    if (ECP4_ZZZ_isinf(P)) return;

    /* precompute table */

    ECP4_ZZZ_copy(&Q,P);
    ECP4_ZZZ_dbl(&Q);
    ECP4_ZZZ_copy(&W[0],P);

    for (i=1; i<8; i++)
    {
        ECP4_ZZZ_copy(&W[i],&W[i-1]);
        ECP4_ZZZ_add(&W[i],&Q);
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
    ECP4_ZZZ_cmove(&Q,P,ns);
    ECP4_ZZZ_copy(&C,&Q);

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

    ECP4_ZZZ_copy(P,&W[(w[nb]-1)/2]);
    for (i=nb-1; i>=0; i--)
    {
        ECP4_ZZZ_select(&Q,W,w[i]);
        ECP4_ZZZ_dbl(P);
        ECP4_ZZZ_dbl(P);
        ECP4_ZZZ_dbl(P);
        ECP4_ZZZ_dbl(P);
        ECP4_ZZZ_add(P,&Q);
    }
    ECP4_ZZZ_sub(P,&C); /* apply correction */
    ECP4_ZZZ_affine(P);
}

// calculate frobenius constants
void ECP4_ZZZ_frob_constants(FP2_YYY F[3])
{
    FP_YYY fx,fy;
    FP2_YYY X;

    FP_YYY_rcopy(&fx,Fra_YYY);
    FP_YYY_rcopy(&fy,Frb_YYY);
    FP2_YYY_from_FPs(&X,&fx,&fy);

    FP2_YYY_sqr(&F[0],&X);		// FF=F^2=(1+i)^(p-7)/6
    FP2_YYY_copy(&F[2],&F[0]);
    FP2_YYY_mul_ip(&F[2]);		// W=(1+i)^6/6.(1+i)^(p-7)/6 = (1+i)^(p-1)/6
    FP2_YYY_norm(&F[2]);
    FP2_YYY_sqr(&F[1],&F[2]);
    FP2_YYY_mul(&F[2],&F[2],&F[1]);  // W=(1+i)^(p-1)/2

    FP2_YYY_copy(&F[1],&X);

#if SEXTIC_TWIST_ZZZ == M_TYPE
    FP2_YYY_mul_ip(&F[1]);		// (1+i)^12/12.(1+i)^(p-7)/12 = (1+i)^(p+5)/12
    FP2_YYY_inv(&F[1],&F[1]);		// (1+i)^-(p+5)/12
    FP2_YYY_sqr(&F[0],&F[1]);		// (1+i)^-(p+5)/6
#endif

    FP2_YYY_mul_ip(&F[0]);		// FF=(1+i)^(p-7)/6.(1+i) = (1+i)^(p-1)/6					// (1+i)^6/6.(1+i)^-(p+5)/6 = (1+i)^-(p-1)/6
    FP2_YYY_norm(&F[0]);
    FP2_YYY_mul(&F[1],&F[1],&F[0]);  // FFF = (1+i)^(p-7)/12 . (1+i)^(p-1)/6 = (1+i)^(p-3)/4	// (1+i)^-(p+5)/12 . (1+i)^-(p-1)/6 = (1+i)^-(p+1)/4

}

/* Calculates q^n.P using Frobenius constants */
void ECP4_ZZZ_frob(ECP4_ZZZ *P,FP2_YYY F[3],int n)
{
    int i;
    FP4_YYY X,Y,Z;

    FP4_YYY_copy(&X,&(P->x));
    FP4_YYY_copy(&Y,&(P->y));
    FP4_YYY_copy(&Z,&(P->z));

    for (i=0; i<n; i++)
    {
        FP4_YYY_frob(&X,&F[2]);		// X^p
        FP4_YYY_pmul(&X,&X,&F[0]);	// X^p.(1+i)^(p-1)/6									// X^p.(1+i)^-(p-1)/6

        FP4_YYY_frob(&Y,&F[2]);		// Y^p
        FP4_YYY_pmul(&Y,&Y,&F[1]);
        FP4_YYY_times_i(&Y);		// Y.p.(1+i)^(p-3)/4.(1+i)^(2/4) = Y^p.(1+i)^(p-1)/4	// (1+i)^-(p+1)/4 .(1+i)^2/4 = Y^p.(1+i)^-(p-1)/4

        FP4_YYY_frob(&Z,&F[2]);
    }

    FP4_YYY_copy(&(P->x),&X);
    FP4_YYY_copy(&(P->y),&Y);
    FP4_YYY_copy(&(P->z),&Z);
}

/* Side channel attack secure */
// Bos & Costello https://eprint.iacr.org/2013/458.pdf
// Faz-Hernandez & Longa & Sanchez  https://eprint.iacr.org/2013/158.pdf

void ECP4_ZZZ_mul8(ECP4_ZZZ *P,ECP4_ZZZ Q[8],BIG_XXX u[8])
{
    int i,j,k,nb,pb1,pb2,bt;
    ECP4_ZZZ T1[8],T2[8],W;
    BIG_XXX mt,t[8];
    sign8 w1[NLEN_XXX*BASEBITS_XXX+1];
    sign8 s1[NLEN_XXX*BASEBITS_XXX+1];
    sign8 w2[NLEN_XXX*BASEBITS_XXX+1];
    sign8 s2[NLEN_XXX*BASEBITS_XXX+1];
    FP2_YYY X[3];

    ECP4_ZZZ_frob_constants(X);

    for (i=0; i<8; i++)
    {
        BIG_XXX_copy(t[i],u[i]);
    }

// Precomputed table
    ECP4_ZZZ_copy(&T1[0],&Q[0]); // Q[0]
    ECP4_ZZZ_copy(&T1[1],&T1[0]);
    ECP4_ZZZ_add(&T1[1],&Q[1]);	// Q[0]+Q[1]
    ECP4_ZZZ_copy(&T1[2],&T1[0]);
    ECP4_ZZZ_add(&T1[2],&Q[2]);	// Q[0]+Q[2]
    ECP4_ZZZ_copy(&T1[3],&T1[1]);
    ECP4_ZZZ_add(&T1[3],&Q[2]);	// Q[0]+Q[1]+Q[2]
    ECP4_ZZZ_copy(&T1[4],&T1[0]);
    ECP4_ZZZ_add(&T1[4],&Q[3]);  // Q[0]+Q[3]
    ECP4_ZZZ_copy(&T1[5],&T1[1]);
    ECP4_ZZZ_add(&T1[5],&Q[3]);	// Q[0]+Q[1]+Q[3]
    ECP4_ZZZ_copy(&T1[6],&T1[2]);
    ECP4_ZZZ_add(&T1[6],&Q[3]);	// Q[0]+Q[2]+Q[3]
    ECP4_ZZZ_copy(&T1[7],&T1[3]);
    ECP4_ZZZ_add(&T1[7],&Q[3]);	// Q[0]+Q[1]+Q[2]+Q[3]

//  Use Frobenius

    for (i=0; i<8; i++)
    {
        ECP4_ZZZ_copy(&T2[i],&T1[i]);
        ECP4_ZZZ_frob(&T2[i],X,4);
    }

// Make them odd
    pb1=1-BIG_XXX_parity(t[0]);
    BIG_XXX_inc(t[0],pb1);
    BIG_XXX_norm(t[0]);

    pb2=1-BIG_XXX_parity(t[4]);
    BIG_XXX_inc(t[4],pb2);
    BIG_XXX_norm(t[4]);

// Number of bits
    BIG_XXX_zero(mt);
    for (i=0; i<8; i++)
    {
        BIG_XXX_or(mt,mt,t[i]);
    }
    nb=1+BIG_XXX_nbits(mt);

// Sign pivot
    s1[nb-1]=1;
    s2[nb-1]=1;
    for (i=0; i<nb-1; i++)
    {
        BIG_XXX_fshr(t[0],1);
        s1[i]=2*BIG_XXX_parity(t[0])-1;
        BIG_XXX_fshr(t[4],1);
        s2[i]=2*BIG_XXX_parity(t[4])-1;
    }


// Recoded exponents
    for (i=0; i<nb; i++)
    {
        w1[i]=0;
        k=1;
        for (j=1; j<4; j++)
        {
            bt=s1[i]*BIG_XXX_parity(t[j]);
            BIG_XXX_fshr(t[j],1);

            BIG_XXX_dec(t[j],(bt>>1));
            BIG_XXX_norm(t[j]);
            w1[i]+=bt*k;
            k*=2;
        }

        w2[i]=0;
        k=1;
        for (j=5; j<8; j++)
        {
            bt=s2[i]*BIG_XXX_parity(t[j]);
            BIG_XXX_fshr(t[j],1);

            BIG_XXX_dec(t[j],(bt>>1));
            BIG_XXX_norm(t[j]);
            w2[i]+=bt*k;
            k*=2;
        }
    }

// Main loop
    ECP4_ZZZ_select(P,T1,2*w1[nb-1]+1);
    ECP4_ZZZ_select(&W,T2,2*w2[nb-1]+1);
    ECP4_ZZZ_add(P,&W);
    for (i=nb-2; i>=0; i--)
    {
        ECP4_ZZZ_dbl(P);
        ECP4_ZZZ_select(&W,T1,2*w1[i]+s1[i]);
        ECP4_ZZZ_add(P,&W);
        ECP4_ZZZ_select(&W,T2,2*w2[i]+s2[i]);
        ECP4_ZZZ_add(P,&W);
    }

// apply corrections
    ECP4_ZZZ_copy(&W,P);
    ECP4_ZZZ_sub(&W,&Q[0]);
    ECP4_ZZZ_cmove(P,&W,pb1);
    ECP4_ZZZ_copy(&W,P);
    ECP4_ZZZ_sub(&W,&Q[4]);
    ECP4_ZZZ_cmove(P,&W,pb2);

    ECP4_ZZZ_affine(P);
}

/* Map to hash value to point on G2 from random BIG_XXX */

void ECP4_ZZZ_mapit(ECP4_ZZZ *Q,octet *W)
{
    BIG_XXX q,one,x,hv;
    FP2_YYY X[3],T;
    FP4_YYY X4;

    ECP4_ZZZ xQ, x2Q, x3Q, x4Q;

    BIG_XXX_fromBytes(hv,W->val);
    BIG_XXX_rcopy(q,Modulus_YYY);
    BIG_XXX_one(one);
    BIG_XXX_mod(hv,q);

    for (;;)
    {
        FP2_YYY_from_BIGs(&T,one,hv);  /*******/
        FP4_YYY_from_FP2(&X4,&T);
        if (ECP4_ZZZ_setx(Q,&X4)) break;
        BIG_XXX_inc(hv,1);
    }

    ECP4_ZZZ_frob_constants(X);

    BIG_XXX_rcopy(x,CURVE_Bnx_ZZZ);

    // Efficient hash maps to G2 on BLS24 curves - Budroni, Pintore
    // Q -> x4Q -x3Q -Q + F(x3Q-x2Q) + F(F(x2Q-xQ)) + F(F(F(xQ-Q))) +F(F(F(F(2Q))))

    ECP4_ZZZ_copy(&xQ,Q);
    ECP4_ZZZ_mul(&xQ,x);
    ECP4_ZZZ_copy(&x2Q,&xQ);
    ECP4_ZZZ_mul(&x2Q,x);
    ECP4_ZZZ_copy(&x3Q,&x2Q);
    ECP4_ZZZ_mul(&x3Q,x);
    ECP4_ZZZ_copy(&x4Q,&x3Q);
    ECP4_ZZZ_mul(&x4Q,x);

#if SIGN_OF_X_ZZZ==NEGATIVEX
    ECP4_ZZZ_neg(&xQ);
    ECP4_ZZZ_neg(&x3Q);
#endif

    ECP4_ZZZ_sub(&x4Q,&x3Q);
    ECP4_ZZZ_sub(&x4Q,Q);

    ECP4_ZZZ_sub(&x3Q,&x2Q);
    ECP4_ZZZ_frob(&x3Q,X,1);

    ECP4_ZZZ_sub(&x2Q,&xQ);
    ECP4_ZZZ_frob(&x2Q,X,2);

    ECP4_ZZZ_sub(&xQ,Q);
    ECP4_ZZZ_frob(&xQ,X,3);

    ECP4_ZZZ_dbl(Q);
    ECP4_ZZZ_frob(Q,X,4);

    ECP4_ZZZ_add(Q,&x4Q);
    ECP4_ZZZ_add(Q,&x3Q);
    ECP4_ZZZ_add(Q,&x2Q);
    ECP4_ZZZ_add(Q,&xQ);

    ECP4_ZZZ_affine(Q);

}

// ECP$ Get Group Generator

void ECP4_ZZZ_generator(ECP4_ZZZ *G)
{
    BIG_XXX a,b;
    FP2_YYY Aa,Bb;
    FP4_YYY X,Y;

    BIG_XXX_rcopy(a,CURVE_Pxaa_ZZZ);
    BIG_XXX_rcopy(b,CURVE_Pxab_ZZZ);
    FP2_YYY_from_BIGs(&Aa,a,b);

    BIG_XXX_rcopy(a,CURVE_Pxba_ZZZ);
    BIG_XXX_rcopy(b,CURVE_Pxbb_ZZZ);
    FP2_YYY_from_BIGs(&Bb,a,b);

    FP4_YYY_from_FP2s(&X,&Aa,&Bb);

    BIG_XXX_rcopy(a,CURVE_Pyaa_ZZZ);
    BIG_XXX_rcopy(b,CURVE_Pyab_ZZZ);
    FP2_YYY_from_BIGs(&Aa,a,b);

    BIG_XXX_rcopy(a,CURVE_Pyba_ZZZ);
    BIG_XXX_rcopy(b,CURVE_Pybb_ZZZ);
    FP2_YYY_from_BIGs(&Bb,a,b);

    FP4_YYY_from_FP2s(&Y,&Aa,&Bb);

    ECP4_ZZZ_set(G,&X,&Y);
}

