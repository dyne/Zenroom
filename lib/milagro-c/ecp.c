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

/* AMCL Elliptic Curve Functions */
/* SU=m, SU is Stack Usage (Weierstrass Curves) */

//#define HAS_MAIN

#include "amcl.h"

/* test for P=O point-at-infinity */
int ECP_isinf(ECP *P)
{
#if CURVETYPE==EDWARDS
	FP_reduce(P->x);
	FP_reduce(P->y);
	FP_reduce(P->z);
	return (BIG_iszilch(P->x) && BIG_comp(P->y,P->z)==0);
#else
	return P->inf;
#endif
}

/* Conditional swap of P and Q dependant on d */
static void ECP_cswap(ECP *P,ECP *Q,int d)
{
	BIG_cswap(P->x,Q->x,d);
#if CURVETYPE!=MONTGOMERY
	BIG_cswap(P->y,Q->y,d);
#endif
	BIG_cswap(P->z,Q->z,d);
#if CURVETYPE!=EDWARDS
	d=~(d-1);
	d=d&(P->inf^Q->inf);
	P->inf^=d;
	Q->inf^=d;
#endif
}

/* Conditional move Q to P dependant on d */
static void ECP_cmove(ECP *P,ECP *Q,int d)
{
	BIG_cmove(P->x,Q->x,d);
#if CURVETYPE!=MONTGOMERY
	BIG_cmove(P->y,Q->y,d);
#endif
	BIG_cmove(P->z,Q->z,d);
#if CURVETYPE!=EDWARDS
	d=~(d-1);
	P->inf^=(P->inf^Q->inf)&d;
#endif
}

/* return 1 if b==c, no branching */
static int teq(sign32 b,sign32 c)
{
	sign32 x=b^c;
	x-=1;  // if x=0, x now -1
	return (int)((x>>31)&1);
}

/* Constant time select from pre-computed table */
static void ECP_select(ECP *P,ECP W[],sign32 b)
{
  ECP MP;
  sign32 m=b>>31;
  sign32 babs=(b^m)-m;

  babs=(babs-1)/2;

  ECP_cmove(P,&W[0],teq(babs,0));  // conditional move
  ECP_cmove(P,&W[1],teq(babs,1));
  ECP_cmove(P,&W[2],teq(babs,2));
  ECP_cmove(P,&W[3],teq(babs,3));
  ECP_cmove(P,&W[4],teq(babs,4));
  ECP_cmove(P,&W[5],teq(babs,5));
  ECP_cmove(P,&W[6],teq(babs,6));
  ECP_cmove(P,&W[7],teq(babs,7));

  ECP_copy(&MP,P);
  ECP_neg(&MP);  // minus P
  ECP_cmove(P,&MP,(int)(m&1));
}

/* Test P == Q */
/* SU=168 */
int ECP_equals(ECP *P,ECP *Q)
{
#if CURVETYPE==WEIERSTRASS
	BIG pz2,qz2,a,b;
	if (ECP_isinf(P) && ECP_isinf(Q)) return 1;
	if (ECP_isinf(P) || ECP_isinf(Q)) return 0;

	FP_sqr(pz2,P->z); FP_sqr(qz2,Q->z);

	FP_mul(a,P->x,qz2);
	FP_mul(b,Q->x,pz2);
	FP_reduce(a);
	FP_reduce(b);
	if (BIG_comp(a,b)!=0) return 0;

	FP_mul(a,P->y,qz2);
	FP_mul(a,a,Q->z);
	FP_mul(b,Q->y,pz2);
	FP_mul(b,b,P->z);
	FP_reduce(a);
	FP_reduce(b);
	if (BIG_comp(a,b)!=0) return 0;
	return 1;
#else
	BIG a,b;
	if (ECP_isinf(P) && ECP_isinf(Q)) return 1;
	if (ECP_isinf(P) || ECP_isinf(Q)) return 0;

	FP_mul(a,P->x,Q->z);
	FP_mul(b,Q->x,P->z);
	FP_reduce(a);
	FP_reduce(b);
	if (BIG_comp(a,b)!=0) return 0;

#if CURVETYPE==EDWARDS
	FP_mul(a,P->y,Q->z);
	FP_mul(b,Q->y,P->z);
	FP_reduce(a);
	FP_reduce(b);
	if (BIG_comp(a,b)!=0) return 0;
#endif

	return 1;
#endif
}

