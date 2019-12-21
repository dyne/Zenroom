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

/* AMCL BN Curve pairing functions */

//#define HAS_MAIN

#include "pair_ZZZ.h"

/* Line function */
static void PAIR_ZZZ_line(FP12_YYY *v,ECP2_ZZZ *A,ECP2_ZZZ *B,FP_YYY *Qx,FP_YYY *Qy)
{
    FP2_YYY X1,Y1,T1,T2;
    FP2_YYY XX,YY,ZZ,YZ;
    FP4_YYY a,b,c;

    if (A==B)
    {
        /* doubling */
        FP2_YYY_copy(&XX,&(A->x));	//FP2 XX=new FP2(A.getx());  //X
        FP2_YYY_copy(&YY,&(A->y));	//FP2 YY=new FP2(A.gety());  //Y
        FP2_YYY_copy(&ZZ,&(A->z));	//FP2 ZZ=new FP2(A.getz());  //Z


        FP2_YYY_copy(&YZ,&YY);		//FP2 YZ=new FP2(YY);        //Y
        FP2_YYY_mul(&YZ,&YZ,&ZZ);		//YZ.mul(ZZ);                //YZ
        FP2_YYY_sqr(&XX,&XX);		//XX.sqr();	               //X^2
        FP2_YYY_sqr(&YY,&YY);		//YY.sqr();	               //Y^2
        FP2_YYY_sqr(&ZZ,&ZZ);		//ZZ.sqr();			       //Z^2

        FP2_YYY_imul(&YZ,&YZ,4);	//YZ.imul(4);
        FP2_YYY_neg(&YZ,&YZ);		//YZ.neg();
        FP2_YYY_norm(&YZ);			//YZ.norm();       //-4YZ

        FP2_YYY_imul(&XX,&XX,6);					//6X^2
        FP2_YYY_pmul(&XX,&XX,Qx);	               //6X^2.Xs

        FP2_YYY_imul(&ZZ,&ZZ,3*CURVE_B_I_ZZZ);	//3Bz^2

        FP2_YYY_pmul(&YZ,&YZ,Qy);	//-4YZ.Ys

#if SEXTIC_TWIST_ZZZ==D_TYPE
        FP2_YYY_div_ip2(&ZZ);		//6(b/i)z^2
#endif
#if SEXTIC_TWIST_ZZZ==M_TYPE
        FP2_YYY_mul_ip(&ZZ);
        FP2_YYY_add(&ZZ,&ZZ,&ZZ);  // 6biz^2
        FP2_YYY_mul_ip(&YZ);
        FP2_YYY_norm(&YZ);
#endif
        FP2_YYY_norm(&ZZ);			// 6bi.Z^2

        FP2_YYY_add(&YY,&YY,&YY);	// 2y^2
        FP2_YYY_sub(&ZZ,&ZZ,&YY);	//
        FP2_YYY_norm(&ZZ);			// 6b.Z^2-2Y^2

        FP4_YYY_from_FP2s(&a,&YZ,&ZZ); // -4YZ.Ys | 6b.Z^2-2Y^2 | 6X^2.Xs
#if SEXTIC_TWIST_ZZZ==D_TYPE
        FP4_YYY_from_FP2(&b,&XX);
        FP4_YYY_zero(&c);
#endif
#if SEXTIC_TWIST_ZZZ==M_TYPE
        FP4_YYY_zero(&b);
        FP4_YYY_from_FP2H(&c,&XX);
#endif

        ECP2_ZZZ_dbl(A);				//A.dbl();
    }
    else
    {
        /* addition */

        FP2_YYY_copy(&X1,&(A->x));		//FP2 X1=new FP2(A.getx());    // X1
        FP2_YYY_copy(&Y1,&(A->y));		//FP2 Y1=new FP2(A.gety());    // Y1
        FP2_YYY_copy(&T1,&(A->z));		//FP2 T1=new FP2(A.getz());    // Z1

        FP2_YYY_copy(&T2,&T1);		//FP2 T2=new FP2(A.getz());    // Z1

        FP2_YYY_mul(&T1,&T1,&(B->y));	//T1.mul(B.gety());    // T1=Z1.Y2
        FP2_YYY_mul(&T2,&T2,&(B->x));	//T2.mul(B.getx());    // T2=Z1.X2

        FP2_YYY_sub(&X1,&X1,&T2);		//X1.sub(T2);
        FP2_YYY_norm(&X1);				//X1.norm();  // X1=X1-Z1.X2
        FP2_YYY_sub(&Y1,&Y1,&T1);		//Y1.sub(T1);
        FP2_YYY_norm(&Y1);				//Y1.norm();  // Y1=Y1-Z1.Y2

        FP2_YYY_copy(&T1,&X1);			//T1.copy(X1);            // T1=X1-Z1.X2

        FP2_YYY_pmul(&X1,&X1,Qy);		//X1.pmul(Qy);            // X1=(X1-Z1.X2).Ys
#if SEXTIC_TWIST_ZZZ==M_TYPE
        FP2_YYY_mul_ip(&X1);
        FP2_YYY_norm(&X1);
#endif

        FP2_YYY_mul(&T1,&T1,&(B->y));	//T1.mul(B.gety());       // T1=(X1-Z1.X2).Y2

        FP2_YYY_copy(&T2,&Y1);			//T2.copy(Y1);            // T2=Y1-Z1.Y2
        FP2_YYY_mul(&T2,&T2,&(B->x));	//T2.mul(B.getx());       // T2=(Y1-Z1.Y2).X2
        FP2_YYY_sub(&T2,&T2,&T1);		//T2.sub(T1);
        FP2_YYY_norm(&T2);				//T2.norm();          // T2=(Y1-Z1.Y2).X2 - (X1-Z1.X2).Y2
        FP2_YYY_pmul(&Y1,&Y1,Qx);		//Y1.pmul(Qx);
        FP2_YYY_neg(&Y1,&Y1);			//Y1.neg();
        FP2_YYY_norm(&Y1);				//Y1.norm(); // Y1=-(Y1-Z1.Y2).Xs

        FP4_YYY_from_FP2s(&a,&X1,&T2);	// (X1-Z1.X2).Ys  |  (Y1-Z1.Y2).X2 - (X1-Z1.X2).Y2  | - (Y1-Z1.Y2).Xs
#if SEXTIC_TWIST_ZZZ==D_TYPE
        FP4_YYY_from_FP2(&b,&Y1);		//b=new FP4(Y1);
        FP4_YYY_zero(&c);
#endif
#if SEXTIC_TWIST_ZZZ==M_TYPE
        FP4_YYY_zero(&b);
        FP4_YYY_from_FP2H(&c,&Y1);		//b=new FP4(Y1);
#endif
        ECP2_ZZZ_add(A,B);			//A.add(B);
    }

    FP12_YYY_from_FP4s(v,&a,&b,&c);
    v->type=AMCL_FP_SPARSER;
}


