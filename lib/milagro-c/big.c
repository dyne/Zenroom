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

/* AMCL basic functions for BIG type */
/* SU=m, SU is Stack Usage */

#include "amcl.h"

/* Calculates x*y+c+*r */

#ifdef dchunk

/* Method required to calculate x*y+c+r, bottom half in r, top half returned */
chunk muladd(chunk x,chunk y,chunk c,chunk *r)
{
	dchunk prod=(dchunk)x*y+c+*r;
	*r=(chunk)prod&MASK;
	return (chunk)(prod>>BASEBITS);
}

#else

/* No integer type available that can store double the wordlength */
/* accumulate partial products */

chunk muladd(chunk x,chunk y,chunk c,chunk *r)
{
	chunk x0,x1,y0,y1;
	chunk bot,top,mid,carry;
	x0=x&HMASK;
	x1=(x>>HBITS);
	y0=y&HMASK;
	y1=(y>>HBITS);
	bot=x0*y0;
	top=x1*y1;
	mid=x0*y1+x1*y0;
	x0=mid&HMASK1;
	x1=(mid>>HBITS1);
	bot+=x0<<HBITS; bot+=*r; bot+=c;

#if HDIFF==1
	bot+=(top&HDIFF)<<(BASEBITS-1);
	top>>=HDIFF;
#endif

	top+=x1;
	carry=bot>>BASEBITS;
	bot&=MASK;
	top+=carry;

	*r=bot;
	return top;
}

#endif

/* test a=0? */
int BIG_iszilch(BIG a)
{
	int i;
	for (i=0;i<NLEN;i++)
		if (a[i]!=0) return 0;
	return 1;
}

/* test a=0? */
int BIG_diszilch(DBIG a)
{
	int i;
	for (i=0;i<DNLEN;i++)
		if (a[i]!=0) return 0;
	return 1;
}

/* SU= 56 */
/* output a */
void BIG_output(BIG a)
{
	BIG b;
	int i,len;
	len=BIG_nbits(a);
	if (len%4==0) len/=4;
	else {len/=4; len++;}
	if (len<MODBYTES*2) len=MODBYTES*2;

	for (i=len-1;i>=0;i--)
	{
		BIG_copy(b,a);
		BIG_shr(b,i*4);
		printf("%01x",(unsigned int) b[0]&15);
	}
}

/* SU= 16 */
void BIG_rawoutput(BIG a)
{
	int i;
	printf("(");
	for (i=0;i<NLEN-1;i++)
	  printf("%llx,",(long long unsigned int) a[i]);
	printf("%llx)",(long long unsigned int) a[NLEN-1]);
}

/* Swap a and b if d=1 */
void BIG_cswap(BIG a,BIG b,int d)
{
	int i;
	chunk t,c=d;
	c=~(c-1);
#ifdef DEBUG_NORM
	for (i=0;i<=NLEN;i++)
#else
	for (i=0;i<NLEN;i++)
#endif
	{
		t=c&(a[i]^b[i]);
		a[i]^=t;
		b[i]^=t;
	}
}

/* Move b to a if d=1 */
void BIG_cmove(BIG f,BIG g,int d)
{
	int i;
	chunk b=(chunk)-d;
#ifdef DEBUG_NORM
	for (i=0;i<=NLEN;i++)
#else
	for (i=0;i<NLEN;i++)
#endif
	{
		f[i]^=(f[i]^g[i])&b;
	}
}

/* convert BIG to/from bytes */
/* SU= 64 */
void BIG_toBytes(char *b,BIG a)
{
	int i;
	BIG c;
	BIG_norm(a);
	BIG_copy(c,a);
	for (i=MODBYTES-1;i>=0;i--)
	{
		b[i]=c[0]&0xff;
		BIG_fshr(c,8);
	}
}

/* SU= 16 */
void BIG_fromBytes(BIG a,char *b)
{
	int i;
	BIG_zero(a);
	for (i=0;i<MODBYTES;i++)
	{
		BIG_fshl(a,8); a[0]+=(int)(unsigned char)b[i];
		//BIG_inc(a,(int)(unsigned char)b[i]); BIG_norm(a);
	}
#ifdef DEBUG_NORM
	a[NLEN]=0;
#endif
}

/* SU= 88 */
void BIG_doutput(DBIG a)
{
	DBIG b;
	int i,len;
	BIG_dnorm(a);
	len=BIG_dnbits(a);
	if (len%4==0) len/=4;
	else {len/=4; len++;}

	for (i=len-1;i>=0;i--)
	{
		BIG_dcopy(b,a);
		BIG_dshr(b,i*4);
		printf("%01x",(unsigned int) b[0]&15);
	}
}