/* Set P=Q */
/* SU=16 */
void ECP_copy(ECP *P,ECP *Q)
{
#if CURVETYPE!=EDWARDS
	P->inf=Q->inf;
#endif
	BIG_copy(P->x,Q->x);
#if CURVETYPE!=MONTGOMERY
	BIG_copy(P->y,Q->y);
#endif
	BIG_copy(P->z,Q->z);
}

/* Set P=-Q */
#if CURVETYPE!=MONTGOMERY
/* SU=8 */
void ECP_neg(ECP *P)
{
	if (ECP_isinf(P)) return;
#if CURVETYPE==WEIERSTRASS
	FP_neg(P->y,P->y);
	BIG_norm(P->y);
#else
	FP_neg(P->x,P->x);
	BIG_norm(P->x);
#endif

}
#endif

/* Set P=O */
void ECP_inf(ECP *P)
{
#if CURVETYPE==EDWARDS
	BIG_zero(P->x); FP_one(P->y); FP_one(P->z);
#else
	P->inf=1;
#endif
}

/* Calculate right Hand Side of curve equation y^2=RHS */
/* SU=56 */
void ECP_rhs(BIG v,BIG x)
{
#if CURVETYPE==WEIERSTRASS
/* x^3+Ax+B */
	BIG t;
	FP_sqr(t,x);
	FP_mul(t,t,x);

	if (CURVE_A==-3)
	{
		FP_neg(v,x);
		BIG_norm(v);
		BIG_imul(v,v,-CURVE_A);
		BIG_norm(v);
		FP_add(v,t,v);
	}
	else BIG_copy(v,t);

	BIG_rcopy(t,CURVE_B);
	FP_nres(t);
	FP_add(v,t,v);
	FP_reduce(v);
#endif

#if CURVETYPE==EDWARDS
/* (Ax^2-1)/(Bx^2-1) */
	BIG t,m,one;
	BIG_rcopy(m,Modulus);
	FP_sqr(v,x);
	FP_one(one);
	BIG_rcopy(t,CURVE_B); FP_nres(t);
	FP_mul(t,v,t); FP_sub(t,t,one);
	if (CURVE_A==1) FP_sub(v,v,one);

	if (CURVE_A==-1)
	{
		FP_add(v,v,one);
		FP_neg(v,v);
	}
	FP_redc(v); FP_redc(t);
	BIG_moddiv(v,v,t,m);
	FP_nres(v);
#endif

#if CURVETYPE==MONTGOMERY
/* x^3+Ax^2+x */
	BIG x2,x3;
	FP_sqr(x2,x);
	FP_mul(x3,x2,x);
	BIG_copy(v,x);
	FP_imul(x2,x2,CURVE_A);
	FP_add(v,v,x2);
	FP_add(v,v,x3);
	FP_reduce(v);
#endif
}

/* Set P=(x,y) */

#if CURVETYPE==MONTGOMERY

/* Set P=(x,{y}) */

int ECP_set(ECP *P,BIG x)
{
	BIG m,rhs;
	BIG_rcopy(m,Modulus);
	BIG_copy(rhs,x);
	FP_nres(rhs);
	ECP_rhs(rhs,rhs);
	FP_redc(rhs);

	if (BIG_jacobi(rhs,m)!=1)
	{
		ECP_inf(P);
		return 0;
	}
	P->inf=0;
	BIG_copy(P->x,x); FP_nres(P->x);
	FP_one(P->z);
	return 1;
}

/* Extract x coordinate as BIG */
int ECP_get(BIG x,ECP *P)
{
	if (ECP_isinf(P)) return -1;
	ECP_affine(P);
	BIG_copy(x,P->x);
	FP_redc(x);
	return 0;
}


