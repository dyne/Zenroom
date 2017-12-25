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

#include "amcl.h"

int ECP2_isinf(ECP2 *P)
{
    return P->inf;
}

/* Set P=Q */
/* SU= 16 */
void ECP2_copy(ECP2 *P,ECP2 *Q)
{
	P->inf=Q->inf;
	FP2_copy(&(P->x),&(Q->x));
	FP2_copy(&(P->y),&(Q->y));
	FP2_copy(&(P->z),&(Q->z));
}

/* set P to Infinity */
/* SU= 8 */
void ECP2_inf(ECP2 *P)
{
	P->inf=1;
	FP2_zero(&(P->x)); FP2_zero(&(P->y)); FP2_zero(&(P->z));
}

/* Conditional move Q to P dependant on d */
static void ECP2_cmove(ECP2 *P,ECP2 *Q,int d)
{
	FP2_cmove(&(P->x),&(Q->x),d);
	FP2_cmove(&(P->y),&(Q->y),d);
	FP2_cmove(&(P->z),&(Q->z),d);
	d=~(d-1);
	P->inf^=(P->inf^Q->inf)&d;
}

/* return 1 if b==c, no branching */
static int teq(sign32 b,sign32 c)
{
	sign32 x=b^c;
	x-=1;  // if x=0, x now -1
	return (int)((x>>31)&1);
}

/* Constant time select from pre-computed table */
static void ECP2_select(ECP2 *P,ECP2 W[],sign32 b)
{
  ECP2 MP;
  sign32 m=b>>31;
  sign32 babs=(b^m)-m;

  babs=(babs-1)/2;

  ECP2_cmove(P,&W[0],teq(babs,0));  // conditional move
  ECP2_cmove(P,&W[1],teq(babs,1));
  ECP2_cmove(P,&W[2],teq(babs,2));
  ECP2_cmove(P,&W[3],teq(babs,3));
  ECP2_cmove(P,&W[4],teq(babs,4));
  ECP2_cmove(P,&W[5],teq(babs,5));
  ECP2_cmove(P,&W[6],teq(babs,6));
  ECP2_cmove(P,&W[7],teq(babs,7));

  ECP2_copy(&MP,P);
  ECP2_neg(&MP);  // minus P
  ECP2_cmove(P,&MP,(int)(m&1));
}

/* return 1 if P==Q, else 0 */
/* SU= 312 */
int ECP2_equals(ECP2 *P,ECP2 *Q)
{
	FP2 pz2,qz2,a,b;
	if (P->inf && Q->inf) return 1;
	if (P->inf || Q->inf) return 0;

	FP2_sqr(&pz2,&(P->z)); FP2_sqr(&qz2,&(Q->z));

	FP2_mul(&a,&(P->x),&qz2);
	FP2_mul(&b,&(Q->x),&pz2);
	if (!FP2_equals(&a,&b)) return 0;

	FP2_mul(&a,&(P->y),&qz2);
	FP2_mul(&a,&a,&(Q->z));
	FP2_mul(&b,&(Q->y),&pz2);
	FP2_mul(&b,&b,&(P->z));
	if (!FP2_equals(&a,&b)) return 0;
	return 1;
}

/* Make P affine (so z=1) */
/* SU= 232 */
void ECP2_affine(ECP2 *P)
{
	FP2 one,iz,izn;
	if (P->inf) return;

	FP2_one(&one);
	if (FP2_isunity(&(P->z)))
	{
		FP2_reduce(&(P->x));
		FP2_reduce(&(P->y));
		return;
	}

	FP2_inv(&iz,&(P->z));
	FP2_sqr(&izn,&iz);
	FP2_mul(&(P->x),&(P->x),&izn);
	FP2_mul(&izn,&izn,&iz);
	FP2_mul(&(P->y),&(P->y),&izn);

	FP2_reduce(&(P->x));
	FP2_reduce(&(P->y));
	FP2_copy(&(P->z),&one);
}

/* extract x, y from point P */
/* SU= 16 */
int ECP2_get(FP2 *x,FP2 *y,ECP2 *P)
{
	if (P->inf) return -1;
	ECP2_affine(P);
	FP2_copy(y,&(P->y));
	FP2_copy(x,&(P->x));
	return 0;
}