/* Copy b=a */
void BIG_copy(BIG b,BIG a)
{
	int i;
	for (i=0;i<NLEN;i++)
		b[i]=a[i];
#ifdef DEBUG_NORM
	b[NLEN]=a[NLEN];
#endif
}

/* Copy from ROM b=a */
void BIG_rcopy(BIG b,const BIG a)
{
	int i;
	for (i=0;i<NLEN;i++)
		b[i]=a[i];
#ifdef DEBUG_NORM
	b[NLEN]=0;
#endif
}

/* double length DBIG copy b=a */
void BIG_dcopy(DBIG b,DBIG a)
{
	int i;
	for (i=0;i<DNLEN;i++)
		b[i]=a[i];
#ifdef DEBUG_NORM
	b[DNLEN]=a[DNLEN];
#endif
}

/* Copy BIG to bottom half of DBIG */
void BIG_dscopy(DBIG b,BIG a)
{
	int i;
	for (i=0;i<NLEN-1;i++)
		b[i]=a[i];

	b[NLEN-1]=a[NLEN-1]&MASK; /* top word normalized */
	b[NLEN]=a[NLEN-1]>>BASEBITS;

	for (i=NLEN+1;i<DNLEN;i++) b[i]=0;
#ifdef DEBUG_NORM
	b[DNLEN]=a[NLEN];
#endif
}

/* Copy BIG to top half of DBIG */
void BIG_dsucopy(DBIG b,BIG a)
{
	int i;
	for (i=0;i<NLEN;i++)
		b[i]=0;
	for (i=NLEN;i<DNLEN;i++)
		b[i]=a[i-NLEN];
#ifdef DEBUG_NORM
	b[DNLEN]=a[NLEN];
#endif
}

/* Copy bottom half of DBIG to BIG */
void BIG_sdcopy(BIG b,DBIG a)
{
	int i;
	for (i=0;i<NLEN;i++)
		b[i]=a[i];
#ifdef DEBUG_NORM
	b[NLEN]=a[DNLEN];
#endif
}

/* Copy top half of DBIG to BIG */
void BIG_sducopy(BIG b,DBIG a)
{
	int i;
	for (i=0;i<NLEN;i++)
		b[i]=a[i+NLEN];
#ifdef DEBUG_NORM
	b[NLEN]=a[DNLEN];
#endif
}

/* Set a=0 */
void BIG_zero(BIG a)
{
	int i;
	for (i=0;i<NLEN;i++)
		a[i]=0;
#ifdef DEBUG_NORM
	a[NLEN]=0;
#endif
}

void BIG_dzero(DBIG a)
{
	int i;
	for (i=0;i<DNLEN;i++)
		a[i]=0;
#ifdef DEBUG_NORM
	a[DNLEN]=0;
#endif
}

/* set a=1 */
void BIG_one(BIG a)
{
	int i;
	a[0]=1;
	for (i=1;i<NLEN;i++)
		a[i]=0;
#ifdef DEBUG_NORM
	a[NLEN]=0;
#endif
}



/* Set c=a+b */
/* SU= 8 */
void BIG_add(BIG c,BIG a,BIG b)
{
	int i;
	for (i=0;i<NLEN;i++)
		c[i]=a[i]+b[i];
#ifdef DEBUG_NORM
	c[NLEN]=a[NLEN]+b[NLEN]+1;
	if (c[NLEN]>=NEXCESS) printf("add problem - digit overflow %d\n",c[NLEN]);
#endif
}

/* Set c=c+d */
void BIG_inc(BIG c,int d)
{
	BIG_norm(c);
	c[0]+=(chunk)d;
#ifdef DEBUG_NORM
	c[NLEN]=1;
#endif
}

/* Set c=a-b */
/* SU= 8 */
void BIG_sub(BIG c,BIG a,BIG b)
{
	int i;
	for (i=0;i<NLEN;i++)
		c[i]=a[i]-b[i];
#ifdef DEBUG_NORM
	c[NLEN]=a[NLEN]+b[NLEN]+1;
	if (c[NLEN]>=NEXCESS) printf("sub problem - digit overflow %d\n",c[NLEN]);
#endif
}

/* SU= 8 */