#else
/* Extract (x,y) and return sign of y. If x and y are the same return only x */
/* SU=16 */
int ECP_get(BIG x,BIG y,ECP *P)
{
	int s;
#if CURVETYPE!=EDWARDS
	if (ECP_isinf(P)) return -1;
#endif
	ECP_affine(P);

	BIG_copy(y,P->y);
	FP_redc(y);

	s=BIG_parity(y);

	BIG_copy(x,P->x);
	FP_redc(x);

	return s;
}

/* Set P=(x,{y}) */
/* SU=96 */
int ECP_set(ECP *P,BIG x,BIG y)
{
	BIG rhs,y2;
	BIG_copy(y2,y);

	FP_nres(y2);

	FP_sqr(y2,y2);
	FP_reduce(y2);

	BIG_copy(rhs,x);
	FP_nres(rhs);

	ECP_rhs(rhs,rhs);

	if (BIG_comp(y2,rhs)!=0)
	{
		ECP_inf(P);
		return 0;
	}
#if CURVETYPE==WEIERSTRASS
	P->inf=0;
#endif
	BIG_copy(P->x,x); FP_nres(P->x);
	BIG_copy(P->y,y); FP_nres(P->y);
	FP_one(P->z);
	return 1;
}

/* Set P=(x,y), where y is calculated from x with sign s */
/* SU=136 */
int ECP_setx(ECP *P,BIG x,int s)
{
	BIG t,rhs,m;
	BIG_rcopy(m,Modulus);

	BIG_copy(rhs,x);
	FP_nres(rhs);
	ECP_rhs(rhs,rhs);
	BIG_copy(t,rhs);
	FP_redc(t);
	if (BIG_jacobi(t,m)!=1)
	{
		ECP_inf(P);
		return 0;
	}
#if CURVETYPE==WEIERSTRASS
	P->inf=0;
#endif
	BIG_copy(P->x,x); FP_nres(P->x);

	FP_sqrt(P->y,rhs);
	BIG_copy(rhs,P->y);
	FP_redc(rhs);
	if (BIG_parity(rhs)!=s)
		FP_neg(P->y,P->y);
	FP_reduce(P->y);
	FP_one(P->z);
	return 1;
}

#endif

/* Convert P to Affine, from (x,y,z) to (x,y) */
/* SU=160 */
void ECP_affine(ECP *P)
{
	BIG one,iz,m;
#if CURVETYPE==WEIERSTRASS
	BIG izn;
	if (ECP_isinf(P)) return;
	FP_one(one);
	if (BIG_comp(P->z,one)==0) return;
	BIG_rcopy(m,Modulus);
	FP_redc(P->z);

	BIG_invmodp(iz,P->z,m);
	FP_nres(iz);

	FP_sqr(izn,iz);
	FP_mul(P->x,P->x,izn);
	FP_mul(izn,izn,iz);
	FP_mul(P->y,P->y,izn);
	FP_reduce(P->y);

#endif
#if CURVETYPE==EDWARDS
	FP_one(one);
	if (BIG_comp(P->z,one)==0) return;
	BIG_rcopy(m,Modulus);
	FP_redc(P->z);

	BIG_invmodp(iz,P->z,m);
	FP_nres(iz);

	FP_mul(P->x,P->x,iz);
	FP_mul(P->y,P->y,iz);
	FP_reduce(P->y);

#endif
#if CURVETYPE==MONTGOMERY
	if (ECP_isinf(P)) return;
	FP_one(one);
	if (BIG_comp(P->z,one)==0) return;

	BIG_rcopy(m,Modulus);
	FP_redc(P->z);
	BIG_invmodp(iz,P->z,m);
	FP_nres(iz);

	FP_mul(P->x,P->x,iz);

#endif
	FP_reduce(P->x);
	BIG_copy(P->z,one);
}