/* prepare ate parameter, n=6u+2 (BN) or n=u (BLS), n3=3*n */
int PAIR_ZZZ_nbits(BIG_XXX n3,BIG_XXX n)
{
    BIG_XXX x;
    BIG_XXX_rcopy(x,CURVE_Bnx_ZZZ);

#if PAIRING_FRIENDLY_ZZZ==BN
    BIG_XXX_pmul(n,x,6);
#if SIGN_OF_X_ZZZ==POSITIVEX
    BIG_XXX_inc(n,2);
#else
    BIG_XXX_dec(n,2);
#endif

#else
    BIG_XXX_copy(n,x);
#endif

    BIG_XXX_norm(n);
    BIG_XXX_pmul(n3,n,3);
    BIG_XXX_norm(n3);

    return BIG_XXX_nbits(n3);
}

/*
	For multi-pairing, product of n pairings
	1. Declare FP12 array of length number of bits in Ate parameter
	2. Initialise this array by calling PAIR_initmp()
	3. Accumulate each pairing by calling PAIR_another() n times
	4. Call PAIR_miller()
	5. Call final exponentiation PAIR_fexp()
*/

/* prepare for multi-pairing */
void PAIR_ZZZ_initmp(FP12_YYY r[])
{
    int i;
    for (i=ATE_BITS_ZZZ-1; i>=0; i--)
        FP12_YYY_one(&r[i]);
    return;
}

/* basic Miller loop */
void PAIR_ZZZ_miller(FP12_YYY *res,FP12_YYY r[])
{
    int i;
    FP12_YYY_one(res);
    for (i=ATE_BITS_ZZZ-1; i>=1; i--)
    {
        FP12_YYY_sqr(res,res);
        FP12_YYY_ssmul(res,&r[i]);
    }

#if SIGN_OF_X_ZZZ==NEGATIVEX
    FP12_YYY_conj(res,res);
#endif
    FP12_YYY_ssmul(res,&r[0]);
    return;
}