/* SU= 152 */
/* Output point P */
void ECP2_output(ECP2 *P)
{
	FP2 x,y;
	if (P->inf)
	{
		printf("Infinity\n");
		return;
	}
	ECP2_get(&x,&y,P);
	printf("(");FP2_output(&x);printf(",");FP2_output(&y);printf(")\n");
}

/* SU= 232 */
void ECP2_outputxyz(ECP2 *P)
{
	FP2 x,y,z;
	ECP2 Q;
	if (P->inf)
	{
		printf("Infinity\n");
		return;
	}
	ECP2_copy(&Q,P);
	printf("(");FP2_output(&(Q.x));printf(",");FP2_output(&(Q.y));printf(",");FP2_output(&(Q.z)); printf(")\n");
}

/* SU= 168 */
/* Convert Q to octet string */
void ECP2_toOctet(octet *W,ECP2 *Q)
{
	FP2 qx,qy;
	ECP2_get(&qx,&qy,Q);
	FP_redc(qx.a); FP_redc(qx.b); FP_redc(qy.a); FP_redc(qy.b);
	W->len=4*MODBYTES;

	BIG_toBytes(&(W->val[0]),qx.a);
	BIG_toBytes(&(W->val[MODBYTES]),qx.b);
	BIG_toBytes(&(W->val[2*MODBYTES]),qy.a);
	BIG_toBytes(&(W->val[3*MODBYTES]),qy.b);
}

/* SU= 176 */
/* restore Q from octet string */
int ECP2_fromOctet(ECP2 *Q,octet *W)
{
	FP2 qx,qy;
    BIG_fromBytes(qx.a,&(W->val[0]));
    BIG_fromBytes(qx.b,&(W->val[MODBYTES]));
    BIG_fromBytes(qy.a,&(W->val[2*MODBYTES]));
    BIG_fromBytes(qy.b,&(W->val[3*MODBYTES]));
	FP_nres(qx.a); FP_nres(qx.b); FP_nres(qy.a); FP_nres(qy.b);

	if (ECP2_set(Q,&qx,&qy)) return 1;
	return 0;
}

/* SU= 128 */
/* Calculate RHS of twisted curve equation x^3+B/i */
void ECP2_rhs(FP2 *rhs,FP2 *x)
{ /* calculate RHS of elliptic curve equation */
	FP2 t;
	BIG b;
	FP2_sqr(&t,x);

	FP2_mul(rhs,&t,x);

/* Assuming CURVE_A=0 */

	BIG_rcopy(b,CURVE_B);

	FP2_from_BIG(&t,b);

	FP2_div_ip(&t);   /* IMPORTANT - here we use the SEXTIC twist of the curve */

	FP2_add(rhs,&t,rhs);
	FP2_reduce(rhs);
}


/* Set P=(x,y). Return 1 if (x,y) is on the curve, else return 0*/
/* SU= 232 */
int ECP2_set(ECP2 *P,FP2 *x,FP2 *y)
{
	FP2 one,rhs,y2;
	FP2_copy(&y2,y);

	FP2_sqr(&y2,&y2);
	ECP2_rhs(&rhs,x);

	if (!FP2_equals(&y2,&rhs))
	{

		P->inf=1;
		return 0;
	}

	P->inf=0;
	FP2_copy(&(P->x),x);
	FP2_copy(&(P->y),y);

	FP2_one(&one);
	FP2_copy(&(P->z),&one);
	return 1;
}

/* Set P=(x,y). Return 1 if (x,.) is on the curve, else return 0 */
/* SU= 232 */
int ECP2_setx(ECP2 *P,FP2 *x)
{
	FP2 y;
	ECP2_rhs(&y,x);

	if (!FP2_sqrt(&y,&y))
	{
		P->inf=1;
		return 0;
	}

	P->inf=0;
	FP2_copy(&(P->x),x);
	FP2_copy(&(P->y),&y);
	FP2_one(&(P->z));
	return 1;
}

/* Set P=-P */
/* SU= 8 */
void ECP2_neg(ECP2 *P)
{
	FP2_neg(&(P->y),&(P->y));
	FP2_norm(&(P->y));
}