/* SU=120 */
void ECP_outputxyz(ECP *P)
{
	BIG x,y,z;
	if (ECP_isinf(P))
	{
		printf("Infinity\n");
		return;
	}
	BIG_copy(x,P->x); FP_reduce(x); FP_redc(x);
	BIG_copy(z,P->z); FP_reduce(z); FP_redc(z);

#if CURVETYPE!=MONTGOMERY
	BIG_copy(y,P->y); FP_reduce(y); FP_redc(y);
	printf("(");BIG_output(x);printf(",");BIG_output(y);printf(",");BIG_output(z);printf(")\n");

#else
	printf("(");BIG_output(x);printf(",");BIG_output(z);printf(")\n");
#endif
}

/* SU=16 */
/* Output point P */
void ECP_output(ECP *P)
{
	if (ECP_isinf(P))
	{
		printf("Infinity\n");
		return;
	}
	ECP_affine(P);
#if CURVETYPE!=MONTGOMERY
	FP_redc(P->x); FP_redc(P->y);
	printf("(");BIG_output(P->x);printf(",");BIG_output(P->y);printf(")\n");
	FP_nres(P->x); FP_nres(P->y);
#else
	FP_redc(P->x);
	printf("(");BIG_output(P->x);printf(")\n");
	FP_nres(P->x);
#endif
}


/* SU=88 */
/* Convert P to octet string */
void ECP_toOctet(octet *W,ECP *P)
{
#if CURVETYPE==MONTGOMERY
	BIG x;
	ECP_get(x,P);
	W->len=MODBYTES+1; W->val[0]=6;
	BIG_toBytes(&(W->val[1]),x);
#else
	BIG x,y;
	ECP_get(x,y,P);
	W->len=2*MODBYTES+1; W->val[0]=4;
	BIG_toBytes(&(W->val[1]),x);
	BIG_toBytes(&(W->val[MODBYTES+1]),y);
#endif
}

/* SU=88 */
/* Restore P from octet string */
int ECP_fromOctet(ECP *P,octet *W)
{
#if CURVETYPE==MONTGOMERY
	BIG x;
	BIG_fromBytes(x,&(W->val[1]));
    if (ECP_set(P,x)) return 1;
	return 0;
#else
	BIG x,y;
	BIG_fromBytes(x,&(W->val[1]));
	BIG_fromBytes(y,&(W->val[MODBYTES+1]));
    if (ECP_set(P,x,y)) return 1;
	return 0;
#endif
}