/* Accumulate another set of line functions for n-pairing */
void PAIR_ZZZ_another(FP12_YYY r[],ECP2_ZZZ* PV,ECP_ZZZ* QV)
{
    int i,nb,bt;
    BIG_XXX n,n3;
    FP12_YYY lv,lv2;
    ECP2_ZZZ A,NP,P;
    ECP_ZZZ Q;
    FP_YYY Qx,Qy;
#if PAIRING_FRIENDLY_ZZZ==BN
    ECP2_ZZZ K;
    FP2_YYY X;
    FP_YYY_rcopy(&Qx,Fra_YYY);
    FP_YYY_rcopy(&Qy,Frb_YYY);
    FP2_YYY_from_FPs(&X,&Qx,&Qy);
#if SEXTIC_TWIST_ZZZ==M_TYPE
    FP2_YYY_inv(&X,&X);
    FP2_YYY_norm(&X);
#endif
#endif

    nb=PAIR_ZZZ_nbits(n3,n);

    ECP2_ZZZ_copy(&P,PV);
    ECP_ZZZ_copy(&Q,QV);

    ECP2_ZZZ_affine(&P);
    ECP_ZZZ_affine(&Q);

    FP_YYY_copy(&Qx,&(Q.x));
    FP_YYY_copy(&Qy,&(Q.y));

    ECP2_ZZZ_copy(&A,&P);
    ECP2_ZZZ_copy(&NP,&P);
    ECP2_ZZZ_neg(&NP);

    for (i=nb-2; i>=1; i--)
    {
        PAIR_ZZZ_line(&lv,&A,&A,&Qx,&Qy);

        bt=BIG_XXX_bit(n3,i)-BIG_XXX_bit(n,i); // bt=BIG_bit(n,i);
        if (bt==1)
        {
            PAIR_ZZZ_line(&lv2,&A,&P,&Qx,&Qy);
            FP12_YYY_smul(&lv,&lv2);
        }
        if (bt==-1)
        {
            PAIR_ZZZ_line(&lv2,&A,&NP,&Qx,&Qy);
            FP12_YYY_smul(&lv,&lv2);
        }
        FP12_YYY_ssmul(&r[i],&lv);
    }

#if PAIRING_FRIENDLY_ZZZ==BN

#if SIGN_OF_X_ZZZ==NEGATIVEX
    ECP2_ZZZ_neg(&A);
#endif

    ECP2_ZZZ_copy(&K,&P);
    ECP2_ZZZ_frob(&K,&X);
    PAIR_ZZZ_line(&lv,&A,&K,&Qx,&Qy);
    ECP2_ZZZ_frob(&K,&X);
    ECP2_ZZZ_neg(&K);
    PAIR_ZZZ_line(&lv2,&A,&K,&Qx,&Qy);
    FP12_YYY_smul(&lv,&lv2);
    FP12_YYY_ssmul(&r[0],&lv);

#endif
}

/* Optimal R-ate pairing r=e(P,Q) */
void PAIR_ZZZ_ate(FP12_YYY *r,ECP2_ZZZ *P1,ECP_ZZZ *Q1)
{
    BIG_XXX n,n3;
    FP_YYY Qx,Qy;
    int i,nb,bt;
    ECP2_ZZZ A,NP,P;
    ECP_ZZZ Q;
    FP12_YYY lv,lv2;
#if PAIRING_FRIENDLY_ZZZ==BN
    ECP2_ZZZ KA;
    FP2_YYY X;

    FP_YYY_rcopy(&Qx,Fra_YYY);
    FP_YYY_rcopy(&Qy,Frb_YYY);
    FP2_YYY_from_FPs(&X,&Qx,&Qy);

#if SEXTIC_TWIST_ZZZ==M_TYPE
    FP2_YYY_inv(&X,&X);
    FP2_YYY_norm(&X);
#endif
#endif

    nb=PAIR_ZZZ_nbits(n3,n);

    ECP2_ZZZ_copy(&P,P1);
    ECP_ZZZ_copy(&Q,Q1);

    ECP2_ZZZ_affine(&P);
    ECP_ZZZ_affine(&Q);

    FP_YYY_copy(&Qx,&(Q.x));
    FP_YYY_copy(&Qy,&(Q.y));

    ECP2_ZZZ_copy(&A,&P);
    ECP2_ZZZ_copy(&NP,&P);
    ECP2_ZZZ_neg(&NP);

    FP12_YYY_one(r);

    /* Main Miller Loop */
    for (i=nb-2; i>=1; i--)   //0
    {
        FP12_YYY_sqr(r,r);
        PAIR_ZZZ_line(&lv,&A,&A,&Qx,&Qy);

        bt=BIG_XXX_bit(n3,i)-BIG_XXX_bit(n,i); // bt=BIG_bit(n,i);
        if (bt==1)
        {
            PAIR_ZZZ_line(&lv2,&A,&P,&Qx,&Qy);
            FP12_YYY_smul(&lv,&lv2);
        }
        if (bt==-1)
        {
            PAIR_ZZZ_line(&lv2,&A,&NP,&Qx,&Qy);
            FP12_YYY_smul(&lv,&lv2);
        }
        FP12_YYY_ssmul(r,&lv);

    }


#if SIGN_OF_X_ZZZ==NEGATIVEX
    FP12_YYY_conj(r,r);
#endif

    /* R-ate fixup required for BN curves */
#if PAIRING_FRIENDLY_ZZZ==BN

#if SIGN_OF_X_ZZZ==NEGATIVEX
    ECP2_ZZZ_neg(&A);
#endif

    ECP2_ZZZ_copy(&KA,&P);
    ECP2_ZZZ_frob(&KA,&X);
    PAIR_ZZZ_line(&lv,&A,&KA,&Qx,&Qy);
    ECP2_ZZZ_frob(&KA,&X);
    ECP2_ZZZ_neg(&KA);
    PAIR_ZZZ_line(&lv2,&A,&KA,&Qx,&Qy);
    FP12_YYY_smul(&lv,&lv2);
    FP12_YYY_ssmul(r,&lv);
#endif
}