void BIG_dsub(DBIG c,DBIG a,DBIG b)
{
	int i;
	for (i=0;i<DNLEN;i++)
		c[i]=a[i]-b[i];
#ifdef DEBUG_NORM
	c[DNLEN]=a[DNLEN]+b[DNLEN]+1;
	if (c[DNLEN]>=NEXCESS) printf("sub problem - digit overflow %d\n",c[DNLEN]);
#endif
}


/* Set c=c-1 */
void BIG_dec(BIG c,int d)
{
	BIG_norm(c);
	c[0]-=(chunk)d;
#ifdef DEBUG_NORM
	c[NLEN]=1;
#endif
}

/* multiplication r=a*c by c<=NEXCESS */
void BIG_imul(BIG r,BIG a,int c)
{
	int i;
	for (i=0;i<NLEN;i++) r[i]=a[i]*c;
#ifdef DEBUG_NORM
	r[NLEN]=(a[NLEN]+1)*c-1;
	if (r[NLEN]>=NEXCESS) printf("int mul problem - digit overflow %d\n",r[NLEN]);
#endif
}

/* multiplication r=a*c by larger integer - c<=FEXCESS */
/* SU= 24 */
chunk BIG_pmul(BIG r,BIG a,int c)
{
	int i;
	chunk ak,carry=0;
	BIG_norm(a);
	for (i=0;i<NLEN;i++)
	{
		ak=a[i];
		r[i]=0;
		carry=muladd(ak,(chunk)c,carry,&r[i]);
	}
#ifdef DEBUG_NORM
	r[NLEN]=0;
#endif
	return carry;
}

/* r/=3 */
/* SU= 16 */
int BIG_div3(BIG r)
{
	int i;
	chunk ak,base,carry=0;
	BIG_norm(r);
	base=((chunk)1<<BASEBITS);
	for (i=NLEN-1;i>=0;i--)
	{
		ak=(carry*base+r[i]);
		r[i]=ak/3;
		carry=ak%3;
	}
	return (int)carry;
}

/* multiplication c=a*b by even larger integer b>FEXCESS, resulting in DBIG */
/* SU= 24 */
void BIG_pxmul(DBIG c,BIG a,int b)
{
	int j;
	chunk carry;
	BIG_dzero(c);
	carry=0;
	for (j=0;j<NLEN;j++)
		carry=muladd(a[j],(chunk)b,carry,&c[j]);
	c[NLEN]=carry;
#ifdef DEBUG_NORM
	c[DNLEN]=0;
#endif
}

/* Set c=a*b */
/* SU= 72 */
void BIG_mul(DBIG c,BIG a,BIG b)
{
	int i,j;
	chunk carry;
#ifdef dchunk
	dchunk t,co;
#endif

	BIG_norm(a);  /* needed here to prevent overflow from addition of partial products */
	BIG_norm(b);

/* Faster to Combafy it.. Let the compiler unroll the loops! */

#ifdef COMBA

	t=(dchunk)a[0]*b[0];
	c[0]=(chunk)t&MASK; co=t>>BASEBITS;
	t=(dchunk)a[1]*b[0]+(dchunk)a[0]*b[1]+co;
	c[1]=(chunk)t&MASK; co=t>>BASEBITS;

	for (j=2;j<NLEN;j++)
	{
		t=co; for (i=0;i<=j;i++) t+=(dchunk)a[j-i]*b[i];
		c[j]=(chunk)t&MASK; co=t>>BASEBITS;
	}

	for (j=NLEN;j<DNLEN-2;j++)
	{
		t=co; for (i=j-NLEN+1;i<NLEN;i++) t+=(dchunk)a[j-i]*b[i];
		c[j]=(chunk)t&MASK; co=t>>BASEBITS;
	}

	t=(dchunk)a[NLEN-1]*b[NLEN-1]+co;
	c[DNLEN-2]=(chunk)t&MASK; co=t>>BASEBITS;
	c[DNLEN-1]=(chunk)co;
#else
	BIG_dzero(c);
	for (i=0;i<NLEN;i++)
	{
		carry=0;
		for (j=0;j<NLEN;j++)
			carry=muladd(a[i],b[j],carry,&c[i+j]);
        c[NLEN+i]=carry;
	}
#endif

#ifdef DEBUG_NORM
	c[DNLEN]=0;
#endif
}