/* Set P=2P */
/* SU=272 */
void ECP_dbl(ECP *P)
{
#if CURVETYPE==WEIERSTRASS
	int i;
	BIG one,s1,s2;
	BIG w1,w7,w8,w2,w3,w6;
	if (ECP_isinf(P)) return;

	if (BIG_iszilch(P->y))
	{
		P->inf=1;
		return;
	}
	FP_one(one);
	BIG_zero(w6);

	if (CURVE_A==-3)
	{
		if (BIG_comp(P->z,one)==0) BIG_copy(w6,one);
		else FP_sqr(w6,P->z);
		FP_neg(w1,w6);
		FP_add(w3,P->x,w1);
		FP_add(w8,P->x,w6);
		FP_mul(w3,w3,w8);
		BIG_imul(w8,w3,3);
	}
	else
	{
/* assuming A=0 */
		FP_sqr(w1,P->x);
		BIG_imul(w8,w1,3);
	}

	FP_sqr(w2,P->y);
	FP_mul(w3,P->x,w2);

	BIG_imul(w3,w3,4);
	FP_neg(w1,w3);
#if CHUNK<64
	BIG_norm(w1);
#endif
	FP_sqr(P->x,w8);
	FP_add(P->x,P->x,w1);
	FP_add(P->x,P->x,w1);

	BIG_norm(P->x);

	if (BIG_comp(P->z,one)==0) BIG_copy(P->z,P->y);
	else FP_mul(P->z,P->z,P->y);
	FP_add(P->z,P->z,P->z);


	FP_add(w7,w2,w2);
	FP_sqr(w2,w7);

	FP_add(w2,w2,w2);
	FP_sub(w3,w3,P->x);
	FP_mul(P->y,w8,w3);
//#if CHUNK<64
//	BIG_norm(w2);
//#endif
	FP_sub(P->y,P->y,w2);

	BIG_norm(P->y);
	BIG_norm(P->z);

#endif

#if CURVETYPE==EDWARDS
/* Not using square for multiplication swap, as (1) it needs more adds, and (2) it triggers more reductions */
	BIG B,C,D,E,F,H,J;

	FP_mul(B,P->x,P->y); FP_add(B,B,B);
	FP_sqr(C,P->x);
	FP_sqr(D,P->y);
	if (CURVE_A==1) BIG_copy(E,C);
	if (CURVE_A==-1) FP_neg(E,C);
	FP_add(F,E,D);
#if CHUNK<64
	BIG_norm(F);
#endif
	FP_sqr(H,P->z);
	FP_add(H,H,H); FP_sub(J,F,H);
	FP_mul(P->x,B,J);
	FP_sub(E,E,D);
	FP_mul(P->y,F,E);
	FP_mul(P->z,F,J);

	BIG_norm(P->x);
	BIG_norm(P->y);
	BIG_norm(P->z);

#endif

#if CURVETYPE==MONTGOMERY
	BIG t,A,B,AA,BB,C;
	if (ECP_isinf(P)) return;

	FP_add(A,P->x,P->z);
	FP_sqr(AA,A);
	FP_sub(B,P->x,P->z);
	FP_sqr(BB,B);
	FP_sub(C,AA,BB);
//#if CHUNK<64
//	BIG_norm(C);
//#endif

	FP_mul(P->x,AA,BB);
	FP_imul(A,C,(CURVE_A+2)/4);
	FP_add(BB,BB,A);
	FP_mul(P->z,BB,C);

	BIG_norm(P->x);
	BIG_norm(P->z);
#endif
}

#if CURVETYPE==MONTGOMERY

/* Set P+=Q. W is difference between P and Q and is affine */
void ECP_add(ECP *P,ECP *Q,ECP *W)
{
	BIG A,B,C,D,DA,CB;

	FP_add(A,P->x,P->z);
	FP_sub(B,P->x,P->z);

	FP_add(C,Q->x,Q->z);
	FP_sub(D,Q->x,Q->z);

	FP_mul(DA,D,A);
	FP_mul(CB,C,B);

	FP_add(A,DA,CB); FP_sqr(A,A);
	FP_sub(B,DA,CB); FP_sqr(B,B);

	BIG_copy(P->x,A);
	FP_mul(P->z,W->x,B);

	FP_reduce(P->z);
	if (BIG_iszilch(P->z)) P->inf=1;
	else P->inf=0;

	BIG_norm(P->x);
}


#else