/* Optimal R-ate double pairing e(P,Q).e(R,S) */
void PAIR_ZZZ_double_ate(FP12_YYY *r,ECP2_ZZZ *P1,ECP_ZZZ *Q1,ECP2_ZZZ *R1,ECP_ZZZ *S1)
{
    BIG_XXX n,n3;
    FP_YYY Qx,Qy,Sx,Sy;
    int i,nb,bt;
    ECP2_ZZZ A,B,NP,NR,P,R;
    ECP_ZZZ Q,S;
    FP12_YYY lv,lv2;
#if PAIRING_FRIENDLY_ZZZ==BN
    FP2_YYY X;
    ECP2_ZZZ K;

    FP_YYY_rcopy(&Qx,Fra_YYY);
    FP_YYY_rcopy(&Qy,Frb_YYY);
    FP2_YYY_from_FPs(&X,&Qx,&Qy);

#if SEXTIC_TWIST_ZZZ==M_TYPE
    FP2_YYY_inv(&X,&X);
    FP2_YYY_norm(&X);
#endif
#endif
    nb=PAIR_ZZZ_nbits(n3,n);

    ECP2_ZZZ_copy(&P,P1);
    ECP_ZZZ_copy(&Q,Q1);

    ECP2_ZZZ_affine(&P);
    ECP_ZZZ_affine(&Q);

    ECP2_ZZZ_copy(&R,R1);
    ECP_ZZZ_copy(&S,S1);

    ECP2_ZZZ_affine(&R);
    ECP_ZZZ_affine(&S);

    FP_YYY_copy(&Qx,&(Q.x));
    FP_YYY_copy(&Qy,&(Q.y));

    FP_YYY_copy(&Sx,&(S.x));
    FP_YYY_copy(&Sy,&(S.y));

    ECP2_ZZZ_copy(&A,&P);
    ECP2_ZZZ_copy(&B,&R);

    ECP2_ZZZ_copy(&NP,&P);
    ECP2_ZZZ_neg(&NP);
    ECP2_ZZZ_copy(&NR,&R);
    ECP2_ZZZ_neg(&NR);

    FP12_YYY_one(r);

    /* Main Miller Loop */
    for (i=nb-2; i>=1; i--)
    {
        FP12_YYY_sqr(r,r);
        PAIR_ZZZ_line(&lv,&A,&A,&Qx,&Qy);
        PAIR_ZZZ_line(&lv2,&B,&B,&Sx,&Sy);
        FP12_YYY_smul(&lv,&lv2);
        FP12_YYY_ssmul(r,&lv);

        bt=BIG_XXX_bit(n3,i)-BIG_XXX_bit(n,i); // bt=BIG_bit(n,i);
        if (bt==1)
        {
            PAIR_ZZZ_line(&lv,&A,&P,&Qx,&Qy);
            PAIR_ZZZ_line(&lv2,&B,&R,&Sx,&Sy);
            FP12_YYY_smul(&lv,&lv2);
            FP12_YYY_ssmul(r,&lv);
        }
        if (bt==-1)
        {
            PAIR_ZZZ_line(&lv,&A,&NP,&Qx,&Qy);
            PAIR_ZZZ_line(&lv2,&B,&NR,&Sx,&Sy);
            FP12_YYY_smul(&lv,&lv2);
            FP12_YYY_ssmul(r,&lv);
        }

    }


    /* R-ate fixup required for BN curves */

#if SIGN_OF_X_ZZZ==NEGATIVEX
    FP12_YYY_conj(r,r);
#endif

#if PAIRING_FRIENDLY_ZZZ==BN

#if SIGN_OF_X_ZZZ==NEGATIVEX
    ECP2_ZZZ_neg(&A);
    ECP2_ZZZ_neg(&B);
#endif

    ECP2_ZZZ_copy(&K,&P);
    ECP2_ZZZ_frob(&K,&X);
    PAIR_ZZZ_line(&lv,&A,&K,&Qx,&Qy);
    ECP2_ZZZ_frob(&K,&X);
    ECP2_ZZZ_neg(&K);
    PAIR_ZZZ_line(&lv2,&A,&K,&Qx,&Qy);
    FP12_YYY_smul(&lv,&lv2);
    FP12_YYY_ssmul(r,&lv);

    ECP2_ZZZ_copy(&K,&R);
    ECP2_ZZZ_frob(&K,&X);
    PAIR_ZZZ_line(&lv,&B,&K,&Sx,&Sy);
    ECP2_ZZZ_frob(&K,&X);
    ECP2_ZZZ_neg(&K);
    PAIR_ZZZ_line(&lv2,&B,&K,&Sx,&Sy);
    FP12_YYY_smul(&lv,&lv2);
    FP12_YYY_ssmul(r,&lv);
#endif
}