/* .. if you know the result will fit in a BIG, c must be distinct from a and b */
/* SU= 40 */
void BIG_smul(BIG c,BIG a,BIG b)
{
	int i,j;
	chunk carry;
	BIG_norm(a);
	BIG_norm(b);

	BIG_zero(c);
	for (i=0;i<NLEN;i++)
	{
		carry=0;
		for (j=0;j<NLEN;j++)
			if (i+j<NLEN) carry=muladd(a[i],b[j],carry,&c[i+j]);
	}
#ifdef DEBUG_NORM
	c[NLEN]=0;
#endif

}

/* Set c=a*a */
/* SU= 80 */
void BIG_sqr(DBIG c,BIG a)
{
	int i,j;
	chunk carry;
#ifdef dchunk
	dchunk t,co;
#endif

	BIG_norm(a);

/* Note 2*a[i] in loop below and extra addition */

#ifdef COMBA

	t=(dchunk)a[0]*a[0];
	c[0]=(chunk)t&MASK; co=t>>BASEBITS;
	t=(dchunk)a[1]*a[0]; t+=t; t+=co;
	c[1]=(chunk)t&MASK; co=t>>BASEBITS;

#if NLEN%2==1
	for (j=2;j<NLEN-1;j+=2)
	{
		t=(dchunk)a[j]*a[0]; for (i=1;i<(j+1)/2;i++) t+=(dchunk)a[j-i]*a[i]; t+=t; t+=co;  t+=(dchunk)a[j/2]*a[j/2];
		c[j]=(chunk)t&MASK; co=t>>BASEBITS;
		t=(dchunk)a[j+1]*a[0]; for (i=1;i<(j+2)/2;i++) t+=(dchunk)a[j+1-i]*a[i]; t+=t; t+=co;
		c[j+1]=(chunk)t&MASK; co=t>>BASEBITS;
	}
	j=NLEN-1;
	t=(dchunk)a[j]*a[0]; for (i=1;i<(j+1)/2;i++) t+=(dchunk)a[j-i]*a[i]; t+=t; t+=co;  t+=(dchunk)a[j/2]*a[j/2];
	c[j]=(chunk)t&MASK; co=t>>BASEBITS;

#else
	for (j=2;j<NLEN;j+=2)
	{
		t=(dchunk)a[j]*a[0]; for (i=1;i<(j+1)/2;i++) t+=(dchunk)a[j-i]*a[i]; t+=t; t+=co;  t+=(dchunk)a[j/2]*a[j/2];
		c[j]=(chunk)t&MASK; co=t>>BASEBITS;
		t=(dchunk)a[j+1]*a[0]; for (i=1;i<(j+2)/2;i++) t+=(dchunk)a[j+1-i]*a[i]; t+=t; t+=co;
		c[j+1]=(chunk)t&MASK; co=t>>BASEBITS;
	}

#endif

#if NLEN%2==1
	j=NLEN;
	t=(dchunk)a[NLEN-1]*a[j-NLEN+1]; for (i=j-NLEN+2;i<(j+1)/2;i++) t+=(dchunk)a[j-i]*a[i]; t+=t; t+=co;
	c[j]=(chunk)t&MASK; co=t>>BASEBITS;
	for (j=NLEN+1;j<DNLEN-2;j+=2)
	{
		t=(dchunk)a[NLEN-1]*a[j-NLEN+1]; for (i=j-NLEN+2;i<(j+1)/2;i++) t+=(dchunk)a[j-i]*a[i]; t+=t; t+=co; t+=(dchunk)a[j/2]*a[j/2];
		c[j]=(chunk)t&MASK; co=t>>BASEBITS;
		t=(dchunk)a[NLEN-1]*a[j-NLEN+2]; for (i=j-NLEN+3;i<(j+2)/2;i++) t+=(dchunk)a[j+1-i]*a[i]; t+=t; t+=co;
		c[j+1]=(chunk)t&MASK; co=t>>BASEBITS;
	}
#else
	for (j=NLEN;j<DNLEN-2;j+=2)
	{
		t=(dchunk)a[NLEN-1]*a[j-NLEN+1]; for (i=j-NLEN+2;i<(j+1)/2;i++) t+=(dchunk)a[j-i]*a[i]; t+=t; t+=co; t+=(dchunk)a[j/2]*a[j/2];
		c[j]=(chunk)t&MASK; co=t>>BASEBITS;
		t=(dchunk)a[NLEN-1]*a[j-NLEN+2]; for (i=j-NLEN+3;i<(j+2)/2;i++) t+=(dchunk)a[j+1-i]*a[i]; t+=t; t+=co;
		c[j+1]=(chunk)t&MASK; co=t>>BASEBITS;
	}

#endif

	t=(dchunk)a[NLEN-1]*a[NLEN-1]+co;
	c[DNLEN-2]=(chunk)t&MASK; co=t>>BASEBITS;
	c[DNLEN-1]=(chunk)co;

#else
	BIG_dzero(c);
	for (i=0;i<NLEN;i++)
	{
		carry=0;
		for (j=i+1;j<NLEN;j++)
			carry=muladd(a[i],a[j],carry,&c[i+j]);
        c[NLEN+i]=carry;
	}

	for (i=0;i<DNLEN;i++) c[i]*=2;

	for (i=0;i<NLEN;i++)
		c[2*i+1]+=muladd(a[i],a[i],0,&c[2*i]);

	BIG_dnorm(c);
#endif


#ifdef DEBUG_NORM
	c[DNLEN]=0;
#endif

}