/* R+=R */
/* return -1 for Infinity, 0 for addition, 1 for doubling */
/* SU= 448 */
int ECP2_dbl(ECP2 *P)
{
	FP2 w1,w7,w8,w2,w3;
	if (P->inf) return -1;

	if (FP2_iszilch(&(P->y)))
	{
		P->inf=1;
		return -1;
	}

/* Assuming A=0 */
	FP2_sqr(&w1,&(P->x));
	FP2_imul(&w8,&w1,3);

	FP2_sqr(&w2,&(P->y));
	FP2_mul(&w3,&(P->x),&w2);
	FP2_imul(&w3,&w3,4);

	FP2_neg(&w1,&w3);
#if CHUNK<64
	FP2_norm(&w1);
#endif
	FP2_sqr(&(P->x),&w8);
	FP2_add(&(P->x),&(P->x),&w1);
	FP2_add(&(P->x),&(P->x),&w1);

	FP2_norm(&(P->x));

	if (FP2_isunity(&(P->z))) FP2_copy(&(P->z),&(P->y));
	else FP2_mul(&(P->z),&(P->z),&(P->y));
	FP2_add(&(P->z),&(P->z),&(P->z));

	FP2_add(&w7,&w2,&w2);
	FP2_sqr(&w2,&w7);

	FP2_add(&w2,&w2,&w2);
	FP2_sub(&w3,&w3,&(P->x));

	FP2_mul(&(P->y),&w8,&w3);
//#if CHUNK<64
//	FP2_norm(&w2);
//#endif
	FP2_sub(&(P->y),&(P->y),&w2);


	FP2_norm(&(P->y));
	FP2_norm(&(P->z));

	return 1;
}

/* Set P+=Q */
/* SU= 400 */
int ECP2_add(ECP2 *P,ECP2 *Q)
{
	int aff;
	FP2 B,D,E,C,A;
	if (Q->inf) return 0;
	if (P->inf)
	{
		ECP2_copy(P,Q);
		return 0;
	}

	aff=1;
	if (!FP2_isunity(&(Q->z))) aff=0;

	if (!aff)
	{
		FP2_sqr(&A,&(Q->z));
		FP2_mul(&C,&A,&(Q->z));

		FP2_sqr(&B,&(P->z));
		FP2_mul(&D,&B,&(P->z));

		FP2_mul(&A,&(P->x),&A);
		FP2_mul(&C,&(P->y),&C);
	}
	else
	{
		FP2_copy(&A,&(P->x));
		FP2_copy(&C,&(P->y));

		FP2_sqr(&B,&(P->z));
		FP2_mul(&D,&B,&(P->z));
	}

	FP2_mul(&B,&(Q->x),&B); FP2_sub(&B,&B,&A); /* B=Qx.z^2-x.Qz^2 */
	FP2_mul(&D,&(Q->y),&D); FP2_sub(&D,&D,&C); /* D=Qy.z^3-y.Qz^3 */

	if (FP2_iszilch(&B))
	{
		if (FP2_iszilch(&D))
		{
			ECP2_dbl(P);
			return 1;
		}
		else
		{
			ECP2_inf(P);
			return -1;
		}
	}
	if (!aff) FP2_mul(&(P->z),&(P->z),&(Q->z));
	FP2_mul(&(P->z),&(P->z),&B);

	FP2_sqr(&E,&B);
	FP2_mul(&B,&B,&E);
	FP2_mul(&A,&A,&E);

	FP2_add(&E,&A,&A);
	FP2_add(&E,&E,&B);

	FP2_sqr(&(P->x),&D);
	FP2_sub(&(P->x),&(P->x),&E);

	FP2_sub(&A,&A,&(P->x));
	FP2_mul(&(P->y),&A,&D);
	FP2_mul(&C,&C,&B);
	FP2_sub(&(P->y),&(P->y),&C);

	FP2_norm(&(P->x));
	FP2_norm(&(P->y));
	FP2_norm(&(P->z));

	return 0;
}