/* final exponentiation - keep separate for multi-pairings and to avoid thrashing stack */
void PAIR_ZZZ_fexp(FP12_YYY *r)
{
    FP2_YYY X;
    BIG_XXX x;
    FP_YYY a,b;
    FP12_YYY t0,y0,y1,y2,y3;

    BIG_XXX_rcopy(x,CURVE_Bnx_ZZZ);
    FP_YYY_rcopy(&a,Fra_YYY);
    FP_YYY_rcopy(&b,Frb_YYY);
    FP2_YYY_from_FPs(&X,&a,&b);

    /* Easy part of final exp */

    FP12_YYY_inv(&t0,r);
    FP12_YYY_conj(r,r);

    FP12_YYY_mul(r,&t0);
    FP12_YYY_copy(&t0,r);

    FP12_YYY_frob(r,&X);
    FP12_YYY_frob(r,&X);
    FP12_YYY_mul(r,&t0);

//    if (FP12_YYY_isunity(r))
//    {
//        FP12_YYY_zero(r);
//        return;
//    }

    /* Hard part of final exp - see Duquesne & Ghamman eprint 2015/192.pdf */
#if PAIRING_FRIENDLY_ZZZ==BN
    FP12_YYY_pow(&t0,r,x); // t0=f^-u
#if SIGN_OF_X_ZZZ==POSITIVEX
    FP12_YYY_conj(&t0,&t0);
#endif
    FP12_YYY_usqr(&y3,&t0); // y3=t0^2
    FP12_YYY_copy(&y0,&t0);
    FP12_YYY_mul(&y0,&y3); // y0=t0*y3
    FP12_YYY_copy(&y2,&y3);
    FP12_YYY_frob(&y2,&X); // y2=y3^p
    FP12_YYY_mul(&y2,&y3); //y2=y2*y3
    FP12_YYY_usqr(&y2,&y2); //y2=y2^2
    FP12_YYY_mul(&y2,&y3); // y2=y2*y3

    FP12_YYY_pow(&t0,&y0,x);  //t0=y0^-u
#if SIGN_OF_X_ZZZ==POSITIVEX
    FP12_YYY_conj(&t0,&t0);
#endif
    FP12_YYY_conj(&y0,r);     //y0=~r
    FP12_YYY_copy(&y1,&t0);
    FP12_YYY_frob(&y1,&X);
    FP12_YYY_frob(&y1,&X); //y1=t0^p^2
    FP12_YYY_mul(&y1,&y0); // y1=y0*y1
    FP12_YYY_conj(&t0,&t0); // t0=~t0
    FP12_YYY_copy(&y3,&t0);
    FP12_YYY_frob(&y3,&X); //y3=t0^p
    FP12_YYY_mul(&y3,&t0); // y3=t0*y3
    FP12_YYY_usqr(&t0,&t0); // t0=t0^2
    FP12_YYY_mul(&y1,&t0); // y1=t0*y1

    FP12_YYY_pow(&t0,&y3,x); // t0=y3^-u
#if SIGN_OF_X_ZZZ==POSITIVEX
    FP12_YYY_conj(&t0,&t0);
#endif
    FP12_YYY_usqr(&t0,&t0); //t0=t0^2
    FP12_YYY_conj(&t0,&t0); //t0=~t0
    FP12_YYY_mul(&y3,&t0); // y3=t0*y3

    FP12_YYY_frob(r,&X);
    FP12_YYY_copy(&y0,r);
    FP12_YYY_frob(r,&X);
    FP12_YYY_mul(&y0,r);
    FP12_YYY_frob(r,&X);
    FP12_YYY_mul(&y0,r);

    FP12_YYY_usqr(r,&y3);  //r=y3^2
    FP12_YYY_mul(r,&y2);   //r=y2*r
    FP12_YYY_copy(&y3,r);
    FP12_YYY_mul(&y3,&y0); // y3=r*y0
    FP12_YYY_mul(r,&y1); // r=r*y1
    FP12_YYY_usqr(r,r); // r=r^2
    FP12_YYY_mul(r,&y3); // r=r*y3
    FP12_YYY_reduce(r);
#else
// Ghamman & Fouotsa Method

    FP12_YYY_usqr(&y0,r);
    FP12_YYY_pow(&y1,&y0,x);
#if SIGN_OF_X_ZZZ==NEGATIVEX
    FP12_YYY_conj(&y1,&y1);
#endif


    BIG_XXX_fshr(x,1);
    FP12_YYY_pow(&y2,&y1,x);
#if SIGN_OF_X_ZZZ==NEGATIVEX
    FP12_YYY_conj(&y2,&y2);
#endif


    BIG_XXX_fshl(x,1); // x must be even
    FP12_YYY_conj(&y3,r);
    FP12_YYY_mul(&y1,&y3);

    FP12_YYY_conj(&y1,&y1);
    FP12_YYY_mul(&y1,&y2);

    FP12_YYY_pow(&y2,&y1,x);
#if SIGN_OF_X_ZZZ==NEGATIVEX
    FP12_YYY_conj(&y2,&y2);
#endif

    FP12_YYY_pow(&y3,&y2,x);
#if SIGN_OF_X_ZZZ==NEGATIVEX
    FP12_YYY_conj(&y3,&y3);
#endif
    FP12_YYY_conj(&y1,&y1);
    FP12_YYY_mul(&y3,&y1);

    FP12_YYY_conj(&y1,&y1);
    FP12_YYY_frob(&y1,&X);
    FP12_YYY_frob(&y1,&X);
    FP12_YYY_frob(&y1,&X);
    FP12_YYY_frob(&y2,&X);
    FP12_YYY_frob(&y2,&X);
    FP12_YYY_mul(&y1,&y2);

    FP12_YYY_pow(&y2,&y3,x);
#if SIGN_OF_X_ZZZ==NEGATIVEX
    FP12_YYY_conj(&y2,&y2);
#endif
    FP12_YYY_mul(&y2,&y0);
    FP12_YYY_mul(&y2,r);

    FP12_YYY_mul(&y1,&y2);
    FP12_YYY_copy(&y2,&y3);
    FP12_YYY_frob(&y2,&X);
    FP12_YYY_mul(&y1,&y2);
    FP12_YYY_copy(r,&y1);
    FP12_YYY_reduce(r);

#endif
}