/* General shift left of a by n bits */
/* a MUST be normalised */
/* SU= 32 */
void BIG_shl(BIG a,int k)
{
	int i;
	int n=k%BASEBITS;
	int m=k/BASEBITS;

	a[NLEN-1]=((a[NLEN-1-m]<<n))|(a[NLEN-m-2]>>(BASEBITS-n));

	for (i=NLEN-2;i>m;i--)
		a[i]=((a[i-m]<<n)&MASK)|(a[i-m-1]>>(BASEBITS-n));
	a[m]=(a[0]<<n)&MASK;
	for (i=0;i<m;i++) a[i]=0;

}

/* Fast shift left of a by n bits, where n less than a word, Return excess (but store it as well) */
/* a MUST be normalised */
/* SU= 16 */
chunk BIG_fshl(BIG a,int n)
{
	int i;

	a[NLEN-1]=((a[NLEN-1]<<n))|(a[NLEN-2]>>(BASEBITS-n)); /* top word not masked */
	for (i=NLEN-2;i>0;i--)
		a[i]=((a[i]<<n)&MASK)|(a[i-1]>>(BASEBITS-n));
	a[0]=(a[0]<<n)&MASK;

	return (a[NLEN-1]>>((8*MODBYTES)%BASEBITS)); /* return excess - only used in ff.c */
}

/* double length left shift of a by k bits - k can be > BASEBITS , a MUST be normalised */
/* SU= 32 */
void BIG_dshl(DBIG a,int k)
{
	int i;
	int n=k%BASEBITS;
	int m=k/BASEBITS;

	a[DNLEN-1]=((a[DNLEN-1-m]<<n))|(a[DNLEN-m-2]>>(BASEBITS-n));

	for (i=DNLEN-2;i>m;i--)
		a[i]=((a[i-m]<<n)&MASK)|(a[i-m-1]>>(BASEBITS-n));
	a[m]=(a[0]<<n)&MASK;
	for (i=0;i<m;i++) a[i]=0;

}

/* General shift rightof a by k bits */
/* a MUST be normalised */
/* SU= 32 */
void BIG_shr(BIG a,int k)
{
	int i;
	int n=k%BASEBITS;
	int m=k/BASEBITS;
	for (i=0;i<NLEN-m-1;i++)
		a[i]=(a[m+i]>>n)|((a[m+i+1]<<(BASEBITS-n))&MASK);
	a[NLEN-m-1]=a[NLEN-1]>>n;
	for (i=NLEN-m;i<NLEN;i++) a[i]=0;

}

/* Faster shift right of a by k bits. Return shifted out part */
/* a MUST be normalised */
/* SU= 16 */
chunk BIG_fshr(BIG a,int k)
{
	int i;
	chunk r=a[0]&(((chunk)1<<k)-1); /* shifted out part */
	for (i=0;i<NLEN-1;i++)
		a[i]=(a[i]>>k)|((a[i+1]<<(BASEBITS-k))&MASK);
	a[NLEN-1]=a[NLEN-1]>>k;
	return r;
}

/* double length right shift of a by k bits - can be > BASEBITS */
/* SU= 32 */
void BIG_dshr(DBIG a,int k)
{
	int i;
	int n=k%BASEBITS;
	int m=k/BASEBITS;
	for (i=0;i<DNLEN-m-1;i++)
		a[i]=(a[m+i]>>n)|((a[m+i+1]<<(BASEBITS-n))&MASK);
	a[DNLEN-m-1]=a[DNLEN-1]>>n;
	for (i=DNLEN-m;i<DNLEN;i++ ) a[i]=0;
}