/* Set P+=Q */
/* SU=248 */
void ECP_add(ECP *P,ECP *Q)
{
#if CURVETYPE==WEIERSTRASS
	int aff;
	BIG one,B,D,E,C,A;
	if (ECP_isinf(Q)) return;
	if (ECP_isinf(P))
	{
		ECP_copy(P,Q);
		return;
	}

	FP_one(one);
	aff=1;
	if (BIG_comp(Q->z,one)!=0) aff=0;

	if (!aff)
	{
		FP_sqr(A,Q->z);
		FP_mul(C,A,Q->z);

		FP_sqr(B,P->z);
		FP_mul(D,B,P->z);

		FP_mul(A,P->x,A);
		FP_mul(C,P->y,C);
	}
	else
	{
		BIG_copy(A,P->x);
		BIG_copy(C,P->y);

		FP_sqr(B,P->z);
		FP_mul(D,B,P->z);
	}

	FP_mul(B,Q->x,B); FP_sub(B,B,A); /* B=Qx.z^2-x.Qz^2 */
	FP_mul(D,Q->y,D); FP_sub(D,D,C); /* D=Qy.z^3-y.Qz^3 */

	FP_reduce(B);
	if (BIG_iszilch(B))
	{
		FP_reduce(D);
		if (BIG_iszilch(D))
		{
			ECP_dbl(P);
			return;
		}
		else
		{
			ECP_inf(P);
			return;
		}
	}
	if (!aff) FP_mul(P->z,P->z,Q->z);
	FP_mul(P->z,P->z,B);

	FP_sqr(E,B);
	FP_mul(B,B,E);
	FP_mul(A,A,E);

	FP_add(E,A,A);
	FP_add(E,E,B);

	FP_sqr(P->x,D);
	FP_sub(P->x,P->x,E);

	FP_sub(A,A,P->x);
	FP_mul(P->y,A,D);
	FP_mul(C,C,B);
	FP_sub(P->y,P->y,C);

	BIG_norm(P->x);
	BIG_norm(P->y);
	BIG_norm(P->z);

#else
	BIG b,A,B,C,D,E,F,G,H,I;

	BIG_rcopy(b,CURVE_B); FP_nres(b);
	FP_mul(A,P->z,Q->z);

	FP_sqr(B,A);
	FP_mul(C,P->x,Q->x);
	FP_mul(D,P->y,Q->y);
	FP_mul(E,C,D); FP_mul(E,E,b);

	FP_sub(F,B,E);
	FP_add(G,B,E);

	FP_add(C,C,D);

	if (CURVE_A==1) FP_sub(E,D,C);

	FP_add(B,P->x,P->y);
	FP_add(D,Q->x,Q->y);
	FP_mul(B,B,D);
	FP_sub(B,B,C);
	FP_mul(B,B,F);
	FP_mul(P->x,A,B);


	if (CURVE_A==1) FP_mul(C,E,G);
	if (CURVE_A==-1)FP_mul(C,C,G);

	FP_mul(P->y,A,C);
	FP_mul(P->z,F,G);

	BIG_norm(P->x);
	BIG_norm(P->y);
	BIG_norm(P->z);

#endif
}

/* Set P-=Q */
/* SU=16 */
void  ECP_sub(ECP *P,ECP *Q)
{
	ECP_neg(Q);
	ECP_add(P,Q);
	ECP_neg(Q);
}

#endif


#if CURVETYPE==WEIERSTRASS
/* normalises array of points. Assumes P[0] is normalised already */

static void ECP_multiaffine(int m,ECP P[],BIG work[])
{
	int i;
	BIG t1,t2;

	FP_one(work[0]);
	BIG_copy(work[1],P[0].z);
	for (i=2;i<m;i++)
		FP_mul(work[i],work[i-1],P[i-1].z);

	FP_mul(t1,work[m-1],P[m-1].z);
	FP_inv(t1,t1);

	BIG_copy(t2,P[m-1].z);
	FP_mul(work[m-1],work[m-1],t1);

	for (i=m-2;;i--)
    {
		if (i==0)
		{
			FP_mul(work[0],t1,t2);
			break;
		}
		FP_mul(work[i],work[i],t2);
		FP_mul(work[i],work[i],t1);
		FP_mul(t2,P[i].z,t2);
    }
/* now work[] contains inverses of all Z coordinates */

	for (i=0;i<m;i++)
	{
		FP_one(P[i].z);
		FP_sqr(t1,work[i]);
		FP_mul(P[i].x,P[i].x,t1);
		FP_mul(t1,work[i],t1);
		FP_mul(P[i].y,P[i].y,t1);
    }
}

#endif

#if CURVETYPE!=MONTGOMERY
/* constant time multiply by small integer of length bts - use ladder */
void ECP_pinmul(ECP *P,int e,int bts)
{
	int nb,i,b;
	ECP R0,R1;

	ECP_affine(P);
	ECP_inf(&R0);
	ECP_copy(&R1,P);

    for (i=bts-1;i>=0;i--)
	{
		b=(e>>i)&1;
		ECP_copy(P,&R1);
		ECP_add(P,&R0);
		ECP_cswap(&R0,&R1,b);
		ECP_copy(&R1,P);
		ECP_dbl(&R0);
		ECP_cswap(&R0,&R1,b);
	}
	ECP_copy(P,&R0);
	ECP_affine(P);
}
#endif