/* Set P-=Q */
/* SU= 16 */
void ECP2_sub(ECP2 *P,ECP2 *Q)
{
	ECP2_neg(Q);
	ECP2_add(P,Q);
	ECP2_neg(Q);
}

/* normalises m-array of ECP2 points. Requires work vector of m FP2s */
/* SU= 200 */
static void ECP2_multiaffine(int m,ECP2 *P,FP2 *work)
{
	int i;
	FP2 t1,t2;

	FP2_one(&work[0]);
	FP2_copy(&work[1],&(P[0].z));
	for (i=2;i<m;i++)
		FP2_mul(&work[i],&work[i-1],&(P[i-1].z));
	FP2_mul(&t1,&work[m-1],&(P[m-1].z));

	FP2_inv(&t1,&t1);

	FP2_copy(&t2,&(P[m-1].z));
	FP2_mul(&work[m-1],&work[m-1],&t1);

	for (i=m-2;;i--)
    {
		if (i==0)
		{
			FP2_mul(&work[0],&t1,&t2);
			break;
		}
		FP2_mul(&work[i],&work[i],&t2);
		FP2_mul(&work[i],&work[i],&t1);
		FP2_mul(&t2,&(P[i].z),&t2);
    }
/* now work[] contains inverses of all Z coordinates */

	for (i=0;i<m;i++)
	{
		FP2_one(&(P[i].z));
		FP2_sqr(&t1,&work[i]);
		FP2_mul(&(P[i].x),&(P[i].x),&t1);
		FP2_mul(&t1,&work[i],&t1);
		FP2_mul(&(P[i].y),&(P[i].y),&t1);
    }
}

/* P*=e */
/* SU= 280 */
void ECP2_mul(ECP2 *P,BIG e)
{
/* fixed size windows */
	int i,b,nb,m,s,ns;
	BIG mt,t,r;
	ECP2 Q,W[8],C;
	sign8 w[1+(NLEN*BASEBITS+3)/4];
	FP2 work[8];

	if (ECP2_isinf(P)) return;
	ECP2_affine(P);


/* precompute table */

	ECP2_copy(&Q,P);
	ECP2_dbl(&Q);
	ECP2_copy(&W[0],P);

	for (i=1;i<8;i++)
	{
		ECP2_copy(&W[i],&W[i-1]);
		ECP2_add(&W[i],&Q);
	}

/* convert the table to affine */

	ECP2_multiaffine(8,W,work);

/* make exponent odd - add 2P if even, P if odd */
	BIG_copy(t,e);
	s=BIG_parity(t);
	BIG_inc(t,1); BIG_norm(t); ns=BIG_parity(t); BIG_copy(mt,t); BIG_inc(mt,1); BIG_norm(mt);
	BIG_cmove(t,mt,s);
	ECP2_cmove(&Q,P,ns);
	ECP2_copy(&C,&Q);

	nb=1+(BIG_nbits(t)+3)/4;

/* convert exponent to signed 4-bit window */
	for (i=0;i<nb;i++)
	{
		w[i]=BIG_lastbits(t,5)-16;
		BIG_dec(t,w[i]); BIG_norm(t);
		BIG_fshr(t,4);
	}
	w[nb]=BIG_lastbits(t,5);

	ECP2_copy(P,&W[(w[nb]-1)/2]);
	for (i=nb-1;i>=0;i--)
	{
		ECP2_select(&Q,W,w[i]);
		ECP2_dbl(P);
		ECP2_dbl(P);
		ECP2_dbl(P);
		ECP2_dbl(P);
		ECP2_add(P,&Q);
	}
	ECP2_sub(P,&C); /* apply correction */
	ECP2_affine(P);
}

/* Calculates q.P using Frobenius constant X */
/* SU= 96 */
void ECP2_frob(ECP2 *P,FP2 *X)
{
	FP2 X2;
	if (P->inf) return;
	FP2_sqr(&X2,X);
	FP2_conj(&(P->x),&(P->x));
	FP2_conj(&(P->y),&(P->y));
	FP2_conj(&(P->z),&(P->z));
	FP2_reduce(&(P->z));

	FP2_mul(&(P->x),&X2,&(P->x));
	FP2_mul(&(P->y),&X2,&(P->y));
	FP2_mul(&(P->y),X,&(P->y));
}