/* Split DBIG d into two BIGs t|b. Split happens at n bits, where n falls into NLEN word */
/* d MUST be normalised */
/* SU= 24 */
void BIG_split(BIG t,BIG b,DBIG d,int n)
{
	int i;
	chunk nw,carry;
	int m=n%BASEBITS;
//	BIG_dnorm(d);

	for (i=0;i<NLEN-1;i++) b[i]=d[i];

	b[NLEN-1]=d[NLEN-1]&(((chunk)1<<m)-1);

	if (t!=b)
	{
		carry=(d[DNLEN-1]<<(BASEBITS-m));
		for (i=DNLEN-2;i>=NLEN-1;i--)
		{
			nw=(d[i]>>m)|carry;
			carry=(d[i]<<(BASEBITS-m))&MASK;
			t[i-NLEN+1]=nw;
		}
	}
#ifdef DEBUG_NORM
		t[NLEN]=0;
		b[NLEN]=0;
#endif

}

/* you gotta keep the sign of carry! Look - no branching! */
/* Note that sign bit is needed to disambiguate between +ve and -ve values */
/* normalise BIG - force all digits < 2^BASEBITS */
chunk BIG_norm(BIG a)
{
	int i;
	chunk d,carry=0;
	for (i=0;i<NLEN-1;i++)
	{
		d=a[i]+carry;
		a[i]=d&MASK;
		carry=d>>BASEBITS;
	}
	a[NLEN-1]=(a[NLEN-1]+carry);

#ifdef DEBUG_NORM
	a[NLEN]=0;
#endif
	return (a[NLEN-1]>>((8*MODBYTES)%BASEBITS));  /* only used in ff.c */
}

void BIG_dnorm(DBIG a)
{
	int i;
	chunk d,carry=0;;
	for (i=0;i<DNLEN-1;i++)
	{
		d=a[i]+carry;
		a[i]=d&MASK;
		carry=d>>BASEBITS;
	}
	a[DNLEN-1]=(a[DNLEN-1]+carry);
#ifdef DEBUG_NORM
	a[DNLEN]=0;
#endif
}

/* Compare a and b. Return 1 for a>b, -1 for a<b, 0 for a==b */
/* a and b MUST be normalised before call */
int BIG_comp(BIG a,BIG b)
{
	int i;
	for (i=NLEN-1;i>=0;i--)
	{
		if (a[i]==b[i]) continue;
		if (a[i]>b[i]) return 1;
		else  return -1;
	}
	return 0;
}

int BIG_dcomp(DBIG a,DBIG b)
{
	int i;
	for (i=DNLEN-1;i>=0;i--)
	{
		if (a[i]==b[i]) continue;
		if (a[i]>b[i]) return 1;
		else  return -1;
	}
	return 0;
}

/* return number of bits in a */
/* SU= 8 */
int BIG_nbits(BIG a)
{
	int bts,k=NLEN-1;
	chunk c;
	BIG_norm(a);
	while (k>=0 && a[k]==0) k--;
	if (k<0) return 0;
    bts=BASEBITS*k;
	c=a[k];
	while (c!=0) {c/=2; bts++;}
	return bts;
}

/* SU= 8 */
int BIG_dnbits(BIG a)
{
	int bts,k=DNLEN-1;
	chunk c;
	BIG_dnorm(a);
	while (a[k]==0 && k>=0) k--;
	if (k<0) return 0;
    bts=BASEBITS*k;
	c=a[k];
	while (c!=0) {c/=2; bts++;}
	return bts;
}


/* Set b=b mod c */
/* SU= 16 */
void BIG_mod(BIG b,BIG c)
{
	int k=0;

	BIG_norm(b);
	if (BIG_comp(b,c)<0)
		return;
	do
	{
		BIG_fshl(c,1);
		k++;
	} while (BIG_comp(b,c)>=0);

	while (k>0)
	{
		BIG_fshr(c,1);
		if (BIG_comp(b,c)>=0)
		{
			BIG_sub(b,b,c);
			BIG_norm(b);
		}
		k--;
	}
}

/* Set a=b mod c, b is destroyed. Slow but rarely used. */
/* SU= 96 */
void BIG_dmod(BIG a,DBIG b,BIG c)
{
	int k=0;
	DBIG m;
	BIG_dnorm(b);
	BIG_dscopy(m,c);

	if (BIG_dcomp(b,m)<0)
	{
		BIG_sdcopy(a,b);
		return;
	}

	do
	{
		BIG_dshl(m,1);
		k++;
	} while (BIG_dcomp(b,m)>=0);

	while (k>0)
	{
		BIG_dshr(m,1);
		if (BIG_dcomp(b,m)>=0)
		{
			BIG_dsub(b,b,m);
			BIG_dnorm(b);
		}
		k--;
	}
	BIG_sdcopy(a,b);
}