#ifdef USE_GLV_ZZZ
/* GLV method */
static void glv(BIG_XXX u[2],BIG_XXX e)
{
#if PAIRING_FRIENDLY_ZZZ==BN
    int i,j;
    BIG_XXX v[2],t,q;
    DBIG_XXX d;
    BIG_XXX_rcopy(q,CURVE_Order_ZZZ);
    for (i=0; i<2; i++)
    {
        BIG_XXX_rcopy(t,CURVE_W_ZZZ[i]);
        BIG_XXX_mul(d,t,e);
        BIG_XXX_ddiv(v[i],d,q);
        BIG_XXX_zero(u[i]);
    }
    BIG_XXX_copy(u[0],e);
    for (i=0; i<2; i++)
        for (j=0; j<2; j++)
        {
            BIG_XXX_rcopy(t,CURVE_SB_ZZZ[j][i]);
            BIG_XXX_modmul(t,v[j],t,q);
            BIG_XXX_add(u[i],u[i],q);
            BIG_XXX_sub(u[i],u[i],t);
            BIG_XXX_mod(u[i],q);
        }

#else
// -(x^2).P = (Beta.x,y)

    BIG_XXX x,x2,q;
    BIG_XXX_rcopy(x,CURVE_Bnx_ZZZ);
    BIG_XXX_smul(x2,x,x);
    BIG_XXX_copy(u[0],e);
    BIG_XXX_mod(u[0],x2);
    BIG_XXX_copy(u[1],e);
    BIG_XXX_sdiv(u[1],x2);

    BIG_XXX_rcopy(q,CURVE_Order_ZZZ);
    BIG_XXX_sub(u[1],q,u[1]);

#endif

    return;
}
#endif // USE_GLV