/* Set P=r*P */
/* SU=424 */
void ECP_mul(ECP *P,BIG e)
{
#if CURVETYPE==MONTGOMERY
/* Montgomery ladder */
	int nb,i,b;
	ECP R0,R1,D;
	if (ECP_isinf(P)) return;
	if (BIG_iszilch(e))
	{
		ECP_inf(P);
		return;
	}
	ECP_affine(P);

	ECP_copy(&R0,P);
	ECP_copy(&R1,P);
	ECP_dbl(&R1);
	ECP_copy(&D,P);

	nb=BIG_nbits(e);
    for (i=nb-2;i>=0;i--)
    {
		b=BIG_bit(e,i);
		ECP_copy(P,&R1);
		ECP_add(P,&R0,&D);
		ECP_cswap(&R0,&R1,b);
		ECP_copy(&R1,P);
		ECP_dbl(&R0);
		ECP_cswap(&R0,&R1,b);
	}
	ECP_copy(P,&R0);

#else
/* fixed size windows */
	int i,b,nb,m,s,ns;
	BIG mt,t;
	ECP Q,W[8],C;
	sign8 w[1+(NLEN*BASEBITS+3)/4];
#if CURVETYPE==WEIERSTRASS
	BIG work[8];
#endif
	if (ECP_isinf(P)) return;
	if (BIG_iszilch(e))
	{
		ECP_inf(P);
		return;
	}

	ECP_affine(P);

/* precompute table */

	ECP_copy(&Q,P);
	ECP_dbl(&Q);
	ECP_copy(&W[0],P);

	for (i=1;i<8;i++)
	{
		ECP_copy(&W[i],&W[i-1]);
		ECP_add(&W[i],&Q);
	}

/* convert the table to affine */
#if CURVETYPE==WEIERSTRASS
	ECP_multiaffine(8,W,work);
#endif

/* make exponent odd - add 2P if even, P if odd */
	BIG_copy(t,e);
	s=BIG_parity(t);
	BIG_inc(t,1); BIG_norm(t); ns=BIG_parity(t); BIG_copy(mt,t); BIG_inc(mt,1); BIG_norm(mt);
	BIG_cmove(t,mt,s);
	ECP_cmove(&Q,P,ns);
	ECP_copy(&C,&Q);

	nb=1+(BIG_nbits(t)+3)/4;

/* convert exponent to signed 4-bit window */
	for (i=0;i<nb;i++)
	{
		w[i]=BIG_lastbits(t,5)-16;
		BIG_dec(t,w[i]); BIG_norm(t);
		BIG_fshr(t,4);
	}
	w[nb]=BIG_lastbits(t,5);

	ECP_copy(P,&W[(w[nb]-1)/2]);
	for (i=nb-1;i>=0;i--)
	{
		ECP_select(&Q,W,w[i]);
		ECP_dbl(P);
		ECP_dbl(P);
		ECP_dbl(P);
		ECP_dbl(P);
		ECP_add(P,&Q);
	}
	ECP_sub(P,&C); /* apply correction */
#endif
	ECP_affine(P);
}

#if CURVETYPE!=MONTGOMERY
/* Set P=eP+fQ double multiplication */
/* constant time - as useful for GLV method in pairings */
/* SU=456 */