/* Set a=b/c,  b is destroyed. Slow but rarely used. */
/* SU= 136 */
void BIG_ddiv(BIG a,DBIG b,BIG c)
{
	int k=0;
	DBIG m;
	BIG e;
	BIG_dnorm(b);
	BIG_dscopy(m,c);

	BIG_zero(a);
	BIG_zero(e); BIG_inc(e,1);

	while (BIG_dcomp(b,m)>=0)
	{
		BIG_fshl(e,1);
		BIG_dshl(m,1);
		k++;
	}

	while (k>0)
	{
		BIG_dshr(m,1);
		BIG_fshr(e,1);
		if (BIG_dcomp(b,m)>=0)
		{
			BIG_add(a,a,e);
			BIG_norm(a);
			BIG_dsub(b,b,m);
			BIG_dnorm(b);
		}
		k--;
	}
}

/* SU= 136 */

void BIG_sdiv(BIG a,BIG c)
{
	int k=0;
	BIG m,e,b;
	BIG_norm(a);
	BIG_copy(b,a);
	BIG_copy(m,c);

	BIG_zero(a);
	BIG_zero(e); BIG_inc(e,1);

	while (BIG_comp(b,m)>=0)
	{
		BIG_fshl(e,1);
		BIG_fshl(m,1);
		k++;
	}

	while (k>0)
	{
		BIG_fshr(m,1);
		BIG_fshr(e,1);
		if (BIG_comp(b,m)>=0)
		{
			BIG_add(a,a,e);
			BIG_norm(a);
			BIG_sub(b,b,m);
			BIG_norm(b);
		}
		k--;
	}
}

/* return LSB of a */
int BIG_parity(BIG a)
{
	return a[0]%2;
}

/* return n-th bit of a */
/* SU= 16 */
int BIG_bit(BIG a,int n)
{
	if (a[n/BASEBITS]&((chunk)1<<(n%BASEBITS))) return 1;
	else return 0;
}

/* return NAF value as +/- 1, 3 or 5. x and x3 should be normed.
nbs is number of bits processed, and nzs is number of trailing 0s detected */
/* SU= 32 */
int BIG_nafbits(BIG x,BIG x3,int i,int *nbs,int *nzs)
{
	int j,r,nb;

	nb=BIG_bit(x3,i)-BIG_bit(x,i);
	*nbs=1;
	*nzs=0;
	if (nb==0) return 0;
	if (i==0) return nb;

    if (nb>0) r=1;
    else      r=(-1);

    for (j=i-1;j>0;j--)
    {
        (*nbs)++;
        r*=2;
        nb=BIG_bit(x3,j)-BIG_bit(x,j);
        if (nb>0) r+=1;
        if (nb<0) r-=1;
        if (abs(r)>5) break;
    }

	if (r%2!=0 && j!=0)
    { /* backtrack */
        if (nb>0) r=(r-1)/2;
        if (nb<0) r=(r+1)/2;
        (*nbs)--;
    }

    while (r%2==0)
    { /* remove trailing zeros */
        r/=2;
        (*nzs)++;
        (*nbs)--;
    }
    return r;
}

/* return last n bits of a, where n is small < BASEBITS */
/* SU= 16 */
int BIG_lastbits(BIG a,int n)
{
	int msk=(1<<n)-1;
	BIG_norm(a);
	return ((int)a[0])&msk;
}

/* get 8*MODBYTES size random number */
void BIG_random(BIG m,csprng *rng)
{
	int i,b,j=0,r=0;

	BIG_zero(m);
/* generate random BIG */
	for (i=0;i<8*MODBYTES;i++)
	{
		if (j==0) r=RAND_byte(rng);
		else r>>=1;
		b=r&1;
		BIG_shl(m,1); m[0]+=b;
		j++; j&=7;
	}

#ifdef DEBUG_NORM
	m[NLEN]=0;
#endif
}

/* get random BIG from rng, modulo q. Done one bit at a time, so its portable */