/* Galbraith & Scott Method */
static void gs(BIG_XXX u[4],BIG_XXX e)
{
    int i;
#if PAIRING_FRIENDLY_ZZZ==BN
    int j;
    BIG_XXX v[4],t,q;
    DBIG_XXX d;
    BIG_XXX_rcopy(q,CURVE_Order_ZZZ);
    for (i=0; i<4; i++)
    {
        BIG_XXX_rcopy(t,CURVE_WB_ZZZ[i]);
        BIG_XXX_mul(d,t,e);
        BIG_XXX_ddiv(v[i],d,q);
        BIG_XXX_zero(u[i]);
    }

    BIG_XXX_copy(u[0],e);
    for (i=0; i<4; i++)
        for (j=0; j<4; j++)
        {
            BIG_XXX_rcopy(t,CURVE_BB_ZZZ[j][i]);
            BIG_XXX_modmul(t,v[j],t,q);
            BIG_XXX_add(u[i],u[i],q);
            BIG_XXX_sub(u[i],u[i],t);
            BIG_XXX_mod(u[i],q);
        }

#else

    BIG_XXX x,w,q;
    BIG_XXX_rcopy(q,CURVE_Order_ZZZ);
    BIG_XXX_rcopy(x,CURVE_Bnx_ZZZ);
    BIG_XXX_copy(w,e);

    for (i=0; i<3; i++)
    {
        BIG_XXX_copy(u[i],w);
        BIG_XXX_mod(u[i],x);
        BIG_XXX_sdiv(w,x);
    }
    BIG_XXX_copy(u[3],w);

    /*  */
#if SIGN_OF_X_ZZZ==NEGATIVEX
    BIG_XXX_modneg(u[1],u[1],q);
    BIG_XXX_modneg(u[3],u[3],q);
#endif

#endif



    return;
}

/* Multiply P by e in group G1 */
void PAIR_ZZZ_G1mul(ECP_ZZZ *P,BIG_XXX e)
{
#ifdef USE_GLV_ZZZ   /* Note this method is patented */
    int np,nn;
    ECP_ZZZ Q;
    FP_YYY cru;
    BIG_XXX t,q;
    BIG_XXX u[2];

    BIG_XXX_rcopy(q,CURVE_Order_ZZZ);
    glv(u,e);

    ECP_ZZZ_copy(&Q,P);
    ECP_ZZZ_affine(&Q);
    FP_YYY_rcopy(&cru,CURVE_Cru_ZZZ);
    FP_YYY_mul(&(Q.x),&(Q.x),&cru);

    /* note that -a.B = a.(-B). Use a or -a depending on which is smaller */

    np=BIG_XXX_nbits(u[0]);
    BIG_XXX_modneg(t,u[0],q);
    nn=BIG_XXX_nbits(t);
    if (nn<np)
    {
        BIG_XXX_copy(u[0],t);
        ECP_ZZZ_neg(P);
    }

    np=BIG_XXX_nbits(u[1]);
    BIG_XXX_modneg(t,u[1],q);
    nn=BIG_XXX_nbits(t);
    if (nn<np)
    {
        BIG_XXX_copy(u[1],t);
        ECP_ZZZ_neg(&Q);
    }
    BIG_XXX_norm(u[0]);
    BIG_XXX_norm(u[1]);
    ECP_ZZZ_mul2(P,&Q,u[0],u[1]);

#else
    ECP_ZZZ_mul(P,e);
#endif
}