void ECP_mul2(ECP *P,ECP *Q,BIG e,BIG f)
{
	BIG te,tf,mt;
	ECP S,T,W[8],C;
	sign8 w[1+(NLEN*BASEBITS+1)/2];
	int i,a,b,s,ns,nb;
#if CURVETYPE==WEIERSTRASS
	BIG work[8];
#endif

	ECP_affine(P);
	ECP_affine(Q);

	BIG_copy(te,e);
	BIG_copy(tf,f);

/* precompute table */
	ECP_copy(&W[1],P); ECP_sub(&W[1],Q);  /* P+Q */
	ECP_copy(&W[2],P); ECP_add(&W[2],Q);  /* P-Q */
	ECP_copy(&S,Q); ECP_dbl(&S);  /* S=2Q */
	ECP_copy(&W[0],&W[1]); ECP_sub(&W[0],&S);
	ECP_copy(&W[3],&W[2]); ECP_add(&W[3],&S);
	ECP_copy(&T,P); ECP_dbl(&T); /* T=2P */
	ECP_copy(&W[5],&W[1]); ECP_add(&W[5],&T);
	ECP_copy(&W[6],&W[2]); ECP_add(&W[6],&T);
	ECP_copy(&W[4],&W[5]); ECP_sub(&W[4],&S);
	ECP_copy(&W[7],&W[6]); ECP_add(&W[7],&S);

#if CURVETYPE==WEIERSTRASS
	ECP_multiaffine(8,W,work);
#endif

/* if multiplier is odd, add 2, else add 1 to multiplier, and add 2P or P to correction */

	s=BIG_parity(te);
	BIG_inc(te,1); BIG_norm(te); ns=BIG_parity(te); BIG_copy(mt,te); BIG_inc(mt,1); BIG_norm(mt);
	BIG_cmove(te,mt,s);
	ECP_cmove(&T,P,ns);
	ECP_copy(&C,&T);

	s=BIG_parity(tf);
	BIG_inc(tf,1); BIG_norm(tf); ns=BIG_parity(tf); BIG_copy(mt,tf); BIG_inc(mt,1); BIG_norm(mt);
	BIG_cmove(tf,mt,s);
	ECP_cmove(&S,Q,ns);
	ECP_add(&C,&S);

	BIG_add(mt,te,tf); BIG_norm(mt);
	nb=1+(BIG_nbits(mt)+1)/2;

/* convert exponent to signed 2-bit window */
	for (i=0;i<nb;i++)
	{
		a=BIG_lastbits(te,3)-4;
		BIG_dec(te,a); BIG_norm(te);
		BIG_fshr(te,2);
		b=BIG_lastbits(tf,3)-4;
		BIG_dec(tf,b); BIG_norm(tf);
		BIG_fshr(tf,2);
		w[i]=4*a+b;
	}
	w[nb]=(4*BIG_lastbits(te,3)+BIG_lastbits(tf,3));

	ECP_copy(P,&W[(w[nb]-1)/2]);
	for (i=nb-1;i>=0;i--)
	{
		ECP_select(&T,W,w[i]);
		ECP_dbl(P);
		ECP_dbl(P);
		ECP_add(P,&T);
	}
	ECP_sub(P,&C); /* apply correction */
	ECP_affine(P);
}

#endif

#ifdef HAS_MAIN

int main()
{
	int i;
	ECP G,P;
	csprng RNG;
	BIG r,s,x,y,b,m,w,q;
	BIG_rcopy(x,CURVE_Gx);
#if CURVETYPE!=MONTGOMERY
	BIG_rcopy(y,CURVE_Gy);
#endif
	BIG_rcopy(m,Modulus);

	printf("x= ");BIG_output(x); printf("\n");
#if CURVETYPE!=MONTGOMERY
	printf("y= ");BIG_output(y); printf("\n");
#endif
	RNG_seed(&RNG,3,"abc");

#if CURVETYPE!=MONTGOMERY
	ECP_set(&G,x,y);
#else
	ECP_set(&G,x);
#endif
	if (ECP_isinf(&G)) printf("Failed to set - point not on curve\n");
	else printf("set success\n");

	ECP_output(&G);

	BIG_rcopy(r,CURVE_Order); //BIG_dec(r,7);
	printf("r= ");BIG_output(r); printf("\n");

	ECP_copy(&P,&G);

	ECP_mul(&P,r);

	ECP_output(&P);
//exit(0);
	BIG_randomnum(w,&RNG);
	BIG_mod(w,r);

	ECP_copy(&P,&G);
	ECP_mul(&P,w);

	ECP_output(&P);

	return 0;
}

#endif