void BIG_randomnum(BIG m,BIG q,csprng *rng)
{
	int i,b,j=0,r=0;
	DBIG d;
	BIG_dzero(d);
/* generate random DBIG */
	for (i=0;i<2*MODBITS;i++)
	{
		if (j==0) r=RAND_byte(rng);
		else r>>=1;
		b=r&1;
		BIG_dshl(d,1); d[0]+=b;
		j++; j&=7;
	}
/* reduce modulo a BIG. Removes bias */
	BIG_dmod(m,d,q);
#ifdef DEBUG_NORM
	m[NLEN]=0;
#endif
}

/* Set r=a*b mod m */
/* SU= 96 */
void BIG_modmul(BIG r,BIG a,BIG b,BIG m)
{
	DBIG d;
	BIG_mod(a,m);
	BIG_mod(b,m);
	BIG_mul(d,a,b);
	BIG_dmod(r,d,m);
}

/* Set a=a*a mod m */
/* SU= 88 */
void BIG_modsqr(BIG r,BIG a,BIG m)
{
	DBIG d;
	BIG_mod(a,m);
	BIG_sqr(d,a);
	BIG_dmod(r,d,m);
}

/* Set r=-a mod m */
/* SU= 16 */
void BIG_modneg(BIG r,BIG a,BIG m)
{
	BIG_mod(a,m);
	BIG_sub(r,m,a);
}

/* Set a=a/b mod m */
/* SU= 136 */
void BIG_moddiv(BIG r,BIG a,BIG b,BIG m)
{
	DBIG d;
	BIG z;
	BIG_mod(a,m);
	BIG_invmodp(z,b,m);
	BIG_mul(d,a,z);
	BIG_dmod(r,d,m);
}

/* Get jacobi Symbol (a/p). Returns 0, 1 or -1 */
/* SU= 216 */
int BIG_jacobi(BIG a,BIG p)
{
	int n8,k,m=0;
	BIG t,x,n,zilch,one;
	BIG_one(one);
	BIG_zero(zilch);
	if (BIG_parity(p)==0 || BIG_comp(a,zilch)==0 || BIG_comp(p,one)<=0) return 0;
	BIG_norm(a);
	BIG_copy(x,a);
	BIG_copy(n,p);
	BIG_mod(x,p);

	while (BIG_comp(n,one)>0)
	{
		if (BIG_comp(x,zilch)==0) return 0;
		n8=BIG_lastbits(n,3);
		k=0;
		while (BIG_parity(x)==0)
		{
			k++;
			BIG_shr(x,1);
		}
		if (k%2==1) m+=(n8*n8-1)/8;
		m+=(n8-1)*(BIG_lastbits(x,2)-1)/4;
		BIG_copy(t,n);

		BIG_mod(t,x);
		BIG_copy(n,x);
		BIG_copy(x,t);
		m%=2;

	}
	if (m==0) return 1;
	else return -1;
}

/* Set r=1/a mod p. Binary method */
/* SU= 240 */
void BIG_invmodp(BIG r,BIG a,BIG p)
{
	BIG u,v,x1,x2,t,one;
	BIG_mod(a,p);
	BIG_copy(u,a);
	BIG_copy(v,p);
	BIG_one(one);
	BIG_copy(x1,one);
	BIG_zero(x2);

	while (BIG_comp(u,one)!=0 && BIG_comp(v,one)!=0)
	{
		while (BIG_parity(u)==0)
		{
			BIG_shr(u,1);
			if (BIG_parity(x1)!=0)
			{
				BIG_add(x1,p,x1);
				BIG_norm(x1);
			}
			BIG_shr(x1,1);
		}
		while (BIG_parity(v)==0)
		{
			BIG_shr(v,1);
			if (BIG_parity(x2)!=0)
			{
				BIG_add(x2,p,x2);
				BIG_norm(x2);
			}
			BIG_shr(x2,1);
		}
		if (BIG_comp(u,v)>=0)
		{
			BIG_sub(u,u,v);
			BIG_norm(u);
			if (BIG_comp(x1,x2)>=0) BIG_sub(x1,x1,x2);
			else
			{
				BIG_sub(t,p,x2);
				BIG_add(x1,x1,t);
			}
			BIG_norm(x1);
		}
		else
		{
			BIG_sub(v,v,u);
			BIG_norm(v);
			if (BIG_comp(x2,x1)>=0) BIG_sub(x2,x2,x1);
			else
			{
				BIG_sub(t,p,x1);
				BIG_add(x2,x2,t);
			}
			BIG_norm(x2);
		}
	}
	if (BIG_comp(u,one)==0)
		BIG_copy(r,x1);
	else
		BIG_copy(r,x2);
}