/* Multiply P by e in group G2 */
void PAIR_ZZZ_G2mul(ECP2_ZZZ *P,BIG_XXX e)
{
#ifdef USE_GS_G2_ZZZ   /* Well I didn't patent it :) */
    int i,np,nn;
    ECP2_ZZZ Q[4];
    FP2_YYY X;
    FP_YYY fx,fy;
    BIG_XXX x,y,u[4];

    FP_YYY_rcopy(&fx,Fra_YYY);
    FP_YYY_rcopy(&fy,Frb_YYY);
    FP2_YYY_from_FPs(&X,&fx,&fy);

#if SEXTIC_TWIST_ZZZ==M_TYPE
    FP2_YYY_inv(&X,&X);
    FP2_YYY_norm(&X);
#endif

    BIG_XXX_rcopy(y,CURVE_Order_ZZZ);
    gs(u,e);

    ECP2_ZZZ_copy(&Q[0],P);
    for (i=1; i<4; i++)
    {
        ECP2_ZZZ_copy(&Q[i],&Q[i-1]);
        ECP2_ZZZ_frob(&Q[i],&X);
    }

    for (i=0; i<4; i++)
    {
        np=BIG_XXX_nbits(u[i]);
        BIG_XXX_modneg(x,u[i],y);
        nn=BIG_XXX_nbits(x);
        if (nn<np)
        {
            BIG_XXX_copy(u[i],x);
            ECP2_ZZZ_neg(&Q[i]);
        }
        BIG_XXX_norm(u[i]);
    }

    ECP2_ZZZ_mul4(P,Q,u);

#else
    ECP2_ZZZ_mul(P,e);
#endif
}

/* f=f^e */
void PAIR_ZZZ_GTpow(FP12_YYY *f,BIG_XXX e)
{
#ifdef USE_GS_GT_ZZZ   /* Note that this option requires a lot of RAM! Maybe better to use compressed XTR method, see fp4.c */
    int i,np,nn;
    FP12_YYY g[4];
    FP2_YYY X;
    BIG_XXX t,q;
    FP_YYY fx,fy;
    BIG_XXX u[4];

    FP_YYY_rcopy(&fx,Fra_YYY);
    FP_YYY_rcopy(&fy,Frb_YYY);
    FP2_YYY_from_FPs(&X,&fx,&fy);

    BIG_XXX_rcopy(q,CURVE_Order_ZZZ);
    gs(u,e);

    FP12_YYY_copy(&g[0],f);
    for (i=1; i<4; i++)
    {
        FP12_YYY_copy(&g[i],&g[i-1]);
        FP12_YYY_frob(&g[i],&X);
    }

    for (i=0; i<4; i++)
    {
        np=BIG_XXX_nbits(u[i]);
        BIG_XXX_modneg(t,u[i],q);
        nn=BIG_XXX_nbits(t);
        if (nn<np)
        {
            BIG_XXX_copy(u[i],t);
            FP12_YYY_conj(&g[i],&g[i]);
        }
        BIG_XXX_norm(u[i]);
    }
    FP12_YYY_pow4(f,g,u);

#else
    FP12_YYY_pow(f,f,e);
#endif
}


#ifdef HAS_MAIN

int main()
{
    int i;
    char byt[32];
    csprng rng;
    BIG_XXX xa,xb,ya,yb,w,a,b,t1,q,u[2],v[4],m,r;
    ECP2_ZZZ P,G;
    ECP_ZZZ Q,R;
    FP12_YYY g,gp;
    FP4_YYY t,c,cp,cpm1,cpm2;
    FP2_YYY x,y,X;


    BIG_XXX_rcopy(a,CURVE_Fra);
    BIG_XXX_rcopy(b,CURVE_Frb);
    FP2_YYY_from_BIGs(&X,a,b);

    BIG_XXX_rcopy(xa,CURVE_Gx);
    BIG_XXX_rcopy(ya,CURVE_Gy);

    ECP_ZZZ_set(&Q,xa,ya);
    if (Q.inf) printf("Failed to set - point not on curve\n");
    else printf("G1 set success\n");

    printf("Q= ");
    ECP_ZZZ_output(&Q);
    printf("\n");

    BIG_XXX_rcopy(xa,CURVE_Pxa);
    BIG_XXX_rcopy(xb,CURVE_Pxb);
    BIG_XXX_rcopy(ya,CURVE_Pya);
    BIG_XXX_rcopy(yb,CURVE_Pyb);

    FP2_YYY_from_BIGs(&x,xa,xb);
    FP2_YYY_from_BIGs(&y,ya,yb);

    ECP2_ZZZ_set(&P,&x,&y);
    if (P.inf) printf("Failed to set - point not on curve\n");
    else printf("G2 set success\n");

    printf("P= ");
    ECP2_ZZZ_output(&P);
    printf("\n");

    for (i=0; i<1000; i++ )
    {
        PAIR_ZZZ_ate(&g,&P,&Q);
        PAIR_ZZZ_fexp(&g);
    }
    printf("g= ");
    FP12_YYY_output(&g);
    printf("\n");
}

#endif