void ECP2_mul4(ECP2 *P,ECP2 Q[4],BIG u[4])
{
	int i,j,a[4],nb;
	ECP2 W[8],T,C;
	BIG mt,t[4];
	FP2 work[8];
	sign8 w[NLEN*BASEBITS+1];

	for (i=0;i<4;i++)
	{
		BIG_copy(t[i],u[i]);
		ECP2_affine(&Q[i]);
	}

/* precompute table */

	ECP2_copy(&W[0],&Q[0]); ECP2_sub(&W[0],&Q[1]);  /* P-Q */
	ECP2_copy(&W[1],&W[0]);
	ECP2_copy(&W[2],&W[0]);
	ECP2_copy(&W[3],&W[0]);
	ECP2_copy(&W[4],&Q[0]); ECP2_add(&W[4],&Q[1]);  /* P+Q */
	ECP2_copy(&W[5],&W[4]);
	ECP2_copy(&W[6],&W[4]);
	ECP2_copy(&W[7],&W[4]);

	ECP2_copy(&T,&Q[2]); ECP2_sub(&T,&Q[3]);       /* R-S */
	ECP2_sub(&W[1],&T);
	ECP2_add(&W[2],&T);
	ECP2_sub(&W[5],&T);
	ECP2_add(&W[6],&T);
	ECP2_copy(&T,&Q[2]); ECP2_add(&T,&Q[3]);      /* R+S */
	ECP2_sub(&W[0],&T);
	ECP2_add(&W[3],&T);
	ECP2_sub(&W[4],&T);
	ECP2_add(&W[7],&T);

	ECP2_multiaffine(8,W,work);

/* if multiplier is even add 1 to multiplier, and add P to correction */
	ECP2_inf(&C);

	BIG_zero(mt);
	for (i=0;i<4;i++)
	{
		if (BIG_parity(t[i])==0)
		{
			BIG_inc(t[i],1); BIG_norm(t[i]);
			ECP2_add(&C,&Q[i]);
		}
		BIG_add(mt,mt,t[i]); BIG_norm(mt);
	}

	nb=1+BIG_nbits(mt);

/* convert exponent to signed 1-bit window */
	for (j=0;j<nb;j++)
	{
		for (i=0;i<4;i++)
		{
			a[i]=BIG_lastbits(t[i],2)-2;
			BIG_dec(t[i],a[i]); BIG_norm(t[i]);
			BIG_fshr(t[i],1);
		}
		w[j]=8*a[0]+4*a[1]+2*a[2]+a[3];
	}
	w[nb]=8*BIG_lastbits(t[0],2)+4*BIG_lastbits(t[1],2)+2*BIG_lastbits(t[2],2)+BIG_lastbits(t[3],2);

	ECP2_copy(P,&W[(w[nb]-1)/2]);
	for (i=nb-1;i>=0;i--)
	{
		ECP2_select(&T,W,w[i]);
		ECP2_dbl(P);
		ECP2_add(P,&T);
	}
	ECP2_sub(P,&C); /* apply correction */

	ECP2_affine(P);
}

/*

int main()
{
	int i;
	ECP2 G,P;
	ECP2 *W;
	FP2 x,y,w,z,f;
	BIG r,xa,xb,ya,yb;

	BIG_rcopy(xa,CURVE_Pxa);
	BIG_rcopy(xb,CURVE_Pxb);
	BIG_rcopy(ya,CURVE_Pya);
	BIG_rcopy(yb,CURVE_Pyb);

	FP2_from_BIGs(&x,xa,xb);
	FP2_from_BIGs(&y,ya,yb);
	ECP2_set(&G,&x,&y);
	if (G.inf) printf("Failed to set - point not on curve\n");
	else printf("set success\n");

	ECP2_output(&G);

//	BIG_copy(r,CURVE_Order);
	BIG_rcopy(r,Modulus);

	ECP2_copy(&P,&G);

	ECP2_mul(&P,r);

	ECP2_output(&P);

	FP2_gfc(&f,12);

	ECP2_frob(&G,&f);

	ECP2_output(&G);

	return 0;
}

*/
